open Discord_Snowflake

type clientT
type channelT
type roleT
type guildT
type guildManagerT
type roleManagerT
type guildMemberRoleManagerT
type guildMemberT
type userT
type messageT
type reactionT
type reactionCollectorT
type reactionManagerT
type emojiT

// Client
type client = {guilds: guildManagerT}

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
type memberCount = MemberCount(int)

type createRoleOptions = {data: roleData, reason: reason}

type guild = {
  t: guildT,
  id: snowflake,
  name: guildName,
  memberCount: memberCount,
  roles: roleManagerT,
}

type guildManager = {
  t: guildManagerT,
  cache: Belt.Map.t<snowflake, guildT, SnowflakeCompare.identity>,
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
type user = {id: snowflake, bot: bot}

// Message

type content = Content(string)
type replyOptions = Content(string) | MessagePayload | MessageOptions
type message = {
  t: messageT,
  id: snowflake,
  content: content,
  author: userT,
  member: guildMemberT,
  channel: channelT,
  guild: guildT,
}

//Reaction
type reaction = {
  t: reactionT,
  message: messageT,
  emoji: emojiT,
}

//Emoji
type emojiName = EmojiName(string)
type emoji = {t: emojiT, name: emojiName}
