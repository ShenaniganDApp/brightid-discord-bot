const fs = require('fs')

const Discord = require('discord.js')
const dotenv = require('dotenv')
const client = new Discord.Client()
const detectHandler = require('./parser/detectHandler')
const {
  RequestHandlerError,
  WhitelistedChannelError,
} = require('./error-utils')
const { error, log } = require('./utils')
const parseWhitelistedChannels = require('./parser/whitelistedChannels')

dotenv.config()
client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`)
})

client.on('guildCreate', guild => {
  guild.roles
    .create({
      data: {
        name: 'Verified',
        color: 'ORANGE',
      },
      reason: 'Verify users with BrightID',
    })
    .catch(console.error)
})

client.on('guildMemberAdd', member => {
  const handler = detectHandler('!verify')
  handler(member)
})

client.on('message', message => {
  if (message.author.bot) {
    return
  }

  let member = message.member
  try {
    const whitelistedChannels = parseWhitelistedChannels()

    const messageWhitelisted = whitelistedChannels.reduce(
      (whitelisted, channel) =>
        channel === message.channel.name || channel === '*' || whitelisted,
      false,
    )

    if (!messageWhitelisted && whitelistedChannels) {
      return
    }

    const handler = detectHandler(message.content)
    handler(member)
    log(
      `Served command ${message.content} successfully for ${message.author.username}`,
    )
  } catch (err) {
    if (err instanceof RequestHandlerError) {
      message.reply(
        'Could not find the requested command. Please use !ac help for more info.',
      )
    } else if (err instanceof WhitelistedChannelError) {
      error('FATAL: No whitelisted channels set in the environment variables.')
    }
  }
})

client.login(process.env.DISCORD_API_TOKEN)
