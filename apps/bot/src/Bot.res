open Discord

exception RequestHandlerError({date: float, message: string})

module type Command = {
  let data: SlashCommandBuilder.t
  let execute: Interaction.t => Js.Promise.t<unit>
}
module type Button = {
  let customId: string
  let execute: Interaction.t => Js.Promise.t<unit>
}

@module("./updateOrReadGist.mjs")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

@val @module("discord.js") external user: 'a = "Client"

Env.createEnv()

let config = Env.getConfig()

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES"],
}

let client = Client.createDiscordClient(~options)

let commands: Collection.t<string, module(Command)> = Collection.make()
let buttons: Collection.t<string, module(Button)> = Collection.make()

commands
->Collection.set(Commands_Help.data->SlashCommandBuilder.getCommandName, module(Commands_Help))
->Collection.set(Commands_Verify.data->SlashCommandBuilder.getCommandName, module(Commands_Verify))
->ignore

buttons->Collection.set(Buttons_Verify.customId, module(Buttons_Verify))->ignore

let updateGistOnGuildCreate = (guild: Guild.t) =>
  guild->Guild.getGuildId->updateGist({"name": guild->Guild.getGuildName, "role": "Verified"})

let onGuildCreate = guild => {
  let roleManager = guild->Guild.getGuildRoleManager

  roleManager
  ->RoleManager.create({
    name: "Verified",
    color: "ORANGE",
    reason: "Create a role to mark verified users with BrightID",
  })
  ->ignore
  guild->updateGistOnGuildCreate->ignore
}

let onMessage = (message: Message.t) => {
  let author = message->Message.getMessageAuthor
  let isBot = author->User.getBot
  // switch isBot {
  // | true => ()
  // | false =>
  // switch message->checkWhitelistedChannel {
  // | true => ()
  // | false => {
  // let guildMember = message->Message.getMessageMember
  // let handler = message->Parser_DetectHandler.detectHandler
  // switch handler {
  // | Some(handler) => guildMember->handler(client, message)->ignore
  // | None => {
  //     message->Message.reply("Could not find the requested command")->ignore
  //     Js.Console.error(
  //       RequestHandlerError({
  //         date: Js.Date.now(),
  //         message: "Could not find the requested command",
  //       }),
  //     )
  //   }
  // }
  // }
}

let onInteraction = (interaction: Interaction.t) => {
  let isCommand = interaction->Interaction.isCommand
  let isButton = interaction->Interaction.isButton
  switch (isCommand, isButton) {
  | (true, false) => {
      let commandName = interaction->Interaction.getCommandName

      let command = commands->Collection.get(commandName)
      switch command->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Command not found")
      | Some(module(Command)) => Command.execute(interaction)->ignore
      }
    }

  | (false, true) => {
      let buttonCustomId = interaction->Interaction.getCustomId

      let button = buttons->Collection.get(buttonCustomId)
      switch button->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Button not found")
      | Some(module(Button)) => Button.execute(interaction)->ignore
      }
    }
  | (_, _) => Js.Console.error("Bot.res: Unknown interaction")
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

client->Client.on(#messageCreate(message => message->onMessage))

client->Client.on(#interactionCreate(interaction => interaction->onInteraction))

switch config {
| Ok(config) => client->Client.login(config["discordApiToken"])
| Error(err) => Js.log(err)
}

// @module
// external parseWhitelistedChannels: unit => <string> = "./parser/whitelistedChannels"

// let checkWhitelistedChannel = (message: Message.t) => {
//   let channel = message->Message.getMessageChannel
//   let whitelistedChannels = parseWhitelistedChannels()
//   let messageWhitelisted =
//     whitelistedChannels->Js.Array2.reduce(
//       (whitelisted, name) =>
//         name === channel->Channel.getChannelName || name === "*" || whitelisted,
//       false,
//     )
//   !messageWhitelisted && whitelistedChannels->Belt.Array.length > 0
// }
