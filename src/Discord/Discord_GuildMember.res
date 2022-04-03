open Types
type t = guildMemberT

@get external getGuildMemberId: t => string = "id"
@get external getGuildMemberRoleManager: t => guildMemberRoleManagerT = "roles"
@get external getGuild: t => guildT = "guild"

// @TODO:options is optional
@send
external _send: (t, 'content, 'options) => Js.Promise.t<messageT> = "send"

let send = (guildMember: guildMember, content, options) => {
  _send(guildMember.t, content, options)
}
