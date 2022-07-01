let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

let fetchBotGuilds = () => {
  open Webapi.Fetch

  let headers = HeadersInit.make({
    "Authorization": `Bot ${botToken}`,
  })
  let init = RequestInit.make(~method_=Get, ~headers, ())
  "https://discord.com/api/users/@me/guilds"->Request.makeWithInit(init)->fetchWithRequest
}
