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
const { updateGist, readGist } = require('./updateOrReadGist')

dotenv.config()
client.on('ready', async () => {
  console.log(`Logged in as ${client.user.tag}!`)
  const guilds = await readGist()
  const clientGuilds = client.guilds.cache.array()

  function printSlowly(array, speed) {
    if (array.length == 0) return
    if (!(clientGuilds[array.length - 1].id in guilds)) {
      setTimeout(function () {
        updateGist(clientGuilds[array.length - 1].id, {
          name: clientGuilds[array.length - 1].name,
          role: 'Verified',
        })

        printSlowly(array.slice(1), speed)
      }, speed)
    } else {
      printSlowly(array.slice(1), speed)
    }
  }

  printSlowly(clientGuilds, 5000)
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
  updateGist(guild.id, {
    name: guild.name,
    role: 'Verified',
  })
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
    handler(member, client, message)
    log(
      `Served command ${message.content} successfully for ${message.author.username}`,
    )
  } catch (err) {
    if (err instanceof RequestHandlerError) {
      message.reply('Could not find the requested command')
    } else if (err instanceof WhitelistedChannelError) {
      error('FATAL: No whitelisted channels set in the environment variables.')
    }
  }
})

module.exports = client

client.login(process.env.DISCORD_API_TOKEN)
