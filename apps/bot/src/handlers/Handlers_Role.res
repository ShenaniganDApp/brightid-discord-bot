open Promise
open Discord

exception RoleHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
}

@module("../updateOrReadGist.mjs")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"
@module("../updateOrReadGist.mjs")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

let newRoleRe = %re("/(?<=^\S+)\s/")

let getRolebyRoleName = (guildRoleManager, roleName) => {
  let guildRole =
    guildRoleManager
    ->RoleManager.getCache
    ->Collection.find(role => role->Role.getName === roleName)
    ->Js.Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => RoleHandlerError("Could not find a role with the name " ++ roleName)->raise
  }
}

let role = (member: GuildMember.t, _: Client.t, message: Message.t) => {
  let guild = member->GuildMember.getGuild
  let guildRoleManager = guild->Guild.getGuildRoleManager
  switch member->Guild.hasPermission("ADMINISTRATOR") {
  | false => {
      message->Message.reply("Must be an administrator")->ignore
      RoleHandlerError("Administrator permissions are required")->reject
    }
  | true => {
      let role = message->Message.getMessageContent->Js.String2.splitByRe(newRoleRe)
      switch role->Belt.Array.get(1) {
      | None =>
        message->Message.reply("Please specify a role -> `!role <role>`")->ignore
        RoleHandlerError("No role specified")->reject
      | Some(role) =>
        switch role {
        | None => RoleHandlerError("Role is empty")->reject
        | Some(role) =>
          readGist()->then(guilds => {
            let guildId = guild->Guild.getGuildId
            let guildData = guilds->Js.Dict.get(guildId)
            switch guildData {
            | None =>
              message->Message.reply("Failed to retreive role data for guild")->ignore
              reject(RoleHandlerError("Guild does not exist"))
            | Some(guildData) => {
                let previousRole = guildData.role
                let guildRole = getRolebyRoleName(guildRoleManager, previousRole)
                guildRole
                ->Role.edit(~data={"name": role}, ~reason="Update BrightId role name")
                ->then(_ => {
                  guildId->updateGist({
                    "role": role,
                  })
                })
                ->then(_ => {
                  message->Message.reply(`Succesfully update verified role to \`${role}\``)->ignore
                  message->resolve
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
    message->resolve
  })
}
