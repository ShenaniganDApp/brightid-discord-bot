open Discord
open Promise

exception RequestHandlerError({date: float, message: string})
exception GuildNotInGist(string)

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

let envConfig = Env.getConfig()

let envConfig = switch envConfig {
| Ok(envConfig) => envConfig
| Error(err) => err->Env.EnvError->raise
}

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES"],
}

let client = Client.createDiscordClient(~options)

let commands: Collection.t<string, module(Command)> = Collection.make()
let buttons: Collection.t<string, module(Button)> = Collection.make()

// One by one is the only way I can find to do this atm. Hopefully we find a better way
commands
->Collection.set(Commands_Help.data->SlashCommandBuilder.getCommandName, module(Commands_Help))
->Collection.set(Commands_Verify.data->SlashCommandBuilder.getCommandName, module(Commands_Verify))
->Collection.set(Commands_Role.data->SlashCommandBuilder.getCommandName, module(Commands_Role))
->Collection.set(Commands_Invite.data->SlashCommandBuilder.getCommandName, module(Commands_Invite))
->Collection.set(Commands_Guild.data->SlashCommandBuilder.getCommandName, module(Commands_Guild))
->ignore

buttons->Collection.set(Buttons_Verify.customId, module(Buttons_Verify))->ignore

// @TODO: these blocks should go in a shared package
// @TODO this should be a record
type brightIdGuild = {
  "role": string,
  "name": string,
  "inviteLink": option<string>,
  "roleId": string,
}

type brightIdGuilds = Js.Dict.t<brightIdGuild>

let guild = Json.Decode.object(field =>
  {
    "role": field.optional(. "role", Json.Decode.string),
    "name": field.optional(. "name", Json.Decode.string),
    "inviteLink": field.optional(. "inviteLink", Json.Decode.string),
    "roleId": field.optional(. "roleId", Json.Decode.string),
  }
)

let brightIdGuilds = guild->Json.Decode.dict

let updateGistOnGuildCreate = (guild: Guild.t, roleId) => {
  let guildId = guild->Guild.getGuildId

  guildId->updateGist({
    "name": guild->Guild.getGuildName,
    "role": "Verified",
    "roleId": roleId,
  })
}

let onGuildCreate = guild => {
  let roleManager = guild->Guild.getGuildRoleManager

  roleManager
  ->RoleManager.create({
    name: "Verified",
    color: "ORANGE",
    reason: "Create a role to mark verified users with BrightID",
  })
  ->then(role => {
    guild->updateGistOnGuildCreate(role->Role.getRoleId)
  })
  ->ignore
}

let onInteraction = (interaction: Interaction.t) => {
  let isCommand = interaction->Interaction.isCommand
  let isButton = interaction->Interaction.isButton
  let user = interaction->Interaction.getUser
  switch (isCommand, isButton) {
  | (true, false) => {
      let commandName = interaction->Interaction.getCommandName

      let command = commands->Collection.get(commandName)
      switch command->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Command not found")
      | Some(module(Command)) =>
        Command.execute(interaction)
        ->then(_ =>
          Js.Console.log(
            `Successfully served the command ${commandName} for ${user->User.getUsername}`,
          )->resolve
        )
        ->ignore
      }
    }

  | (false, true) => {
      let buttonCustomId = interaction->Interaction.getCustomId

      let button = buttons->Collection.get(buttonCustomId)
      switch button->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Button not found")
      | Some(module(Button)) =>
        Button.execute(interaction)
        ->then(_ =>
          Js.Console.log(
            `Successfully served button press "${buttonCustomId}" for ${user->User.getUsername}`,
          )->resolve
        )
        ->ignore
      }
    }

  | (_, _) => Js.Console.error("Bot.res: Unknown interaction")
  }
}

let onGuildDelete = guild => {
  open! Utils.Gist
  let config = makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=githubAccessToken,
  )

  let guildId = guild->Guild.getGuildId

  ReadGist.content(~config, ~decoder=brightIdGuilds)
  ->then(content => {
    let brightIdGuild = content->Js.Dict.get(guildId)
    switch brightIdGuild {
    | Some(_) =>
      guild
      ->Guild.getGuildId
      ->UpdateGist.removeEntry(~content, ~key=_, ~config)
      ->then(_ => resolve())

    | None => Js.log(`No role to delete for guild ${guildId}`)->resolve
    }
  })
  ->catch(err => {
    Js.Console.error(err)
    resolve()
  })
  ->ignore
}

client->Client.on(
  #ready(
    () => {
      Js.log("Logged In")
    },
  ),
)

client->Client.on(#guildCreate(guild => guild->onGuildCreate))

client->Client.on(#interactionCreate(interaction => interaction->onInteraction))

client->Client.on(#guildDelete(guild => guild->onGuildDelete))

client->Client.login(envConfig["discordApiToken"])->ignore

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
