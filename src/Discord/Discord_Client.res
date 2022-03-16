type t
type rec client = Client(client)
@module("discord.js") @new external createDiscordClient: 'a => 'b = "Client"
@send external createLogin: ('client, string) => unit = "login"

@send
external on: (
  'client,
  @string
  [
    | #ready(unit => unit)
    | #guildCreate('guild => unit)
    | #message('message => unit)
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
