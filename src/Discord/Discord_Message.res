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
}

@send external createReply: (t, string) => unit = "reply"
@get external getMessageContent: t => string = "content"
@get external getMessageId: t => string = "id"
@get external getMessageAuthor: t => Discord_User.t = "author"
@get external getMessageMember: t => Discord_Guild.guildMember = "member"
@get external getMessageChannel: t => Discord_Channel.t = "channel"

let validateContent = content =>
  switch content {
  | Content(content) => content
  }

let reply = (message, content) => {
  let content = validateContent(content)
  createReply(message, content)
}

let make = message => {
  let id = getMessageId(message)
  let content = getMessageContent(message)
  let author = getMessageAuthor(message)
  let member = getMessageMember(message)
  let channel = getMessageChannel(message)
  {
    t: message,
    id: Snowflake(id),
    content: Content(content),
    author: Discord_User.make(author),
    member: member,
    channel: Discord_Channel.make(channel),
  }
}
