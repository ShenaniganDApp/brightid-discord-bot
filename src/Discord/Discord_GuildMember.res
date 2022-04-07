open Types
type t = guildMemberT

@get external getGuildMemberId: t => string = "id"
@get external getGuildMemberRoleManager: t => guildMemberRoleManagerT = "roles"
@get external getGuild: t => guildT = "guild"
@send external hasPermission: (t, string) => bool = "hasPermission"

// @TODO:options is optional
@send
external _send: (t, 'content, 'options) => Js.Promise.t<messageT> = "send"

let send = (guildMember: guildMember, content, options) => {
  _send(guildMember.t, content, options)
}
