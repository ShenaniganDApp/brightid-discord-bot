open Types
open Variants
open Promise

exception MeHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
}

@module("../updateOrReadGist.js")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

let getRolebyRoleName = (roleName, guildRoleManager) => {
  let guildRole = guildRoleManager.cache->Belt.Map.findFirstBy((_, role) => {
    let role = role->wrapRole
    role.name->Discord_Role.validateRoleName === roleName
  })
  switch guildRole {
  | Some((_, guildRole)) => guildRole->wrapRole
  | None => MeHandlerError("Could not find a role with the name " ++ roleName)->raise
  }
}

let getRoleFromGuildData = data => data.role

let getGuildDataFromGist = (guilds, guildId, message) => {
  let guildData = guilds->Js.Dict.get(guildId)
  switch guildData {
  | None =>
    message
    ->Discord_Message.reply(Content("Failed to retreive data for this Discord Guild"))
    ->ignore
    MeHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let verifyMember = (guildRole, member) => {
  open Discord_GuildMemberRoleManager
  let guildMemberRoleManager = member.roles->wrapGuildMemberRoleManager
  guildMemberRoleManager->add(guildRole, Reason("Add BrightId Verified role"))->ignore
  member->Discord_GuildMember.send("You are now verified", ())
}

let noMultipleAccounts = member => {
  member
  ->Discord_GuildMember.send(
    "You are currently limited to one Discord account with BrightID. If there has been a mistake, message the BrightID team on Discord https://discord.gg/N4ZbNjP",
    (),
  )
  ->ignore
  MeHandlerError(
    "Verification Info can not be retrieved from more than one Discord account.",
  )->reject
}

let me = (member: guildMember, _: client, message: message) => {
  let guild = member.guild->wrapGuild
  let guildRoleManager = guild.roles->wrapRoleManager

  let guildId = guild.id->Discord_Snowflake.validateSnowflake

  readGist()
  ->then(guilds => {
    let guildRole =
      getGuildDataFromGist(guilds, guildId, message)
      ->getRoleFromGuildData
      ->getRolebyRoleName(guildRoleManager)
    member
    ->Services_VerificationInfo.getBrightIdVerification
    ->then(verificationInfo => {
      switch verificationInfo.userAddresses->Belt.Array.length > 1 {
      | true => member->noMultipleAccounts
      | false =>
        switch verificationInfo.userVerified {
        | true => guildRole->verifyMember(member)
        | false =>
          member->Discord_GuildMember.send("You must be verified for this role", ())->ignore
          MeHandlerError("Member is not verified")->reject
        }
      }
    })
  })
  ->catch(e => {
    switch e {
    | MeHandlerError(msg) => Js.Console.error(msg)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    message.t->resolve
  })
}
