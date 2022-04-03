open Promise
open Types
open Variants

exception RoleHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
}

@module("../updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"
@module("../updateOrReadGist.js")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

let newRoleRe = %re("/(?<=^\S+)\s/")

let getRolebyRoleName = (guildRoleManager, roleName) => {
  let guildRole = guildRoleManager.cache->Belt.Map.findFirstBy((_, role) => {
    let role = role->wrapRole
    role.name->Discord_Role.validateRoleName === roleName
  })
  switch guildRole {
  | Some((_, guildRole)) => guildRole->wrapRole
  | None => RoleHandlerError("Could not find a role with the name " ++ roleName)->raise
  }
}

let role = (member: guildMember, _: client, message: message) => {
  let guild = member.guild->wrapGuild
  let guildRoleManager = guild.roles->wrapRoleManager
  switch member.t->Discord_Guild.hasPermission("ADMINISTRATOR") {
  | false => {
      message->Discord_Message.reply(Content("Must be an administrator"))->ignore
      reject(RoleHandlerError("Administrator permissions are required"))
    }
  | true => {
      let role = message.content->Discord_Message.validateContent->Js.String2.splitByRe(newRoleRe)
      switch role->Belt.Array.get(1) {
      | None =>
        message->Discord_Message.reply(Content("Please specify a role -> `!role <role>`"))->ignore
        reject(RoleHandlerError("No role specified"))
      | Some(role) =>
        switch role {
        | None => reject(RoleHandlerError("Role is empty"))
        | Some(role) =>
          readGist()->then(guilds => {
            let guildId = guild.id->Discord_Snowflake.validateSnowflake
            let guildData = guilds->Js.Dict.get(guildId)
            switch guildData {
            | None =>
              message
              ->Discord_Message.reply(Content("Failed to retreive role data for guild"))
              ->ignore
              reject(RoleHandlerError("Guild does not exist"))
            | Some(guildData) => {
                let previousRole = guildData.role
                let guildRole = getRolebyRoleName(guildRoleManager, previousRole)
                guildRole
                ->Discord_Role.edit(
                  {name: RoleName(role), color: String("")},
                  Reason("Update BrightId role name"),
                )
                ->then(_ => {
                  guild.id
                  ->Discord_Snowflake.validateSnowflake
                  ->updateGist({
                    "role": role,
                  })
                })
                ->then(_ => {
                  message
                  ->Discord_Message.reply(
                    Content(`Succesfully update verified role to \`${role}\``),
                  )
                  ->ignore
                  resolve(message.t)
                })
              }
            }
          })
        }
      }
    }
  }->catch(e => {
    switch e {
    | RoleHandlerError(msg) => Js.Console.error(msg)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    resolve(message.t)
  })
}
