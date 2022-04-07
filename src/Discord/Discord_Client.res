open Types
type t = clientT
@module("discord.js") @new external createDiscordClient: 'a => t = "Client"
@send external createLogin: (t, string) => unit = "login"
@get external getGuildManager: t => guildManagerT = "guilds"
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

let login = (client, token) => {
  switch token {
  | Env.DiscordToken(token) => createLogin(client, token)
  }
}
