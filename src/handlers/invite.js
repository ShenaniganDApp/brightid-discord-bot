const fs = require('fs')
const { Error } = require('../error-utils')
const { updateGist } = require('../updateOrReadGist')
module.exports = async function invite(member, client, message) {
  if (member.hasPermission('ADMINISTRATOR')) {
    const discordInviteRe = new RegExp(
      '(https?://)?(www.)?(discord.(gg|io|me|li)|discordapp.com/invite)/.+[a-z]',
    )
    if (discordInviteRe.test(message.content)) {
      const inviteLink = message.content.match(discordInviteRe)[0]
      await updateGist(message.guild.id, {
        inviteLink,
      })
      message.reply(`Succesfully update server invite link to ${inviteLink}`)
    } else {
      message.reply(
        'Please ensure your command includes an invite link at the end',
      )
    }
  } else {
    member.reply('You do not have the admin privileges for this command')
    throw new Error(err)
  }
}
