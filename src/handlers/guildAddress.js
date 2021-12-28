const fs = require('fs')
const Discord = require('discord.js')
const { ethers } = require('ethers')

const { QRCodeError } = require('../error-utils')
const { readGist, updateGist } = require('../updateOrReadGist')

const { CONTRACT_ABI, CONTRACT_ADDRESS } = require('../constants')

module.exports = async function guildAddress(member, _, message) {
  // Make sure only mods can run this command
  if (!member.hasPermission('ADMINISTRATOR')) {
    message.reply('You need to be an admin to do that.')
    return
  }
  // Parse out the message content
  const args = message.content.split(' ')
  // Make sure the first argument passed is an address
  if (args[1].substring(0, 2) === '0x') {
    const address = args[1]

    // Check the gist to see if current guild exists
    const guilds = await readGist()
    const guild = guilds[message.guild.id]

    // We also need to set the last block checked so we can track this when we filter our assign events
    // This will be updated when someone runs the !me command and we check sponsorship amounts
    if (guild) {
      // If it does, assign the entered address
      updateGist(message.guild.id, {
        address,
      })
    } else {
      // If it does not, create it and assign the entered address
      updateGist(message.guild.id, {
        name: [message.guild.id].name,
        role: 'Verified',
        address,
      })
    }

    // Now check IDChain to see how many sponsorships this address has
    const provider = new ethers.getDefaultProvider()
    const contract = new ethers.Contract(
      CONTRACT_ADDRESS,
      CONTRACT_ABI,
      provider,
    )

    // Get the number of sponsorships assigned to the Discord context by the specified address
    const formattedContext = ethers.utils.formatBytes32String('Discord')
    const spBalance = await contract.contextBalance(address, formattedContext)

    // Set that amount as the totalAssignedSp for this guild
    updateGist(message.guild.id, {
      assignedSp: ethers.utils.formatUnits(spBalance, 0),
    })

    message.reply('Successfully assigned address to guild.')
  } else {
    message.reply(
      'Make sure you add a valid Ethereum address after !guildAddress',
    )
  }
}
