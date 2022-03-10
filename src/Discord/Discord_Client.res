//Client
@module("discord.js") @new external createDiscordClient: 'a => 'b = "Client"
type rec client = Client(client)
@send external on: ('a, 'b, 'c => unit) => unit = "on"
@send external login: ('a, string) => unit = "login"

let make = () => {
  let client = createDiscordClient()
  Client(client)
}

let onEvent = (client, event) => {
  switch client {
  | Client(client) =>
    switch event {
    | Ready(callback) => client->on("ready", callback)
    | GuildCreate(callback) => client->on("guildCreate", callback)
    }
  }
}

let loginClient = (client, token) => {
  switch client {
  | Client(client) =>
    switch token {
    | Env.DiscordToken(token) => login(client, token)
    }
  }
}
