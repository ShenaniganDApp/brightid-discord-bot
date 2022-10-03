open Promise

exception DiscordRateLimited

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

let sleep = ms => %raw(` new Promise((resolve) => setTimeout(resolve, ms))`)

//fetch all bot and user guilds
let rec fetchBotGuilds = (~after=0, ~allGuilds=[], ()): Promise.t<array<Types.oauthGuild>> => {
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
    switch json->Js.Json.test(Js.Json.Array) {
    | false => {
        let rateLimit = json->Js.Json.decodeObject->Belt.Option.getUnsafe

        let retry_after =
          rateLimit->Js.Dict.get("retry_after")->Belt.Option.flatMap(Js.Json.decodeNumber)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Belt.Float.toInt + 100
        }

        Js.log(
          `Discord Rate Limited: Retrying fetch for guilds after: ${after->Belt.Int.toString} in ${retry_after->Belt.Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchBotGuilds(~after, ~allGuilds, ()))
      }

    | true => {
        let guilds = json->Js.Json.decodeArray->mapGuildOauthRecord->Belt.Option.getUnsafe
        switch guilds->Belt.Array.length <= 1 {
        | true => allGuilds->Belt.Array.concat(guilds)->resolve
        | false => {
            let last = guilds->Js.Array2.length - 1
            let after = guilds[last].id->Belt.Int.fromString->Belt.Option.getUnsafe
            let allGuilds = allGuilds->Belt.Array.concat(guilds)
            fetchBotGuilds(~after, ~allGuilds, ())
          }
        }
      }
    }
  })
  ->catch(e => {
    switch e {
    | DiscordRateLimited => e->raise
    | _ => allGuilds->resolve
    }
  })
}

type guildsCursor = {guilds: array<Types.oauthGuild>, after: option<string>}
//fetch first 1000 guilds
let rec fetchBotGuildsLimit = (~after): Promise.t<guildsCursor> => {
  open Webapi.Fetch

  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())
  switch after {
  | Some(after) =>
    `https://discord.com/api/users/@me/guilds?after=${after}`
    ->Request.makeWithInit(init)
    ->fetchWithRequest
    ->then(res => res->Response.json)
    ->then(json => {
      switch json->Js.Json.test(Js.Json.Array) {
      | false => {
          let rateLimit = json->Js.Json.decodeObject->Belt.Option.getUnsafe

          let retry_after =
            rateLimit->Js.Dict.get("retry_after")->Belt.Option.flatMap(Js.Json.decodeNumber)

          let retry_after = switch retry_after {
          | None => DiscordRateLimited->raise
          | Some(retry_after) => retry_after->Belt.Float.toInt + 100
          }

          Js.log(
            `Discord Rate Limited: Retrying fetch for guilds after: ${after} in ${retry_after->Belt.Int.toString}ms`,
          )
          sleep(retry_after)->then(_ => fetchBotGuildsLimit(~after=Some(after)))
        }

      | true => {
          let guilds = json->Js.Json.decodeArray->mapGuildOauthRecord->Belt.Option.getUnsafe
          let last = guilds->Js.Array2.length - 1
          let after = guilds[last].id->Some
          {guilds, after}->resolve
        }
      }
    })
    ->catch(e => {
      switch e {
      | DiscordRateLimited => e->raise
      | _ => {guilds: [], after: Some(after)}->resolve
      }
    })
  | None => {guilds: [], after}->resolve
  }
}

let rec fetchUserGuilds = (user: RemixAuth.User.t) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bearer ${user->RemixAuth.User.getAccessToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())
  "https://discord.com/api/users/@me/guilds"
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json =>
    switch json->Js.Json.test(Js.Json.Array) {
    | false => {
        let rateLimit = json->Js.Json.decodeObject->Belt.Option.getUnsafe

        let retry_after =
          rateLimit->Js.Dict.get("retry_after")->Belt.Option.flatMap(Js.Json.decodeNumber)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Belt.Float.toInt + 100
        }
        Js.log(
          `Discord Rate Limited: Retrying fetch user guilds in ${retry_after->Belt.Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchUserGuilds(user))
      }

    | true => json->Js.Json.decodeArray->mapGuildOauthRecord->Belt.Option.getUnsafe->resolve
    }
  )
  ->catch(e => {
    switch e {
    | DiscordRateLimited => e->raise
    | _ => []->resolve
    }
  })
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

let rec fetchGuildRoles = (~guildId) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })

  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/guilds/${guildId}/roles`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json =>
    switch json->Js.Json.test(Js.Json.Array) {
    | false => {
        let rateLimit = json->Js.Json.decodeObject->Belt.Option.getUnsafe

        let retry_after =
          rateLimit->Js.Dict.get("retry_after")->Belt.Option.flatMap(Js.Json.decodeNumber)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Belt.Float.toInt + 100
        }
        Js.log(
          `Discord Rate Limited: Retrying fetch guild: ${guildId} roles in ${retry_after->Belt.Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchGuildRoles(~guildId))
      }

    | true => json->Js.Json.decodeArray->mapRoleRecord->Belt.Option.getUnsafe->resolve
    }
  )
  ->catch(e => {
    switch e {
    | DiscordRateLimited => e->raise
    | _ => []->resolve
    }
  })
}

let memberIsAdmin = (~guildRoles: array<Types.role>, ~memberRoles) => {
  let adminPerm = %raw(`0x0000000000000008`)

  let memberRoles = guildRoles->Js.Array2.filter(role => memberRoles->Js.Array2.includes(role.id))
  memberRoles->Js.Array2.some(role => {
    %raw(`(role.permissions & adminPerm)`) === adminPerm
  })
}
