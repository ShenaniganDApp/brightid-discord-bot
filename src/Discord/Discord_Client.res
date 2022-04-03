type t = Types.clientT
@module("discord.js") @new external createDiscordClient: 'a => t = "Client"
@send external createLogin: (t, string) => unit = "login"

@send
external on: (
  t,
  @string
  [
    | #ready(unit => unit)
    | #guildCreate(Discord_Guild.t => unit)
    | #message(Discord_Message.t => unit)
  ],
) => unit = "on"

let make = () => {
  let client = createDiscordClient()
  Types.Client(client)
}

let validateClient = client => {
  switch client {
  | Types.Client(client) => client
  }
}

let login = (client, token) => {
  switch client {
  | Types.Client(client) =>
    switch token {
    | Env.DiscordToken(token) => createLogin(client, token)
    }
  }
}
