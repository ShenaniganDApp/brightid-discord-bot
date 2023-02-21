type loaderData = {
  user: Nullable.t<RemixAuth.User.t>,
  userGuilds: array<Types.oauthGuild>,
  botGuilds: array<Types.oauthGuild>,
  after: option<string>,
  rateLimited: bool,
}

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Promise
  open Webapi

  let after =
    request->Fetch.Request.url->Url.make->Url.searchParams->Url.URLSearchParams.get("after")

  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Nullable.toOption {
    | None =>
      {
        user: Nullable.null,
        userGuilds: [],
        botGuilds: [],
        after: None,
        rateLimited: false,
      }->resolve
    | Some(existingUser) =>
      existingUser
      ->DiscordServer.fetchUserGuilds
      ->then(userGuilds => {
        DiscordServer.fetchBotGuildsLimit(~after)->then(
          ({guilds: botGuilds, after}) => {
            {user, userGuilds, botGuilds, after, rateLimited: false}->resolve
          },
        )
      })
    }
  })
  ->catch(error => {
    switch error {
    | DiscordServer.DiscordRateLimited =>
      {
        user: Nullable.null,
        userGuilds: [],
        botGuilds: [],
        after: None,
        rateLimited: true,
      }->resolve
    | _ =>
      {
        user: Nullable.null,
        userGuilds: [],
        botGuilds: [],
        after: None,
        rateLimited: false,
      }->resolve
    }
  })
}
