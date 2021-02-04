const fs = require('fs')
const { error } = require('../error-utils')
module.exports = async function role(member, client, message) {
  if (member.hasPermission('ADMINISTRATOR')) {
    const role = message.content.split(/(?<=^\S+)\s/)[1]
    if (role) {
      const fileData = JSON.parse(fs.readFileSync('./src/guildData.json'))
      const previousRole = fileData[member.guild.id].role
      const guildRole = message.guild.roles.cache.find(
        r => r.name === previousRole,
      )
      try {
        await guildRole.edit({ name: role })
        fileData[member.guild.id] = {
          ...fileData[member.guild.id],
          role,
        }
        fs.writeFileSync(
          './src/guildData.json',
          JSON.stringify(fileData, null, 2),
        )
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
