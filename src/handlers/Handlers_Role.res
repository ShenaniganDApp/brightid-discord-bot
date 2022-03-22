open Promise

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

let role = (
  member: Discord_Guild.guildMember,
  _: Discord_Client.client,
  message: Discord_Message.message,
) => {
  switch member->Discord_Guild.hasPermission("ADMINISTRATOR") {
  | false => {
      message->Discord_Message.reply(Discord_Message.Content("Must be an administrator"))->ignore
      reject(RoleHandlerError("Administrator permissions are required"))
    }
  | true => {
      let role = message.content->Discord_Message.validateContent->Js.String2.splitByRe(newRoleRe)
      switch role->Belt.Array.get(1) {
      | None =>
        message
        ->Discord_Message.reply(Discord_Message.Content("Please specify a role -> `!role <role>`"))
        ->ignore
        reject(RoleHandlerError("No role specified"))
      | Some(role) =>
        switch role {
        | None => reject(RoleHandlerError("Role is empty"))
        | Some(role) =>
          readGist()->then(guilds => {
            let guildId = message.guild.id->Discord_Snowflake.validateSnowflake
            let guildData = guilds->Js.Dict.get(guildId)
            switch guildData {
            | None =>
              message
              ->Discord_Message.reply(
                Discord_Message.Content("Failed to retreive role data for guild"),
              )
              ->ignore
              reject(RoleHandlerError("Guild does not exist"))
            | Some(guildData) => {
                let previousRole = guildData.role
                let guildRole =
                  message.guild.roles.cache->Belt.Map.findFirstBy((_, role) =>
                    role.name->Discord_Role.validateRoleName === previousRole
                  )
                switch guildRole {
                | None =>
                  message
                  ->Discord_Message.reply(
                    Discord_Message.Content(`No role found with name: ${previousRole}`),
                  )
                  ->ignore
                  reject(RoleHandlerError(`No role found with name: ${previousRole}`))
                | Some(_, guildRole) =>
                  guildRole
                  ->Discord_Role.edit(
                    {name: RoleName(role), color: String("")},
                    Reason("Update BrightId role name"),
                  )
                  ->then(_ => {
                    message.guild.id
                    ->Discord_Snowflake.validateSnowflake
                    ->updateGist({
                      "role": role,
                    })
                  })
                  ->then(_ => {
                    message
                    ->Discord_Message.reply(Content(`Succesfully update verified role to ${role}`))
                    ->ignore
                    resolve()
                  })
                }
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
    resolve()
  })
}