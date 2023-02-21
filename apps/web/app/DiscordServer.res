open Promise

exception DiscordRateLimited

let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

// let options: Client.clientOptions = {
//   intents: ["GUILDS"],
// }

// let client = Client.createDiscordClient(~options)

let mapGuildOauthRecord = decodedGuilds => {
  decodedGuilds->Option.map(guilds =>
    guilds->Array.map(guild => {
      let guild = guild->JSON.Decode.object->Option.getUnsafe

      (
        {
          id: guild->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          name: guild->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          icon: guild->Dict.get("icon")->Option.flatMap(JSON.Decode.string),
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
          id: guild->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          name: guild->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          icon: guild->Dict.get("icon")->Option.flatMap(JSON.Decode.string),
          roles: guild->Dict.get("roles")->Option.flatMap(JSON.Decode.array)->Option.getExn,
          owner_id: guild->Dict.get("owner_id")->Option.flatMap(JSON.Decode.string)->Option.getExn,
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
          ->Dict.get("roles")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.map(roles => roles->Array.map(role => role->JSON.Decode.string->Option.getExn))
          ->Option.getExn,
        }: Types.guildMember
      ),
    )
  }
}

let mapRoleRecord = decodedRoles => {
  decodedRoles->Option.map(roles =>
    roles->Array.map(role => {
      let role = role->JSON.Decode.object->Option.getUnsafe

      (
        {
          id: role->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          name: role->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getExn,
          permissions: role
          ->Dict.get("permissions")
          ->Option.flatMap(JSON.Decode.float)
          ->Option.getExn,
        }: Types.role
      )
    })
  )
}

let sleep = _ms => %raw(` new Promise((resolve) => setTimeout(resolve, _ms))`)

//fetch all bot and user guilds
let rec fetchBotGuilds = (~after=0, ~allGuilds=[], ()): promise<array<Types.oauthGuild>> => {
  open Webapi.Fetch

  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/users/@me/guilds?after=${after->Int.toString}`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => {
    switch json->JSON.Decode.array {
    | None => {
        let rateLimit = json->JSON.Decode.object->Option.getUnsafe

        let retry_after = rateLimit->Dict.get("retry_after")->Option.flatMap(JSON.Decode.float)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Float.toInt + 100
        }

        Console.log(
          `Discord Rate Limited: Retrying fetch for guilds after: ${after->Int.toString} in ${retry_after->Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchBotGuilds(~after, ~allGuilds, ()))
      }

    | Some(_) => {
        let guilds = json->JSON.Decode.array->mapGuildOauthRecord->Option.getUnsafe
        switch guilds->Array.length <= 1 {
        | true => allGuilds->Array.concat(guilds)->resolve
        | false => {
            let last = guilds->Array.length - 1
            let after =
              guilds[last]
              ->Option.map(guild => guild.id->Int.fromString->Option.getUnsafe)
              ->Option.getUnsafe
            let allGuilds = allGuilds->Array.concat(guilds)
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
let rec fetchBotGuildsLimit = (~after): promise<guildsCursor> => {
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
      switch json->JSON.Decode.array {
      | None => {
          let rateLimit = json->JSON.Decode.object->Option.getUnsafe

          let retry_after = rateLimit->Dict.get("retry_after")->Option.flatMap(JSON.Decode.float)

          let retry_after = switch retry_after {
          | None => DiscordRateLimited->raise
          | Some(retry_after) => retry_after->Float.toInt + 100
          }

          Console.log(
            `Discord Rate Limited: Retrying fetch for guilds after: ${after} in ${retry_after->Int.toString}ms`,
          )
          sleep(retry_after)->then(_ => fetchBotGuildsLimit(~after=Some(after)))
        }

      | Some(_) => {
          let guilds = json->JSON.Decode.array->mapGuildOauthRecord->Option.getUnsafe
          let last = guilds->Array.length - 1
          let after = guilds[last]->Option.map(guild => guild.id)
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
    switch json->JSON.Decode.array {
    | None => {
        let rateLimit = json->JSON.Decode.object->Option.getUnsafe

        let retry_after = rateLimit->Dict.get("retry_after")->Option.flatMap(JSON.Decode.float)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Float.toInt + 100
        }
        Console.log(
          `Discord Rate Limited: Retrying fetch user guilds in ${retry_after->Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchUserGuilds(user))
      }

    | Some(_) => json->JSON.Decode.array->mapGuildOauthRecord->Option.getUnsafe->resolve
    }
  )
  ->catch(e => {
    switch e {
    | DiscordRateLimited => e->raise
    | _ => []->resolve
    }
  })
}

let fetchDiscordGuildFromId = (~guildId) => {
  open Webapi.Fetch
  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())

  `https://discord.com/api/guilds/${guildId}`
  ->Request.makeWithInit(init)
  ->fetchWithRequest
  ->then(res => res->Response.json)
  ->then(json => json->JSON.Decode.object->mapGuildRecord->Nullable.fromOption->resolve)
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
    json->JSON.Decode.object->mapGuildMemberRecord->Nullable.fromOption->resolve
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
    switch json->JSON.Decode.array {
    | None => {
        let rateLimit = json->JSON.Decode.object->Option.getUnsafe

        let retry_after = rateLimit->Dict.get("retry_after")->Option.flatMap(JSON.Decode.float)

        let retry_after = switch retry_after {
        | None => DiscordRateLimited->raise
        | Some(retry_after) => retry_after->Float.toInt + 100
        }
        Console.log(
          `Discord Rate Limited: Retrying fetch guild: ${guildId} roles in ${retry_after->Int.toString}ms`,
        )
        sleep(retry_after)->then(_ => fetchGuildRoles(~guildId))
      }

    | Some(_) => json->JSON.Decode.array->mapRoleRecord->Option.getUnsafe->resolve
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

  let memberRoles = guildRoles->Array.filter(role => memberRoles->Array.includes(role.id))
  memberRoles->Array.some(role => {
    %raw(`(role.permissions & adminPerm)`) === adminPerm
  })
}
