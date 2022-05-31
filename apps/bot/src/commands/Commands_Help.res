open Discord
open Promise

let helpMessage = `\
__**Available BrightId Unique Bot commands:**__

- \`/verify\` → Sends a BrightID QR code for users to connect with their BrightId

- \`/guilds\` → View a list of discord servers that use this bot. Lots of cool servers use BrightId for token airdrops 😉


Server Admin only:
- \`/role\` → Use this command to change the name of the "Verified" role

- \`/invite\` → Use this command to add an invite for this discord to the guilds

`

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("help")
  ->SlashCommandBuilder.setDescription("Explain the BrightId bot commands")

let execute = (interaction: Interaction.t) => {
  interaction->Interaction.reply(~options={"content": helpMessage, "ephemeral": true}, ())->ignore
  resolve()
}
