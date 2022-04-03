type t = Types.guildT

@get external getGuildRoleManager: t => Types.roleManagerT = "roles"
@get external getGuildId: t => string = "id"
@get external getGuildName: t => string = "name"

@send external hasPermission: (Types.guildMemberT, string) => bool = "hasPermission"

let validateGuildName = guildName =>
  switch guildName {
  | Types.GuildName(guildName) => guildName
  }

// let validateGuild = guild =>
//   switch guild {
//   | Guild(guild) => {
//       let id = guild.id->validateSnowflake
//       let name = guild.name->validateGuildName
//       {"id": id, "name": name}
//     }
//   }
