open Discord_Snowflake
type content = Content(string)

type t
type message = {
  t: t,
  id: snowflake,
  content: content,
  author: Discord_User.user,
  member: Discord_Guild.guildMember,
  channel: Discord_Channel.channel,
  guild: Discord_Guild.guild,
}

@send external createReply: (t, string) => unit = "reply"
@get external getMessageContent: t => string = "content"
@get external getMessageId: t => string = "id"
@get external getMessageAuthor: t => Discord_User.t = "author"
@get external getMessageMember: t => Discord_Guild.guildMember = "member"
@get external getMessageChannel: t => Discord_Channel.t = "channel"
//This return should be Js.Nullable
@get external getMessageGuild: t => Discord_Guild.t = "guild"

let validateContent = content =>
  switch content {
  | Content(content) => content
  }

let reply = (message, content) => {
  let content = validateContent(content)
  createReply(message.t, content)
}

let make = message => {
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
    author: Discord_User.make(author),
    guild: Discord_Guild.make(guild),
    member: member,
    channel: Discord_Channel.make(channel),
  }
}
