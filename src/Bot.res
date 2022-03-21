// let errorUtils = %raw(`require('./error-utils')`)
// let utils = %raw(`require('./utils')`)
exception RequestHandlerError({date: float, message: string})
@module
external parseWhitelistedChannels: unit => array<string> = "./parser/whitelistedChannels"
@module("./updateOrReadGist.js")
external updateGist: (Discord_Snowflake.snowflake, 'a) => unit = "updateGist"

@val @module("discord.js") external user: 'a = "Client"

Env.createEnv()

let config = Env.getConfig()

let client = Discord_Client.make()

client
->Discord_Client.validateClient
->Discord_Client.on(
  #ready(
    () => {
      Js.log("Logged In")
    },
  ),
)

let updateGistOnGuildCreate = (guild: Discord_Guild.guild) =>
  guild.id->updateGist({"name": guild.name, "role": "Verified"})

let onGuildCreate = (guild: Discord_Guild.guild) => {
  let roleManager = guild.roles

  let makeRoleOptions: Discord_RoleManager.makeRoleOptions = {
    data: {
      name: Discord_Role.RoleName("Verified"),
      color: String("ORANGE"),
    },
    reason: Reason("Verify users with BrightID"),
  }
  roleManager.t->Discord_RoleManager.makeGuildRole(makeRoleOptions)->ignore
  guild->updateGistOnGuildCreate
  // ->catch(e => {
  //   switch e {
  //   | CreateRoleError(msg) => Js.log("ReScript Error caught:" ++ msg)
  //   | JsError(obj) =>
  //     switch Js.Exn.message(obj) {
  //     | Some(msg) => Js.log("Some JS error msg: " ++ msg)
  //     | None => Js.log("Must be some non-error value")
  //     }
  //   | _ => Js.log("Some unknown error")
  //   }
  //   resolve()
  // })
}

client
->Discord_Client.validateClient
->Discord_Client.on(#guildCreate(guild => guild->Discord_Guild.make->onGuildCreate))

let tap = args => {
  Js.log(args)
  args
}

let checkWhitelistedChannel = (message: Discord_Message.message) => {
  let whitelistedChannels = parseWhitelistedChannels()
  let messageWhitelisted =
    whitelistedChannels->Js.Array2.reduce(
      (whitelisted, channel) =>
        Discord_Channel.ChannelName(channel) === message.channel.name ||
        channel === "*" ||
        whitelisted,
      false,
    )
  !messageWhitelisted && whitelistedChannels->Belt.Array.length > 0
}

let onMessage = (message: Discord_Message.message) => {
  let isBot = message.author.bot->Discord_User.validateBot
  switch isBot {
  | true => ()
  | false =>
    switch message->checkWhitelistedChannel {
    | true => ()
    | false => {
        let handler = Parser_DetectHandler.detectHandler(message.content)
        switch handler {
        | Some(handler) => message.member->handler(client, message)
        | None => {
            message->Discord_Message.reply(
              Discord_Message.Content("Could not find the requested command"),
            )
            Js.Console.error(
              RequestHandlerError({
                date: Js.Date.now(),
                message: "Could not find the requested command",
              }),
            )
          }
        }
      }
    }
  }
}

client
->Discord_Client.validateClient
->Discord_Client.on(
  #message(
    message =>
      message->Discord_Message.make->onMessage,
      //   if (err instanceof RequestHandlerError) {
      //     message.reply('Could not find the requested command')
      //   } else if (err instanceof WhitelistedChannelError) {
      //     error('FATAL: No whitelisted channels set in the environment variables.')
      //   }
      // }
  ),
)

switch config {
| Ok(discordToken) => client->Discord_Client.login(discordToken)
| Error(err) => Js.log(err)
}

// %%raw(`

// client.on('guildMemberAdd', member => {
//   const handler = detectHandler('!verify')
//   handler(member)
// })

// module.exports = client

// client.login(process.env.DISCORD_API_TOKEN)
// `)
