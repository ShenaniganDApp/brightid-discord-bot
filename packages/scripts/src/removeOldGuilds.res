open Promise
open Utils
open Shared
open Discord

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
let config = Gist.makeGistConfig(~token=githubAccessToken, ~id, ~name="guildData.json")

// type brightIdGuild = {
//   "role": string,
//   "name": string,
//   "inviteLink": option<string>,
//   "roleId": string,
// }

// type brightIdGuilds = Js.Dict.t<brightIdGuild>

// let guild = Json.Decode.object(field =>
//   {
//     "role": field.optional(. "role", Json.Decode.string),
//     "name": field.optional(. "name", Json.Decode.string),
//     "inviteLink": field.optional(. "inviteLink", Json.Decode.string),
//     "roleId": field.optional(. "roleId", Json.Decode.string),
//   }
// )

// let brightIdGuilds = guild->Json.Decode.dict

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES"],
}

let client = Client.createDiscordClient(~options)

Client.login(client, discordBotToken)
->then(_ => {
  Js.log("Client Started\n")
  Gist.ReadGist.content(~config, ~decoder=Decode.Gist.brightIdGuilds)->then(content => {
    let gistGuilds = content->Js.Dict.keys
    let botGuilds = client->Client.getGuildManager->GuildManager.getCache
    let keys =
      gistGuilds
      ->Belt.Array.keep(gistGuild => !Collection.has(botGuilds, gistGuild))
      ->Belt.Set.String.fromArray
    Gist.UpdateGist.removeManyEntries(~content, ~config, ~keys)
    ->then(
      _ => {
        Js.log(
          j`Removed ${keys->Belt.Set.String.size->Belt.Int.toString} guilds
             from gist`,
        )->resolve
      },
    )
    ->then(
      _ => {
        client->Client.destroy
        Js.log("Finished ✅")
        resolve()
      },
    )
  })
})
->catch(e => {
  Js.log(e)
  resolve()
})
->ignore
