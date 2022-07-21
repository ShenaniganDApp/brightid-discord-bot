open Discord
open Promise

module NodeFetchPolyfill = {
  type t
  @module("node-fetch") external fetch: t = "default"
  @val external globalThis: 'a = "globalThis"
  globalThis["fetch"] = fetch
}

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

Env.createEnv()

let envConfig = Env.getConfig()

let envConfig = switch envConfig {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let githubAccessToken = envConfig["githubAccessToken"]
let gistId = envConfig["gistId"]

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES"],
}

let client = Client.createDiscordClient(~options)

module ReadGist = {
  type t = {name: string, role: string, inviteLink: option<string>}

  @val @scope("globalThis")
  external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

  let make = () => {
    let params = {
      "Authorization": `Bearer ${githubAccessToken}`,
    }

    `https://api.github.com/gists/${gistId}`
    ->fetch(params)
    ->then(res => res->Response.json)
    ->then(data => {
      let files =
        data->Js.Json.decodeObject->Belt.Option.getExn->Js.Dict.get("files")->Belt.Option.getExn

      let guildData =
        files
        ->Js.Json.decodeObject
        ->Belt.Option.getExn
        ->Js.Dict.get("guildData.json")
        ->Belt.Option.getExn

      let content =
        guildData
        ->Js.Json.decodeObject
        ->Belt.Option.getExn
        ->Js.Dict.get("content")
        ->Belt.Option.getExn
        ->Js.Json.decodeString
        ->Belt.Option.getExn
        ->Js.Json.parseExn
        ->Js.Json.decodeObject
        ->Belt.Option.getExn

      content->resolve
    })
  }
}

type brightIdGuild = {"name": string, "role": string, "inviteLink": Js.Nullable.t<string>}

type brightIdGuildWithRoleId = {...brightIdGuild, "roleId": string}

client
->Client.login(envConfig["discordApiToken"])
->then(_ => {
  let guildManager = client->Client.getGuildManager
  ReadGist.make()
  ->then(guildData => {
    let guildIds = guildData->Js.Dict.keys

    Js.log2("guildIds: ", guildIds)

    let roles = guildIds->Belt.Array.map(
      guildId => {
        let roleName =
          guildData
          ->Js.Dict.get(guildId)
          ->Belt.Option.getExn
          ->Js.Json.decodeObject
          ->Belt.Option.getExn
          ->Js.Dict.get("role")
          ->Belt.Option.getExn
          ->Js.Json.decodeString
          ->Belt.Option.getExn

        let guilds = guildManager->GuildManager.getCache
        let guild = guilds->Collection.get(guildId)->Js.Nullable.toOption->Belt.Option.getExn
        let guildRoleManager = guild->Guild.getGuildRoleManager
        let roles = guildRoleManager->RoleManager.getCache
        roles
        ->Collection.find(r => r->Role.getName == roleName)
        ->Js.Nullable.toOption
        ->Belt.Option.getExn
      },
    )

    let newGist = Js.Dict.empty()
    roles->Belt.Array.forEach(
      role => {
        let roleGuildId = role->Role.getGuild->Guild.getGuildId
        let brightIdGuild =
          guildData
          ->Js.Dict.get(roleGuildId)
          ->Belt.Option.getExn
          ->Js.Json.decodeObject
          ->Belt.Option.getExn
        let brightIdGuildWithRoleId = (
          {
            "name": brightIdGuild
            ->Js.Dict.get("name")
            ->Belt.Option.flatMap(Js.Json.decodeString)
            ->Belt.Option.getExn,
            "role": brightIdGuild
            ->Js.Dict.get("role")
            ->Belt.Option.flatMap(Js.Json.decodeString)
            ->Belt.Option.getExn,
            "roleId": role->Role.getRoleId,
            "inviteLink": brightIdGuild
            ->Js.Dict.get("inviteLink")
            ->Belt.Option.flatMap(Js.Json.decodeString)
            ->Js.Nullable.fromOption,
          }: brightIdGuildWithRoleId
        )

        newGist->Js.Dict.set(roleGuildId, brightIdGuildWithRoleId)
      },
    )

    resolve()
  })
  ->catch(e => {
    Js.log(e)
    resolve()
  })
})
->ignore
