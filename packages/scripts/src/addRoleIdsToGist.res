open Discord
open Promise

Env.createEnv()

let envConfig = Env.getConfig()

@raises(Env.EnvError)
let envConfig = switch envConfig {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let discordBotToken = envConfig["discordApiToken"]
let githubAccessToken = envConfig["githubAccessToken"]
let id = envConfig["gistId"]

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES"],
  partials: [],
}

let client = Client.createDiscordClient(~options)

type brightIdGuild = {
  "role": string,
  "name": string,
  "inviteLink": option<string>,
  "roleId": string,
}

type brightIdGuilds = Js.Dict.t<brightIdGuild>

let guild = Json.Decode.object(field =>
  {
    "role": field.optional(. "role", Json.Decode.string),
    "name": field.optional(. "name", Json.Decode.string),
    "inviteLink": field.optional(. "inviteLink", Json.Decode.string),
    "roleId": field.optional(. "roleId", Json.Decode.string),
  }
)

let brightIdGuilds = guild->Json.Decode.dict

Client.login(client, discordBotToken)
->then(_ => {
  open Utils

  let config = Gist.makeGistConfig(~token=githubAccessToken, ~id, ~name="guildData.json")

  Gist.ReadGist.content(~config, ~decoder=brightIdGuilds)
  ->then(content => {
    let guildIds = content->Js.Dict.keys
    let guilds = client->Client.getGuildManager->GuildManager.getCache
    let roleIdEntries =
      guildIds
      ->Belt.Array.map(
        guildId => {
          let brightIdGuild = content->Js.Dict.get(guildId)->Belt.Option.getExn

          let guild = guilds->Collection.get(guildId)->Js.Nullable.toOption
          switch guild {
          | None => {
              Js.log(`Guild Does not exist: ${guildId}`)
              None
            }

          | Some(guild) => {
              let guildRoleManager = guild->Guild.getGuildRoleManager
              let roles = guildRoleManager->RoleManager.getCache
              let brightIdRole =
                roles
                ->Collection.find(
                  r => r->Role.getName == brightIdGuild["role"]->Belt.Option.getWithDefault(""),
                )
                ->Js.Nullable.toOption
              switch brightIdRole {
              | None =>
                let roleId = ""
                let inviteLink = switch brightIdGuild["inviteLink"] {
                | None => Some("")
                | Some(inviteLink) => Some(inviteLink)
                }
                let role = brightIdGuild["role"]
                let name = brightIdGuild["name"]
                Some((
                  guildId,
                  {"roleId": Some(roleId), "inviteLink": inviteLink, "role": role, "name": name},
                ))

              | Some(role) => {
                  let roleId = role->Role.getRoleId
                  let inviteLink = switch brightIdGuild["inviteLink"] {
                  | None => Some("")
                  | Some(inviteLink) => Some(inviteLink)
                  }
                  let role = brightIdGuild["role"]
                  let name = brightIdGuild["name"]
                  Some((
                    guildId,
                    {"roleId": Some(roleId), "inviteLink": inviteLink, "role": role, "name": name},
                  ))
                }
              }
            }
          }
        },
      )
      ->Belt.Array.keepMap(
        roleIdEntry =>
          roleIdEntry->Belt.Option.isSome ? Some(roleIdEntry->Belt.Option.getExn) : None,
      )
      ->Belt.List.fromArray

    Gist.UpdateGist.updateAllEntries(~content, ~entries=roleIdEntries, ~config)->then(
      result => {
        switch result {
        | Ok(result) => Js.log(j`$result: Succesfully updated gist with id: ${id}`)->resolve
        | Error(err) => err->Gist.UpdateGist.UpdateGistError->raise
        }
      },
    )
  })
  ->then(_ => {
    client->Client.destroy
    resolve()
  })
  ->catch(e => {
    Js.log2("e: ", e)

    resolve()
  })
})
->ignore
