open Types
open Variants
open Discord_Client

exception RequestHandlerError({date: float, message: string})
@module
external parseWhitelistedChannels: unit => array<string> = "./parser/whitelistedChannels"
@module("./updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

@val @module("discord.js") external user: 'a = "Client"

Env.createEnv()

let config = Env.getConfig()

let client = createDiscordClient()

let checkWhitelistedChannel = (message: message) => {
  let channel = message.channel->wrapChannel
  let whitelistedChannels = parseWhitelistedChannels()
  let messageWhitelisted =
    whitelistedChannels->Js.Array2.reduce(
      (whitelisted, name) => ChannelName(name) === channel.name || name === "*" || whitelisted,
      false,
    )
  !messageWhitelisted && whitelistedChannels->Belt.Array.length > 0
}

let updateGistOnGuildCreate = (guild: guild) =>
  guild.id
  ->Discord_Snowflake.validateSnowflake
  ->updateGist({"name": guild.name->Discord_Guild.validateGuildName, "role": "Verified"})

let onGuildCreate = (guild: guild) => {
  let roleManager = guild.roles->wrapRoleManager

  let createRoleOptions: createRoleOptions = {
    data: {
      name: Types.RoleName("Verified"),
      color: String("ORANGE"),
    },
    reason: Reason("Verify users with BrightID"),
  }
  roleManager.t->Discord_RoleManager.create(createRoleOptions)->ignore
  guild->updateGistOnGuildCreate->ignore
}

let onMessage = (message: Types.message) => {
  let author = message.author->wrapUser
  let isBot = author.bot->Discord_User.validateBot
  switch isBot {
  | true => ()
  | false =>
    switch message->checkWhitelistedChannel {
    | true => ()
    | false => {
        let guildMember = message.member->wrapGuildMember
        let handler = Parser_DetectHandler.detectHandler(message.content)
        switch handler {
        | Some(handler) => {
            let client = client->wrapClient
            guildMember->handler(client, message)->ignore
          }
        | None => {
            message
            ->Discord_Message.reply(Types.Content("Could not find the requested command"))
            ->ignore
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

client->on(
  #ready(
    () => {
      Js.log("Logged In")
    },
  ),
)

client->on(#guildCreate(guild => guild->wrapGuild->onGuildCreate))

client->on(#message(message => message->Variants.wrapMessage->onMessage))

switch config {
| Ok(config) => client->Discord_Client.login(config["discordApiToken"])
| Error(err) => Js.log(err)
}
