const fs = require('fs')
const { error } = require('../error-utils')
const { readGist, updateGist } = require('../updateOrReadGist')
module.exports = async function role(member, client, message) {
  if (member.hasPermission('ADMINISTRATOR')) {
    const role = message.content.split(/(?<=^\S+)\s/)[1]
    if (role) {
      const guilds = await readGist()
      const previousRole = guilds[message.guild.id].role
      const guildRole = message.guild.roles.cache.find(
        r => r.name === previousRole,
      )
      try {
        await guildRole.edit({ name: role })
        await updateGist(message.guild.id, { role })
        message.reply(`Succesfully update verified role to ${role}`)
      } catch (err) {
        console.log('err: ', err)
      }
    } else {
      message.reply(
        'Please ensure your command includes a role name at the end',
      )
    }
  } else {
    message.reply('You do not have the admin privileges for this command')
  }
}
