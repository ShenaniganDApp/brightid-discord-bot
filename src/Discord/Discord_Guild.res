type guildMember
type guildName = GuildName(string)

type guild = {
  id: Discord_Snowflake.snowflake,
  name: guildName,
  roles: Discord_RoleManager.roleManager,
}
@get external getGuildRoleManager: 'a => Discord_RoleManager.roleManager = "roles"
@get external getGuildId: 'a => string = "id"
@get external getGuildName: 'a => string = "name"

let validateGuildName = guildName =>
  switch guildName {
  | GuildName(guildName) => guildName
  }

// let validateGuild = guild =>
//   switch guild {
//   | Guild(guild) => {
//       let id = guild.id->validateSnowflake
//       let name = guild.name->validateGuildName
//       {"id": id, "name": name}
//     }
//   }

let make = guild => {
  let id = getGuildId(guild)
  let name = getGuildName(guild)
  let roles = getGuildRoleManager(guild)
  {id: Snowflake(id), name: GuildName(name), roles: roles}
}
