type t
type client = Client(t)
@module("discord.js") @new external createDiscordClient: 'a => t = "Client"
@send external createLogin: (t, string) => unit = "login"

@send
external on: (
  t,
  @string
  [
    | #ready(unit => unit)
    | #guildCreate('guild => unit)
    | #message(Discord_Message.t => unit)
  ],
) => unit = "on"

let make = () => {
  let client = createDiscordClient()
  Client(client)
}

let validateClient = client => {
  switch client {
  | Client(client) => client
  }
}

let login = (client, token) => {
  switch client {
  | Client(client) =>
    switch token {
    | Env.DiscordToken(token) => createLogin(client, token)
    }
  }
}
