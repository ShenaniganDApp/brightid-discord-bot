open Discord
open Promise
open NodeFetch
open Shared

let {brightIdVerificationEndpoint} = module(Endpoints)
let {context} = module(Constants)

exception RequestHandlerError(string)
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
  let guildId = guild->Guild.getGuildId
  let guildName = guild->Guild.getGuildName

  let createRole = await RoleManager.create(
    roleManager,
    {
      name: "Verified",
      color: "ORANGE",
      reason: "Create a role to mark verified users with BrightID",
    },
  )

  switch createRole {
  | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
  | role =>
    switch await updateGistOnGuildCreate(guild, role->Role.getRoleId) {
    | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
    | _ => Js.log(`${guildName} : ${guildId}: Successfully added to the database`)
    }
  }
}

let onInteraction = async (interaction: Interaction.t) => {
  let guildId = interaction->Interaction.getGuild->Guild.getGuildId
  let guildName = interaction->Interaction.getGuild->Guild.getGuildName
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
        switch await Command.execute(interaction) {
        | exception e =>
          switch e {
          | Exceptions.BrightIdError({errorMessage}) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, errorMessage)
          | Exceptions.VerifyCommandError(msg) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.InviteCommandError(msg) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, msg)
          | JsError(obj) => Js.Console.error2(`${guildName} : ${guildId}: `, obj)
          | _ => Js.Console.error2(`${guildName} : ${guildId}: `, e)
          }
        | _ =>
          Js.Console.log(
            `${guildName} : ${guildId}: Successfully served the command ${commandName} for ${user->User.getUsername}`,
          )
        }
      }
    }

  | (false, true) => {
      let buttonCustomId = interaction->Interaction.getCustomId

      let button = buttons->Collection.get(buttonCustomId)
      switch button->Js.Nullable.toOption {
      | None => Js.Console.error("Bot.res: Button not found")
      | Some(module(Button)) =>
        switch await Button.execute(interaction) {
        | exception e =>
          switch e {
          | Exceptions.BrightIdError({errorMessage}) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, errorMessage)
          | Exceptions.PremiumSponsorButtonError(msg) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.SponsorButtonError(msg) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.ButtonVerifyHandlerError(msg) =>
            Js.Console.error2(`${guildName} : ${guildId}: `, msg)
          | JsError(obj) => Js.Console.error2(`${guildName} : ${guildId}: `, obj)
          | _ => Js.Console.error2(`${guildName} : ${guildId}: `, e)
          }
        | _ =>
          Js.Console.log(
            `${guildName} : ${guildId}: Successfully served button press "${buttonCustomId}" for ${user->User.getUsername}`,
          )
        }
      }
    }

  | (_, _) => Js.Console.error("Bot.res: Unknown interaction")
  }
}

let onGuildDelete = async guild => {
  open Utils
  open Shared.Decode

  let guildId = Guild.getGuildId(guild)
  let guildName = Guild.getGuildName(guild)

  let config = Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )

  switch await Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds) {
  | exception JsError(e) => Js.Console.error2(`${guildName} : ${guildId}: `, e)
  | guilds =>
    switch guilds->Js.Dict.get(guildId) {
    | Some(_) =>
      switch await Gist.UpdateGist.removeEntry(~content=guilds, ~key=guildId, ~config) {
      | _ => Js.log(`${guildName} : ${guildId}: Successfully removed guild data`)
      | exception JsError(e) => Js.Console.error2(`${guildName} : ${guildId}: `, e)
      }

    | None => Js.Console.error(`${guildName} : ${guildId}: Could not find guild data to delete`)
    }
  }
}

