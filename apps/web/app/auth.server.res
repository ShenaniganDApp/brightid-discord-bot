let clientID = Remix.process["env"]["DISCORD_CLIENT_ID"]
let clientSecret = Remix.process["env"]["DISCORD_CLIENT_SECRET"]
let baseUrl = Remix.process["env"]["BASE_URL"]

let cookieOptions = Remix.CreateCookieOptions.make(
  ~sameSite=#lax,
  ~path="/",
  ~httpOnly=true,
  ~secrets=["s3cr3t"],
  ~secure=Remix.process["env"]["NODE_ENV"] === "production",
  (),
)

let cookie = Remix.createCookieWithOptions("__session", cookieOptions)

let sessionStorage =
  cookie
  ->Remix.CreateCookieSessionStorageOptions.make(~cookie=_)
  ->Remix.createCookieSessionStorageWithOptions(~options=_)

let auth = sessionStorage->RemixAuth.Authenticator.make

let discordStrategy = RemixAuth.DiscordStrategy.CreateDiscordStategyOptions.make(
  ~clientID,
  ~clientSecret,
  ~callbackURL=baseUrl ++ "/auth/discord/callback",
  ~scope=["identify", "guilds", "guilds.join"],
  (),
)->RemixAuth.DiscordStrategy.make(({accessToken, extraParams, profile}) => {
  Js.log2("extraParams: ", extraParams)
  {"accessToken": accessToken, "profile": profile}->Promise.resolve
})

auth->RemixAuth.Authenticator.use(discordStrategy)
