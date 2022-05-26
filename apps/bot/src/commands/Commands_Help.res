open Discord
open Promise

let helpMessage = `\`\`\`
__**Available BrightId commands:**__
- \`/verify\` → Sends a BrightID QR code for users to connect with their BrightId
- \`/me\` → After scanning the qr code, add yourself to the list of verified users
- \`/guilds\` → View a list of discord servers that use this bot. Lots of cool servers use BrightId for token airdrops 😉
__**admin only**__
- \`/role\` → Use this command to change the name of the "Verified" role
- \`/invite\` → Use this command to add an invite for this discord to the guilds
\`\`\``

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("help")
  ->SlashCommandBuilder.setDescription("Explain the BrightId bot commands")

let execute = (interaction: Interaction.t) => {
  interaction->Interaction.reply(~content=helpMessage, ~options={"ephemeral": true}, ())->ignore
  resolve()
}
