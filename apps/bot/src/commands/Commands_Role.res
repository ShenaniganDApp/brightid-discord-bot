open Promise
open Discord

// @TODO: Update name of error to reflect Command namespace
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

let execute = interaction => {
  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager
  let commandOptions = interaction->Interaction.getOptions
  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    let isAdmin =
      member->GuildMember.getPermissions->Permissions.has(Permissions.Flags.administrator)

    switch isAdmin {
    | false => {
        interaction
        ->Interaction.editReply(~options={"content": "Only administrators can change the role"}, ())
        ->ignore
        RoleHandlerError("Commands_Role: User does not hav Administrator permissions")->reject
      }
    | true => {
        let role = commandOptions->CommandInteractionOptionResolver.getString("name")

        switch role->Js.Nullable.toOption {
        | None => {
            interaction
            ->Interaction.editReply(
              ~options={
                "content": "Woah! It seems I couldn't find a role to change. This one is on the developer. Go complain!",
              },
              (),
            )
            ->ignore
            RoleHandlerError("Commands_Role: The string input by the user came back null")->reject
          }
        | Some(role) =>
          readGist()->then(guilds => {
            let guildId = guild->Guild.getGuildId
            let guildData = guilds->Js.Dict.get(guildId)
            switch guildData {
            | None =>
              interaction
              ->Interaction.editReply(
                ~options={
                  "content": "I couldn't get the data about this Discord server from BrightID",
                },
                (),
              )
              ->ignore
              reject(
                RoleHandlerError(
                  `Commands_Role: Guild does not exist with the guildID: ${guildId}`,
                ),
              )
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
                  interaction
                  ->Interaction.editReply(
                    ~options={
                      "content": `Succesfully updated \`${previousRole}\` role to \`${role}\``,
                    },
                    (),
                  )
                  ->ignore
                  resolve()
                })
              }
            }
          })
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
  })
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("role")
  ->SlashCommandBuilder.setDescription("Set the name of the BrightID verified role for this server")
  ->SlashCommandBuilder.addStringOption(option => {
    open SlashCommandStringOption
    option->setName("name")->setDescription("Enter the new name of the role")->setRequired(true)
  })
