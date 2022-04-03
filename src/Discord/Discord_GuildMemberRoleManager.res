type t = Types.guildMemberRoleManagerT
@send
external _add: (t, Types.roleT, string) => Js.Promise.t<t> = "add"

let add = (guildMemberRoleManager: Types.guildMemberRoleManager, role: Types.role, reason) => {
  _add(guildMemberRoleManager.t, role.t, reason->Discord_Role.validateReason)
}
