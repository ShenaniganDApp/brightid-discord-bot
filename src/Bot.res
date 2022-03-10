let detectHandler = %raw(`require('./parser/detectHandler')`)
let errorUtils = %raw(`require('./error-utils')`)
let utils = %raw(`require('./utils')`)
let parseWhitelistedChannels = %raw(`require('./parser/whitelistedChannels')`)
@module("./updateOrReadGist.js") external updateGist: (string, 'a) => unit = "updateGist"

@val @module("discord.js") external user: 'a = "Client"

open Promise

Env.createEnv()

let config = Env.getConfig()

let client = Discord_Client.make()

client
->Discord_Client.onEvent(
  Ready(
    () => {
      Js.log("Logged In")
    },
  ),
)
->ignore

switch config {
| Ok(discordToken) => client->Discord_Client.loginClient(discordToken)
| Error(err) => Js.log(err)
}

// let validateGuild = guild => {
//   switch guild {
//   | Discord_Client.Guild({roles: roleManager}) => {"roles": roleManager}
//   }
// }

client->Discord_Client.onEvent(
  GuildCreate(
    guild => {
      open Discord_Client
      let roleManager = guild->getGuildRoleManager
      let createRoleOptions = CreateRoleOptions({
        data: RoleData({
          name: RoleName("Verified"),
          color: String("ORANGE"),
        }),
        reason: Reason("Verify users with BrightID"),
      })
      roleManager
      ->createGuildRoleClient(createRoleOptions)
      ->then(role => {
        Js.log2("role", role)
        resolve(role)
      })
      ->ignore
      // ->then(
      //   resolve
      //   updateGist(
      //     guild.id,
      //     {
      //       name: guild.name,
      //       role: "Verified",
      //     },
      //   ),
      // )
      // ->catch(err => Js.log(err)->ignore)
    },
  ),
)

// %%raw(`

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
