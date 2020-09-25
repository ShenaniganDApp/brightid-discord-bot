const fs = require('fs')
const getBrightIdVerification = require('../services/verificationInfo')
const UUID = require('uuid')

module.exports = async function me(member) {
  const ID = UUID.v5(member.id, process.env.UUID_NAMESPACE)
  const role = member.guild.roles.cache.find(r => r.name === 'Verified')
  try {
    const verificationInfo = await getBrightIdVerification(member)
    // if (verificationInfo.userAddresses.length > 1) {
    //     member.send(
    //       'You are currently limited to one Discord account with BrightID. If there has been a mistake, message the BrightID team on Discord https://discord.gg/N4ZbNjP',
    //     )
    //     throw new VerificationError(
    //       `Verification Info can not be retrieved from more than one Discord account.`,
    //     )
    //   }
    if (verificationInfo.userVerified) {
      member.roles.add(role)
      member.send(
        "We recognized you! You're now a verified BrightID user on Discord.",
      )
      if (!verifiedUsers['contextIds'].includes(ID)) {
        fs.readFile(
          './src/verifiedUsers.json',
          'utf8',
          function readFileCallback(err, data) {
            if (err) {
              console.log(err)
            } else {
              obj = JSON.parse(data) //now it an object
              obj.contextIds.push(ID) //add some data
              json = JSON.stringify(obj) //convert it back to json
              fs.writeFile('./src/verifiedUsers.json', json, 'utf8', () => {}) // write it back
            }
          },
        )
      }
    } else {
      member.send('You must be verified for this role.')
    }
  } catch (err) {
    throw new Error(err)
  }
}
