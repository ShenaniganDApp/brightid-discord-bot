let clientID = Remix.process["env"]["DISCORD_CLIENT_ID"]
let clientSecret = Remix.process["env"]["DISCORD_CLIENT_SECRET"]
let baseUrl = Remix.process["env"]["BASE_URL"]
let uuidNamespace = Remix.process["env"]["UUID_NAMESPACE"]

let cookieOptions = Remix.CreateCookieOptions.make(
  ~sameSite=#lax,
  ~path="/",
  ~httpOnly=true,
  ~secrets=[uuidNamespace],
  ~secure=Remix.process["env"]["NODE_ENV"] === "production",
  (),
)

let cookie = Remix.createCookieWithOptions("__session", cookieOptions)

let sessionStorage =
  cookie
  ->Remix.CreateCookieSessionStorageOptions.make(~cookie=_)
  ->Remix.createCookieSessionStorageWithOptions(~options=_)

let authenticator = sessionStorage->RemixAuth.Authenticator.make

let discordStrategy = RemixAuth.DiscordStrategy.CreateDiscordStategyOptions.make(
  ~clientID,
  ~clientSecret,
  ~callbackURL=baseUrl ++ "/auth/discord/callback",
  ~scope=["identify", "guilds", "guilds.join"],
  (),
)->RemixAuth.DiscordStrategy.make(({accessToken, profile}) => {
  {"accessToken": accessToken, "profile": profile}->Promise.resolve
})

authenticator->RemixAuth.Authenticator.use(discordStrategy)
