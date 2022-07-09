let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

let fetchBotGuilds: (
  ~after: int=?,
  ~allGuilds: array<Types.guild>=?,
  ~retry: int=?,
  unit,
) => Js.Promise.t<array<Types.guild>> = %raw(`require( "~/bot.server").fetchBotGuilds`)

let fetchUserGuilds: RemixAuth.User.t => Promise.t<
  Js.Array2.t<Types.guild>,
> = %raw(`require( "~/bot.server").fetchUserGuilds`)

type loaderData = {user: option<RemixAuth.User.t>, guilds: option<array<Types.guild>>}

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Promise

  authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {user: None, guilds: None}->resolve
    | Some(user) =>
      user
      ->fetchUserGuilds
      ->then(userGuilds => {
        fetchBotGuilds()->then(botGuilds => {
          let guilds =
            userGuilds->Js.Array2.filter(userGuild =>
              botGuilds->Js.Array2.findIndex(botGuild => botGuild.id === userGuild.id) !== -1
            )
          {user: Some(user), guilds: Some(guilds)}->resolve
        })
      })
    }
  })
}
