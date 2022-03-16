open Discord_Snowflake
type content = Content(string)

type message = {
  id: snowflake,
  content: content,
  author: Discord_User.user,
  member: Discord_Guild.guildMember,
  channel: Discord_Channel.channel,
}

@get external getMessageContent: 'message => string = "content"
@get external getMessageId: 'message => string = "id"
@get external getMessageAuthor: 'message => 'author = "author"
@get external getMessageMember: 'message => Discord_Guild.guildMember = "member"
@get external getMessageChannel: 'message => 'channel = "channel"

let make = message => {
  let id = getMessageId(message)
  let content = getMessageContent(message)
  let author = getMessageAuthor(message)
  let member = getMessageMember(message)
  let channel = getMessageChannel(message)
  {
    id: Snowflake(id),
    content: Content(content),
    author: author,
    member: member,
    channel: channel,
  }
}
