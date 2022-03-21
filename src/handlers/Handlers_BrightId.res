open Discord_Message
let brightIdContent = `
__**Available BrightId commands:**__
- \`!verify\` → Sends a BrightID QR code for users to connect with their BrightId
- \`!me\`→ After scanning the qr code, add yourself to the list of verified users
- \`!guilds\` → View a list of discord servers that use this bot. Lots of cool servers use BrightId for token airdrops 😉
__**admin only**__
- \`!role\` → Use this command to change the name of the "Verified" role
- \`!invite\` → Use this command to add an invite for this discord to the guilds
`

let brightId = (_: Discord_Guild.guildMember, _: Discord_Client.client, message: message) => {
  message->reply(brightIdContent->Content)
}
