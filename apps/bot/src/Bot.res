open Discord

exception RequestHandlerError({date: float, message: string})
@module
external parseWhitelistedChannels: unit => array<string> = "./parser/whitelistedChannels"
@module("./updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

@val @module("discord.js") external user: 'a = "Client"

Env.createEnv({"path": "../../.env"})

let config = Env.getConfig()

let client = Client.createDiscordClient()

let checkWhitelistedChannel = (message: Message.t) => {
  let channel = message->Message.getMessageChannel
  let whitelistedChannels = parseWhitelistedChannels()
  let messageWhitelisted =
    whitelistedChannels->Js.Array2.reduce(
      (whitelisted, name) =>
        name === channel->Channel.getChannelName || name === "*" || whitelisted,
      false,
    )
  !messageWhitelisted && whitelistedChannels->Belt.Array.length > 0
}

let updateGistOnGuildCreate = (guild: Guild.t) =>
  guild->Guild.getGuildId->updateGist({"name": guild->Guild.getGuildName, "role": "Verified"})

let onGuildCreate = guild => {
  let roleManager = guild->Guild.getGuildRoleManager

  let createRoleOptions = RoleManager.makeCreateRoleOptions(
    ~data={
      "name": "Verified",
      "color": "ORANGE",
    },
    ~reason="Verify users with BrightID",
  )
  roleManager->RoleManager.create(~createRoleOptions)->ignore
  guild->updateGistOnGuildCreate->ignore
}

let onMessage = (message: Message.t) => {
  let author = message->Message.getMessageAuthor
  let isBot = author->User.getBot
  switch isBot {
  | true => ()
  | false =>
    switch message->checkWhitelistedChannel {
    | true => ()
    | false => {
        let guildMember = message->Message.getMessageMember
        let handler = message->Parser_DetectHandler.detectHandler
        switch handler {
        | Some(handler) => guildMember->handler(client, message)->ignore
        | None => {
            message->Message.reply("Could not find the requested command")->ignore
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

client->Client.on(
  #ready(
    () => {
      Js.log("Logged In")
    },
  ),
)

client->Client.on(#guildCreate(guild => guild->onGuildCreate))

client->Client.on(#message(message => message->onMessage))

switch config {
| Ok(config) => client->Client.login(config["discordApiToken"])
| Error(err) => Js.log(err)
}
