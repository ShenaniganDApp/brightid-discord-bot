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
  const clientGuilds = client.guilds.cache

  for (let i = 0; i < clientGuilds.length; i++) {
    if (!(clientGuilds[i].id in guilds)) {
      setTimeout(() => {
        updateGist(clientGuilds[i].id, {
          name: clientGuilds[i].name,
          role: 'Verified',
        })
      }, 5000 * i)
    }
  }
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
  const fileData = JSON.parse(fs.readFileSync('./src/guildData.json'))
  fileData[guild.id] = {
    name: guild.name,
    role: 'Verified',
    inviteLink: '',
    verifications: [],
  }
  fs.writeFileSync('./src/guildData.json', JSON.stringify(fileData, null, 2))
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
