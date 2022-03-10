open Node.Fs
open Promise

type c
@module("discord.js") @new external createDiscordClient: unit => c = "Client"
@send external on: (c, string, unit => unit) => unit = "on"
@send external login: (c, string) => unit = "login"
@val @module("discord.js") external user: 'a = "Client"

Env.createEnv()

let config = Env.getConfig()

let client = createDiscordClient()

client
->on("ready", () => {
  Js.log("Logged In")
})
->ignore

switch config {
| Ok(discordApiToken) => client->login(discordApiToken)
| Error(err) => Js.log(err)
}

// %%raw(`

// const detectHandler = require('./parser/detectHandler')
// const {
//   RequestHandlerError,
//   WhitelistedChannelError,
// } = require('./error-utils')
// const { error, log } = require('./utils')
// const parseWhitelistedChannels = require('./parser/whitelistedChannels')
// const { updateGist, readGist } = require('./updateOrReadGist')

// client.on('guildCreate', guild => {
//   guild.roles
//     .create({
//       data: {
//         name: 'Verified',
//         color: 'ORANGE',
//       },
//       reason: 'Verify users with BrightID',
//     })
//     .catch(console.error)
//   updateGist(guild.id, {
//     name: guild.name,
//     role: 'Verified',
//   })
// })

// client.on('guildMemberAdd', member => {
//   const handler = detectHandler('!verify')
//   handler(member)
// })

// client.on('message', message => {
//   if (message.author.bot) {
//     return
//   }

//   let member = message.member

//   try {
//     const whitelistedChannels = parseWhitelistedChannels()

//     const messageWhitelisted = whitelistedChannels.reduce(
//       (whitelisted, channel) =>
//         channel === message.channel.name || channel === '*' || whitelisted,
//       false,
//     )

//     if (!messageWhitelisted && whitelistedChannels) {
//       return
//     }

//     const handler = detectHandler(message.content)
//     handler(member, client, message)

//   } catch (err) {
//     if (err instanceof RequestHandlerError) {
//       message.reply('Could not find the requested command')
//     } else if (err instanceof WhitelistedChannelError) {
//       error('FATAL: No whitelisted channels set in the environment variables.')
//     }
//   }
// })

// module.exports = client

// client.login(process.env.DISCORD_API_TOKEN)
// `)
