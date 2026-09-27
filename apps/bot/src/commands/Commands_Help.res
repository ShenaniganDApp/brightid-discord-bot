open Discord

let helpMessage = `\
__**Available BrightId Unique Bot commands:**__

- \`/verify\` → Sends a BrightID QR code for users to connect with their BrightId.

[Privacy Policy](https://github.com/ShenaniganDApp/brightid-discord-bot/blob/master/PRIVACY.md)

`

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("help")
  ->SlashCommandBuilder.setDescription("Explain the BrightId bot commands")

let execute = async (interaction: Interaction.t) => {
  switch await interaction->Interaction.reply(
    ~options={"content": helpMessage, "ephemeral": true},
    (),
  ) {
  | exception JsError(obj) =>
    Console.error(obj)
    JsError(obj)->raise
  | _ => ()
  }
}
