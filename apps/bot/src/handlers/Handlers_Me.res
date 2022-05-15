open Discord
open Promise

exception MeHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
}

@module("../updateOrReadGist.js")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

let getRolebyRoleName = (guildRoleManager, roleName) => {
  let guildRole =
    guildRoleManager
    ->RoleManager.getCache
    ->Collection.find(role => role->Role.getName === roleName)
    ->Js.Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => MeHandlerError("Could not find a role with the name " ++ roleName)->raise
  }
}

let getRoleFromGuildData = data => data.role

let getGuildDataFromGist = (guilds, guildId, message) => {
  let guildData = guilds->Js.Dict.get(guildId)
  switch guildData {
  | None =>
    message->Message.reply("Failed to retreive data for this Discord Guild")->ignore
    MeHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let verifyMember = (guildRole, member) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  guildMemberRoleManager
  ->GuildMemberRoleManager.add(guildRole, "Add BrightId Verified role")
  ->ignore
  member->GuildMember.send("You are now verified", ())
}

let noMultipleAccounts = member => {
  member
  ->GuildMember.send(
    "You are currently limited to one Discord account with BrightID. If there has been a mistake, message the BrightID team on Discord https://discord.gg/N4ZbNjP",
    (),
  )
  ->ignore
  MeHandlerError(
    "Verification Info can not be retrieved from more than one Discord account.",
  )->reject
}

let me = (member: GuildMember.t, _: Client.t, message: Message.t) => {
  let guild = member->GuildMember.getGuild
  let guildRoleManager = guild->Guild.getGuildRoleManager

  let guildId = guild->Guild.getGuildId

  readGist()
  ->then(guilds => {
    let guildRole =
      guilds
      ->getGuildDataFromGist(guildId, message)
      ->getRoleFromGuildData
      ->getRolebyRoleName(guildRoleManager, _)
    member
    ->Services_VerificationInfo.getBrightIdVerification
    ->then(verificationInfo => {
      verificationInfo.userAddresses->Belt.Array.length > 1
        ? member->noMultipleAccounts
        : verificationInfo.userVerified
        ? guildRole->verifyMember(member)
        : {
            member->GuildMember.send("You must be verified for this role", ())->ignore
            MeHandlerError("Member is not verified")->reject
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
    message->resolve
  })
}
