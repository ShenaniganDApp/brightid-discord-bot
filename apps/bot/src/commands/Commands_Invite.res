open Discord
open Promise

exception InviteCommandError(string)

@module("../updateOrReadGist.mjs")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

let urlRe = %re(
  "/(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})/"
)

let execute = (interaction: Interaction.t) => {
  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let isAdmin = member->GuildMember.getPermissions->Permissions.has(Permissions.Flags.administrator)
  let commandOptions = interaction->Interaction.getOptions
  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    switch isAdmin {
    | false =>
      interaction
      ->Interaction.editReply(
        ~options={"content": "Only administrators can change the invite link"},
        (),
      )
      ->ignore
      InviteCommandError("Commands_Invite: User does not hav Administrator permissions")->raise
    | true => {
        let inviteLink = commandOptions->CommandInteractionOptionResolver.getString("invite")
        switch inviteLink->Js.Nullable.toOption {
        | None =>
          interaction
          ->Interaction.editReply(
            ~options={"content": "I didn't receive an invite link. (For some unexplained reason)"},
            (),
          )
          ->ignore
          InviteCommandError("Commands_Invite: Invite Link returned null or undefined")->reject
        | Some(inviteLink) =>
          switch urlRe->Js.Re.test_(inviteLink) {
          | false => {
              interaction
              ->Interaction.editReply(
                ~options={"content": "The invite link is not a valid URL"},
                (),
              )
              ->ignore
              InviteCommandError("Commands_Invite: Invite Link is not a valid URL")->reject
            }

          | true =>
            updateGist(
              guild->Guild.getGuildId,
              {
                "inviteLink": inviteLink,
              },
            )->ignore

            interaction
            ->Interaction.editReply(
              ~options={
                "content": `Successfully update server invite link to ${inviteLink}`,
                "ephemeral": true,
              },
              (),
            )
            ->ignore
            resolve()
          }
        }
      }
    }
  })
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("invite")
  ->SlashCommandBuilder.setDescription("Add an invite link to be displayed for this server")
  ->SlashCommandBuilder.addStringOption(option => {
    open SlashCommandStringOption
    option
    ->setName("invite")
    ->setDescription("Enter an invite link to this server")
    ->setRequired(true)
  })
