open Discord

let helpMessage = `\
__**Available BrightId Unique Bot commands:**__

- \`/verify\` → Sends a BrightID QR code for users to connect with their BrightId.


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
