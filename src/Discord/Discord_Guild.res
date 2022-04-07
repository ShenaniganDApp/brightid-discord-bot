open Types
type t = guildT

@get external getGuildRoleManager: t => roleManagerT = "roles"
@get external getGuildId: t => string = "id"
@get external getGuildName: t => string = "name"
@get external getMemberCount: t => int = "memberCount"

@send external hasPermission: (guildMemberT, string) => bool = "hasPermission"

let validateGuildName = guildName =>
  switch guildName {
  | GuildName(guildName) => guildName
  }

let validateMemberCount = memberCount =>
  switch memberCount {
  | MemberCount(memberCount) => memberCount
  }
