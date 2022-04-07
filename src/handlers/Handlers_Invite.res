open Types
open Variants
open Promise

@module("../updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

let invite = (member: guildMember, _: client, message: message): Promise.t<messageT> => {
  let guild = message.guild->wrapGuild
  let isAdmin = member.t->Discord_GuildMember.hasPermission("ADMINISTRATOR")
  switch isAdmin {
  | false =>
    message.t
    ->Discord_Message._reply("You do not have the admin privileges for this command")
    ->ignore
  | true => {
      let inviteCommandArray =
        message.content->Discord_Message.validateContent->Js.String2.split(" ")
      let inviteLink = inviteCommandArray->Belt.Array.get(1)
      switch inviteLink {
      | None =>
        message.t
        ->Discord_Message._reply("Please Format your command like `!invite <invite link>`")
        ->ignore
      | Some(inviteLink) => {
          updateGist(
            guild.id->Discord_Snowflake.validateSnowflake,
            {
              "inviteLink": inviteLink,
            },
          )->ignore
          message.t
          ->Discord_Message._reply(`Succesfully update server invite link to ${inviteLink}`)
          ->ignore
        }
      }
    }
  }
  message.t->resolve
}
