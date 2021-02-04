const fs = require('fs')

const getBrightIdVerification = require('../services/verificationInfo')
const { VerificationError } = require('../error-utils')

module.exports = async function me(member, _, message) {
  const guild = JSON.parse(fs.readFileSync('./src/guildData.json'))[
    message.guild.id
  ]
  const role = member.guild.roles.cache.find(r => r.name === guild.role)
  try {
    const verificationInfo = await getBrightIdVerification(member)
    if (verificationInfo.userAddresses.length > 1) {
      member.send(
        'You are currently limited to one Discord account with BrightID. If there has been a mistake, message the BrightID team on Discord https://discord.gg/N4ZbNjP',
      )
      throw new VerificationError(
        `Verification Info can not be retrieved from more than one Discord account.`,
      )
    }
    if (verificationInfo.userVerified) {
      member.roles.add(role)
      member.send(
        `I recognize you! You're now a verified user in ${member.guild.name}`,
      )
      return
    } else {
      member.send('You must be verified for this role.')
    }
  } catch (err) {
    throw new Error(err)
  }
}
