open Discord
open Promise
open NodeFetch
open Shared

let {brightIdVerificationEndpoint} = module(Endpoints)
let {context} = module(Constants)

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

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

@module("./updateOrReadGist.mjs")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

Env.createEnv()

let envConfig = Env.getConfig()

let envConfig = switch envConfig {
| Ok(envConfig) => envConfig
| Error(err) => err->Env.EnvError->raise
}

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES", "GUILD_MEMBERS"],
}

let client = Client.createDiscordClient(~options)

let commands: Collection.t<string, module(Command)> = Collection.make()
let buttons: Collection.t<string, module(Button)> = Collection.make()

// One by one is the only way I can find to do this atm. Hopefully we find a better way
let _ =
  commands
  ->Collection.set(Commands_Help.data->SlashCommandBuilder.getCommandName, module(Commands_Help))
  ->Collection.set(
    Commands_Verify.data->SlashCommandBuilder.getCommandName,
    module(Commands_Verify),
  )
  ->Collection.set(
    Commands_Invite.data->SlashCommandBuilder.getCommandName,
    module(Commands_Invite),
  )
  ->Collection.set(Commands_Guild.data->SlashCommandBuilder.getCommandName, module(Commands_Guild))

let _ =
  buttons
  ->Collection.set(Buttons_Verify.customId, module(Buttons_Verify))
  ->Collection.set(Buttons_Sponsor.customId, module(Buttons_Sponsor))
  ->Collection.set(Buttons_PremiumSponsor.customId, module(Buttons_PremiumSponsor))

let updateGistOnGuildCreate = async (guild: Guild.t, roleId) => {
  open Utils
  open Shared.Decode
  let id = envConfig["gistId"]
  let name = "guildData.json"
  let token = envConfig["githubAccessToken"]
  let config = Gist.makeGistConfig(~id, ~name, ~token)

  let guildId = guild->Guild.getGuildId

  let content = await Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)

  let entry = {
    open Shared.BrightId.Gist
    {
      name: guild->Guild.getGuildName->Some,
      role: Some("Verified"),
      roleId: Some(roleId),
      inviteLink: None,
      sponsorshipAddress: None,
      usedSponsorships: None,
      assignedSponsorships: None,
      premiumSponsorshipsUsed: None,
      premiumExpirationTimestamp: None,
    }
  }

  await Gist.UpdateGist.addEntry(~content, ~config, ~key=guildId, ~entry)
}

let onGuildCreate = async guild => {
  let roleManager = guild->Guild.getGuildRoleManager

  let role = await RoleManager.create(
    roleManager,
    {
      name: "Verified",
      color: "ORANGE",
      reason: "Create a role to mark verified users with BrightID",
    },
  )

  (await updateGistOnGuildCreate(guild, role->Role.getRoleId))->ignore
}

let onInteraction = async (interaction: Interaction.t) => {
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
        await Command.execute(interaction)
        Js.Console.log(
          `Successfully served the command ${commandName} for ${user->User.getUsername}`,
        )
      }
    }

  | (false, true) => {
      let buttonCustomId = interaction->Interaction.getCustomId

      let button = buttons->Collection.get(buttonCustomId)
      switch button->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Button not found")
      | Some(module(Button)) =>
        await Button.execute(interaction)
        Js.Console.log(
          `Successfully served button press "${buttonCustomId}" for ${user->User.getUsername}`,
        )
      }
    }

  | (_, _) => Js.Console.error("Bot.res: Unknown interaction")
  }
}

let onGuildDelete = async guild => {
  open Utils
  open Shared.Decode
  let config = Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )
  let guildId = guild->Guild.getGuildId

  let content = switch await Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds) {
  | data => Some(data)
  | exception JsError(_) => None
  }->Belt.Option.getExn

  let brightIdGuild = content->Js.Dict.get(guildId)

  switch brightIdGuild {
  | Some(_) =>
    switch await Gist.UpdateGist.removeEntry(~content, ~key=guildId, ~config) {
    | _ => Some()
    | exception JsError(_) => None
    }

  | None => Js.log(`No role to delete for guild ${guildId}`)->Some
  }
}

let onGuildMemberAdd = guildMember => {
  open Utils

  let requestTimeout = 60000
  let uuid = guildMember->GuildMember.getGuildMemberId->UUID.v5(envConfig["uuidNamespace"])
  let endpoint = `${brightIdVerificationEndpoint}/${context}/${uuid}?timestamp=seconds`

  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timestamp": requestTimeout,
  }
  endpoint
  ->fetch(params)
  ->then(res => res->Response.json)
  ->then(json => {
    open Shared.Decode
    switch (
      json->Json.decode(Decode_BrightId.ContextId.data),
      json->Json.decode(Decode_BrightId.Error.data),
    ) {
    | (Ok({data}), _) =>
      switch data.unique {
      | true =>
        Gist.makeGistConfig(
          ~id=envConfig["gistId"],
          ~name="guildData.json",
          ~token=envConfig["githubAccessToken"],
        )
        ->Gist.ReadGist.content(~config=_, ~decoder=Decode_Gist.brightIdGuilds)
        ->then(content => {
          let guild = guildMember->GuildMember.getGuild
          let guildId = guild->Guild.getGuildId
          let brightIdGuild = content->Js.Dict.get(guildId)->Belt.Option.getExn
          let roleId = brightIdGuild.roleId->Belt.Option.getExn

          let role =
            guild
            ->Guild.getGuildRoleManager
            ->RoleManager.getCache
            ->Collection.get(roleId)
            ->Js.Nullable.toOption
            ->Belt.Option.getExn

          let guildMemberRoleManager = guildMember->GuildMember.getGuildMemberRoleManager
          guildMemberRoleManager
          ->GuildMemberRoleManager.add(role, ~reason="User is already verified by BrightID", ())
          ->ignore
          resolve()
        })

      | false => Js.log(`User ${guildMember->GuildMember.getDisplayName} is not unique`)->resolve
      }

    | (_, Ok(error)) => Js.log(error.errorMessage)->resolve

    | (Error(err), _) => err->Json.Decode.DecodeError->reject
    }
  })
  ->catch(err => {
    Js.Console.error(err)
    resolve()
  })
  ->ignore
}

let onRoleUpdate = role => {
  open Utils
  open Shared.Decode
  let guildId = role->Role.getGuild->Guild.getGuildId
  let config = Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )
  Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)
  ->then(guilds => {
    let brightIdGuild = guilds->Js.Dict.get(guildId)->Belt.Option.getExn
    let roleId = brightIdGuild.roleId->Belt.Option.getExn
    let isVerifiedRole = role->Role.getRoleId === roleId
    switch isVerifiedRole {
    | true =>
      let roleName = role->Role.getName
      let entry = {
        ...brightIdGuild,
        role: Some(roleName),
      }
      Gist.UpdateGist.updateEntry(~content=guilds, ~entry, ~key=guildId, ~config)->then(_ =>
        resolve()
      )
    | false => resolve()
    }
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

client->Client.on(#guildCreate(guild => guild->onGuildCreate->ignore))

client->Client.on(#interactionCreate(interaction => interaction->onInteraction->ignore))

client->Client.on(#guildDelete(guild => guild->onGuildDelete->ignore))

client->Client.on(#guildMemberAdd(member => member->onGuildMemberAdd))

client->Client.on(#roleUpdate((~oldRole as _, ~newRole) => newRole->onRoleUpdate))

client->Client.login(envConfig["discordApiToken"])->ignore
