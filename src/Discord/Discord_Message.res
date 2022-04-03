open Promise

type t = Types.messageT
type messageAttachment

@send external _reply: (t, string) => Js.Promise.t<t> = "reply"
@get external getMessageContent: t => string = "content"
@get external getMessageId: t => string = "id"
@get external getMessageAuthor: t => Types.userT = "author"
@get external getMessageMember: t => Types.guildMemberT = "member"
@get external getMessageChannel: t => Types.channelT = "channel"
//This return should be Js.Nullable
@get external getMessageGuild: t => Types.guildT = "guild"

@module("discord.js") @new
external createMessageAttachment: ('attachment, string, 'data) => messageAttachment =
  "MessageAttachment"
let validateContent = content =>
  switch content {
  | Types.Content(content) => content
  }

let reply = (message: Types.message, content) => {
  let content = validateContent(content)
  _reply(message.t, content)->catch(e => {
    switch e {
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    message.t->resolve
  })
}
