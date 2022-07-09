open Promise
let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

// let options: Client.clientOptions = {
//   intents: ["GUILDS"],
// }

// let client = Client.createDiscordClient(~options)

let mapGuildOauthRecord = decodedGuilds => {
  decodedGuilds->Belt.Option.map(guilds =>
    guilds->Js.Array2.map(guild => {
      let guild = guild->Js.Json.decodeObject->Belt.Option.getUnsafe

      (
        {
          id: guild
          ->Js.Dict.get("id")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          name: guild
          ->Js.Dict.get("name")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          icon: guild->Js.Dict.get("icon")->Belt.Option.flatMap(Js.Json.decodeString),
        }: Types.oauthGuild
      )
    })
  )
}
let mapGuildRecord = decodedGuild => {
  switch decodedGuild {
  | None => None
  | Some(guild) =>
    Some(
      (
        {
          id: guild
          ->Js.Dict.get("id")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          name: guild
          ->Js.Dict.get("name")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          icon: guild->Js.Dict.get("icon")->Belt.Option.flatMap(Js.Json.decodeString),
          roles: guild
          ->Js.Dict.get("roles")
          ->Belt.Option.flatMap(Js.Json.decodeArray)
          ->Belt.Option.getExn,
          owner_id: guild
          ->Js.Dict.get("owner_id")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
        }: Types.guild
      ),
    )
  }
}
let mapGuildMemberRecord = decodedGuildMember => {
  switch decodedGuildMember {
  | None => None
  | Some(guildMember) =>
    Some(
      (
        {
          roles: guildMember
          ->Js.Dict.get("roles")
          ->Belt.Option.flatMap(Js.Json.decodeArray)
          ->Belt.Option.map(roles =>
            roles->Js.Array2.map(role => role->Js.Json.decodeString->Belt.Option.getExn)
          )
          ->Belt.Option.getExn,
        }: Types.guildMember
      ),
    )
  }
}

let mapRoleRecord = decodedRoles => {
  decodedRoles->Belt.Option.map(roles =>
    roles->Js.Array2.map(role => {
      let role = role->Js.Json.decodeObject->Belt.Option.getUnsafe

      (
        {
          id: role
          ->Js.Dict.get("id")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          name: role
          ->Js.Dict.get("name")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          permissions: role
          ->Js.Dict.get("permissions")
          ->Belt.Option.flatMap(Js.Json.decodeNumber)
          ->Belt.Option.getExn,
        }: Types.role
      )
    })
  )
}

let rec fetchBotGuilds = (~after=0, ~allGuilds=[], ~retry=5, ()) => {
  open Webapi.Fetch

  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/users/@me/guilds?after=${after->Belt.Int.toString}`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => {
    let guilds = json->Js.Json.decodeArray->mapGuildOauthRecord
    switch guilds {
    | None =>
      switch retry {
      | 0 => allGuilds->resolve
      | _ => {
          Js.log(`Retrying to fetch guilds after id ${after->Belt.Int.toString}`)
          fetchBotGuilds(~after, ~allGuilds, ~retry=retry - 1, ())
        }
      }
    | Some(guilds) => {
        let last = guilds->Js.Array2.length - 1
        let after = guilds[last].id->Belt.Int.fromString->Belt.Option.getUnsafe
        fetchBotGuilds(~after, ~allGuilds=allGuilds->Belt.Array.concat(guilds), ())
      }
    }
  })
}

let fetchUserGuilds = (user: RemixAuth.User.t) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bearer ${user->RemixAuth.User.getAccessToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())
  "https://discord.com/api/users/@me/guilds"
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => json->Js.Json.decodeArray->mapGuildOauthRecord->Belt.Option.getUnsafe->resolve)
}

let fetchGuildFromId = (~guildId) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/guilds/${guildId}`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => json->Js.Json.decodeObject->mapGuildRecord->Js.Nullable.fromOption->resolve)
}

let fetchGuildMemberFromId = (~guildId, ~userId) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/guilds/${guildId}/members/${userId}`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => {
    json->Js.Json.decodeObject->mapGuildMemberRecord->Js.Nullable.fromOption->resolve
  })
}

let fetchGuildRoles = (~guildId) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/guilds/${guildId}/roles`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => json->Js.Json.decodeArray->mapRoleRecord->Belt.Option.getUnsafe->resolve)
}

let memberIsAdmin = (~guildRoles: array<Types.role>, ~memberRoles) => {
  let adminPerm = %raw(`0x0000000000000008`)

  let memberRoles = guildRoles->Js.Array2.filter(role => memberRoles->Js.Array2.includes(role.id))
  memberRoles->Js.Array2.some(role => {
    %raw(`(role.permissions & adminPerm)`) === adminPerm
  })
}
