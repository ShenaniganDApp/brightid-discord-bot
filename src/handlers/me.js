const fs = require('fs')
const { sponsor } = require('brightid_sdk')
const UUID = require('uuid')
const { ethers } = require('ethers')
const { CONTEXT_ID, CONTRACT_ABI, CONTRACT_ADDRESS } = require('../constants')

const getBrightIdVerification = require('../services/verificationInfo')
const { VerificationError } = require('../error-utils')
const { readGist, updateGist } = require('../updateOrReadGist')

module.exports = async function me(member, _, message) {
  const guilds = await readGist()
  const guild = guilds[message.guild.id]
  const role = member.guild.roles.cache.find(r => r.name === guild.role)
  const ID = UUID.v5(member.id, process.env.UUID_NAMESPACE)

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
      // Sponsor member
      // Check IDChain to see how many sponsorships this address has
      const provider = new ethers.getDefaultProvider()
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        provider,
      )

      // Get the number of sponsorships assigned to the Discord context by the specified address
      const formattedContext = ethers.utils.formatBytes32String('Discord')
      const spBalance = await contract.contextBalance(address, formattedContext)
      const formattedBalance = parseInt(ethers.utils.formatUnits(spBalance, 0))

      // Assign that many sponsorships in the gist for the guild with this address
      updateGist(message.guild.id, {
        assignedSp: formattedBalance,
      })

      // CONTEXT_ID and ID are a little confusing here
      // CONTEXT_ID corresponds to the application context that is sponsoring the user, 'Discord' in this case
      // ID corresponds to the unique ID of the user being sponsored, which is referred to as contextId on BrightID's end
      if (ethers.utils.formatUnits(spBalance, 0) > 0) {
        sponsor(sponsorKey, CONTEXT_ID, ID)
        // Now that the user is sponsored, we need to decrement the amount of sp for this guild
        updateGist(message.guild.id, {
          assignedSp: formattedBalance - 1,
        })
      } else {
        member.send(`This guild has no sponsorships available.`)
        return
      }

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
