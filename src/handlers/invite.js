const fs = require('fs')
const { Error } = require('../error-utils')
module.exports = async function invite(member, client, message) {
  if (member.hasPermission('ADMINISTRATOR')) {
    const discordInviteRe = new RegExp(
      '(https?://)?(www.)?(discord.(gg|io|me|li)|discordapp.com/invite)/.+[a-z]',
    )
    if (discordInviteRe.test(message.content)) {
      const inviteLink = message.content.match(discordInviteRe)[0]
      const fileData = JSON.parse(fs.readFileSync('./src/guildData.json'))
      fileData[member.guild.id] = {
        ...fileData[member.guild.id],
        inviteLink,
      }
      fs.writeFileSync(
        './src/guildData.json',
        JSON.stringify(fileData, null, 2),
      )
      message.reply(`Succesfully update server invite link to ${inviteLink}`)
    } else {
      message.reply(
        'Please ensure your command includes an invite link at the end',
      )
    }
  } else {
    member.reply("You do not have the admin privileges for this command")
    throw new Error(err)
  }
}
