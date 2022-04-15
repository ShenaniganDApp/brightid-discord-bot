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
    | #guildMemberAdd(Discord_GuildMember.t => unit)
  ],
) => unit = "on"