let onGuildMemberAdd = async guildMember => {
  open Utils
  open Services_VerificationInfo
  let config = Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )
  let guildName = guildMember->GuildMember.getGuild->Guild.getGuildName
  let guildId = guildMember->GuildMember.getGuild->Guild.getGuildId
  let _ = switch await getBrightIdVerification(guildMember) {
  | VerificationInfo({unique}) =>
    switch unique {
    | true =>
      switch await Gist.ReadGist.content(~config, ~decoder=Decode.Decode_Gist.brightIdGuilds) {
      | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
      | guilds =>
        let guild = guildMember->GuildMember.getGuild
        let guildId = guild->Guild.getGuildId
        let brightIdGuild = guilds->Js.Dict.get(guildId)
        switch brightIdGuild {
        | None => Js.Console.error2(`${guildName} : ${guildId}: `, `Guild does not exist in Gist`)
        | Some({roleId: None}) =>
          Js.Console.error2(`${guildName} : ${guildId}: `, `Guild does not have a saved roleId`)
        | Some({roleId: Some(roleId)}) =>
          let role =
            guild
            ->Guild.getGuildRoleManager
            ->RoleManager.getCache
            ->Collection.get(roleId)
            ->Js.Nullable.toOption
            ->Belt.Option.getExn

          let guildMemberRoleManager = guildMember->GuildMember.getGuildMemberRoleManager
          let _ = switch await GuildMemberRoleManager.add(
            guildMemberRoleManager,
            role,
            ~reason="User is already verified by BrightID",
            (),
          ) {
          | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
          | _ =>
            let uuid =
              guildMember->GuildMember.getGuildMemberId->UUID.v5(envConfig["uuidNamespace"])
            Js.log(`${guildName} : ${guildId} verified the user with contextId: ${uuid}`)
          }
        }
      }

    | false =>
      Js.Console.error2(
        `${guildName} : ${guildId}: `,
        `User ${guildMember->GuildMember.getDisplayName} is not unique`,
      )
    }
  | exception e =>
    switch e {
    | Exceptions.BrightIdError({errorMessage}) =>
      Js.Console.error2(`${guildName} : ${guildId}: `, errorMessage)
    | JsError(obj) => Js.Console.error2(`${guildName} : ${guildId}: `, obj)
    | _ => Js.Console.error2(`${guildName} : ${guildId}: `, e)
    }
  }
}

let onRoleUpdate = async role => {
  open Utils
  let guildId = role->Role.getGuild->Guild.getGuildId
  let guildName = role->Role.getGuild->Guild.getGuildName
  let config = Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )
  switch await Gist.ReadGist.content(~config, ~decoder=Decode.Decode_Gist.brightIdGuilds) {
  | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
  | content =>
    let brightIdGuild = content->Js.Dict.get(guildId)
    switch brightIdGuild {
    | None => Js.Console.error2(`${guildName} : ${guildId}: `, `Guild does not exist in Gist`)
    | Some(brightIdGuild) =>
      switch brightIdGuild.roleId {
      | None =>
        Js.Console.error2(`${guildName} : ${guildId}: `, `Guild does not have a saved roleId`)
      | Some(roleId) =>
        let isVerifiedRole = role->Role.getRoleId === roleId
        switch isVerifiedRole {
        | true =>
          let roleName = role->Role.getName
          let entry = {
            ...brightIdGuild,
            role: Some(roleName),
          }
          switch await Gist.UpdateGist.updateEntry(~content, ~entry, ~key=guildId, ~config) {
          | exception e => Js.Console.error2(`${guildName} : ${guildId}: `, e)
          | _ => Js.log(`${guildName} : ${guildId} updated the role name to ${roleName}`)
          }
        | false => ()
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

client->Client.on(#guildCreate(guild => guild->onGuildCreate->ignore))

client->Client.on(#interactionCreate(interaction => interaction->onInteraction->ignore))

client->Client.on(#guildDelete(guild => guild->onGuildDelete->ignore))

client->Client.on(#guildMemberAdd(member => member->onGuildMemberAdd->ignore))

client->Client.on(#roleUpdate((~oldRole as _, ~newRole) => newRole->onRoleUpdate->ignore))

client->Client.login(envConfig["discordApiToken"])->ignore
