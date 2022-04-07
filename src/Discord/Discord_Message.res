open Promise
open Types

type t = messageT
type messageAttachment

@get external getEmojiName: emojiT => string = "emoji"

let validateEmojiName = name => {
  switch name {
  | EmojiName(name) => name
  }
}

@send external _reply: (t, 'options) => Js.Promise.t<t> = "reply"
@send external _react: (t, string) => Js.Promise.t<emojiT> = "react"
@send external _edit: (t, 'options) => Js.Promise.t<t> = "pin"

@get external getMessageContent: t => string = "content"
@get external getMessageId: t => string = "id"
@get external getMessageAuthor: t => userT = "author"
@get external getMessageMember: t => guildMemberT = "member"
@get external getMessageChannel: t => channelT = "channel"
//@TODO:This return should be Js.Nullable
@get external getMessageGuild: t => guildT = "guild"
@get external getMessageReactions: t => reactionManagerT = "reactions"

@module("discord.js") @new
external createMessageAttachment: ('attachment, string, 'data) => messageAttachment =
  "MessageAttachment"

let validateContent = (content: content) =>
  switch content {
  | Content(content) => content
  }

let reply = (message: message, options) => {
  let content = switch options {
  | Content(content) => content
  | MessagePayload => ""
  | MessageOptions => ""
  }
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
