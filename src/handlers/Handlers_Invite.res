open Discord

@module("../updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

let invite = (member: GuildMember.t, _: Client.t, message: Message.t): Promise.t<Message.t> => {
  let guild = message->Message.getMessageGuild
  let isAdmin = member->GuildMember.hasPermission("ADMINISTRATOR")
  switch isAdmin {
  | false => message->Message.reply("You do not have the admin privileges for this command")
  | true => {
      let inviteCommandArray = message->Message.getMessageContent->Js.String2.split(" ")
      let inviteLink = inviteCommandArray->Belt.Array.get(1)
      switch inviteLink {
      | None => message->Message.reply("Please Format your command like `!invite <invite link>`")
      | Some(inviteLink) => {
          updateGist(
            guild->Guild.getGuildId,
            {
              "inviteLink": inviteLink,
            },
          )->ignore
          message->Message.reply(`Succesfully update server invite link to ${inviteLink}`)
        }
      }
    }
  }
}
