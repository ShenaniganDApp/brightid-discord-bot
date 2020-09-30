const fs = require('fs')
const getBrightIdVerification = require('../services/verificationInfo')
const UUID = require('uuid')
const verifiedUsers = require('../verifiedUsers.json')
const { VerificationError } = require('../error-utils')
const { log } = require('../utils')


module.exports = async function me(member) {
  const ID = UUID.v5(member.id, process.env.UUID_NAMESPACE)
  const role = member.guild.roles.cache.find(r => r.name === 'Verified')
  fs.readFile(
    './src/verifiedUsers.json',
    'utf8',
    function readFileCallback(err, data) {
      if (err) {
        console.log(err)
      } else {
        const { contextIds } = JSON.parse(data)
        log(contextIds.length)
      }
    },
  )
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
      if (!verifiedUsers.contextIds.includes(ID)) {
        member.roles.add(role)
        fs.readFile(
          './src/verifiedUsers.json',
          'utf8',
          function readFileCallback(err, data) {
            if (err) {
              console.log(err)
            } else {
              const obj = JSON.parse(data)
              obj.contextIds.push(ID)
              member.send(
                `We recognized you! You are the ${obj.contextIds.length} person to be verified using our bot.`,
              )
              json = JSON.stringify(obj)
              fs.writeFile('./src/verifiedUsers.json', json, 'utf8', () => {})
            }
          },
        )
      } else {
        member.roles.add(role)
        member.send(
          `I recognize you! You're now a verified user in ${member.guild.name}`,
        )
        return
      }
    } else {
      member.send('You must be verified for this role.')
    }
  } catch (err) {
    throw new Error(err)
  }
}
