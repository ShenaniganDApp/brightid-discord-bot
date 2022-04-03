open Discord_Snowflake

type clientT
type channelT
type roleT
type guildT
type roleManagerT
type guildMemberRoleManagerT
type guildMemberT
type userT
type messageT

// Client
type client = Client(clientT)

// Channel
type channelName = ChannelName(string)
type channel = {
  t: channelT,
  id: snowflake,
  name: channelName,
}

//Role
type roleName = RoleName(string)
type reason = Reason(string)
// @TODO: Color resolvable is missing most of its fields. String works in this case
type colorResolvable = String(string)
// RGB(int, int, int) | Hex(string)
// @TODO: These types and their values should be optional
type roleData = {name: roleName, color: colorResolvable}

type role = {t: roleT, name: roleName}

//Guild

type guildName = GuildName(string)

type createRoleOptions = {data: roleData, reason: reason}

type guild = {
  t: guildT,
  id: snowflake,
  name: guildName,
  roles: roleManagerT,
}

//RoleManager

type roleManager = {
  t: roleManagerT,
  cache: Belt.Map.t<snowflake, roleT, SnowflakeCompare.identity>,
  guild: guildT,
}

// GuildMemberRoleManager
type guildMemberRoleManager = {t: guildMemberRoleManagerT}

// GuildMember
type guildMember = {t: guildMemberT, id: snowflake, roles: guildMemberRoleManagerT, guild: guildT}

//User
type bot = Bot(bool)
type user = {bot: bot}

// Message

type content = Content(string)
type message = {
  t: messageT,
  id: snowflake,
  content: content,
  author: userT,
  member: guildMemberT,
  channel: channelT,
  guild: guildT,
}
