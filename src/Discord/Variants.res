open Discord_Snowflake
open Types

let wrapClient = (client): client => {
  open Discord_Client
  let guilds = client->getGuildManager
  {guilds: guilds}
}

let wrapGuild = (guild): guild => {
  open Discord_Guild
  let id = guild->getGuildId->Discord_Snowflake.Snowflake
  let name = guild->getGuildName->GuildName
  let roles = guild->getGuildRoleManager
  let memberCount = guild->getMemberCount->MemberCount
  {
    t: guild,
    id: id,
    memberCount: memberCount,
    name: name,
    roles: roles,
  }
}

let wrapGuildManager = (guildManager): guildManager => {
  open Discord_GuildManager
  let keys =
    guildManager
    ->getCache
    ->Discord_Collection.keyArray
    ->Belt.Array.map(key => Discord_Snowflake.Snowflake(key))
  let values = guildManager->getCache->Discord_Collection.array
  let cache =
    Belt.Array.zip(keys, values)->Belt.Map.fromArray(~id=module(Discord_Snowflake.SnowflakeCompare))
  {t: guildManager, cache: cache}
}

let wrapRoleManager = (roleManager): roleManager => {
  open Discord_RoleManager
  let keys =
    roleManager
    ->getCache
    ->Discord_Collection.keyArray
    ->Belt.Array.map(key => Discord_Snowflake.Snowflake(key))
  let values = roleManager->getCache->Discord_Collection.array
  let cache =
    Belt.Array.zip(keys, values)->Belt.Map.fromArray(~id=module(Discord_Snowflake.SnowflakeCompare))
  let guild = roleManager->getGuild
  {t: roleManager, cache: cache, guild: guild}
}

let wrapRole = (role): role => {
  open Discord_Role
  let name = role->getName
  {t: role, name: RoleName(name)}
}

let wrapGuildMember = (member): guildMember => {
  open Discord_GuildMember

  let id = member->getGuildMemberId->Snowflake
  let roles = member->getGuildMemberRoleManager
  let guild = member->getGuild

  {
    t: member,
    id: id,
    roles: roles,
    guild: guild,
  }
}

let wrapGuildMemberRoleManager = (guildMemberRoleManager): guildMemberRoleManager => {
  {t: guildMemberRoleManager}
}

let wrapMessage = (message): message => {
  open Discord_Message
  let id = getMessageId(message)
  let content = getMessageContent(message)
  let author = getMessageAuthor(message)
  let member = getMessageMember(message)
  let channel = getMessageChannel(message)
  let guild = getMessageGuild(message)
  {
    t: message,
    id: Snowflake(id),
    content: Content(content),
    author: author,
    guild: guild,
    member: member,
    channel: channel,
  }
}
let wrapUser = (user): user => {
  open Discord_User
  let id = user->getUserId->Snowflake
  let bot = user->getUserBot->Bot
  {id: id, bot: bot}
}

let wrapChannel = (channel): channel => {
  open Discord_Channel
  let id = channel->getChannelId
  let name = channel->getChannelName
  {
    t: channel,
    id: Snowflake(id),
    name: ChannelName(name),
  }
}

let wrapReaction = reaction => {
  open Discord_Reaction
  let emoji = reaction->getReactionEmoji
  let message = reaction->getReactionMessage
  {
    t: reaction,
    message: message,
    emoji: emoji,
  }
}

let wrapEmoji = (emoji): emoji => {
  let name = emoji->Discord_Message.getEmojiName->EmojiName
  {
    t: emoji,
    name: name,
  }
}
