open Discord
open NodeFetch
open Shared

let {brightIdVerificationEndpoint} = module(Endpoints)
let {context} = module(Constants)

module type Command = {
  let data: SlashCommandBuilder.t
  let execute: Interaction.t => promise<unit>
}
module type Button = {
  let customId: string
  let execute: Interaction.t => promise<unit>
}

@val @scope("globalThis")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "fetch"

Env.createEnv()

let envConfig = Env.getConfig()

@raises([Env.Error])
let envConfig = switch envConfig {
| Ok(envConfig) => envConfig
| Error(err) => err->Env.EnvError->raise
}

@raises([Env.Error])
let gistConfig = () => {
  let id = envConfig["gistId"]
  let name = "guildData.json"
  let token = envConfig["githubAccessToken"]
  Utils.Gist.makeGistConfig(~id, ~name, ~token)
}

let options: Client.clientOptions = {
  intents: ["GUILDS", "GUILD_MESSAGES", "GUILD_MEMBERS"],
  partials: ["GUILD_MEMBER"],
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

let _ =
  buttons
  ->Collection.set(Buttons_Verify.customId, module(Buttons_Verify))
  ->Collection.set(Buttons_Sponsor.customId, module(Buttons_Sponsor))
  ->Collection.set(Buttons_PremiumSponsor.customId, module(Buttons_PremiumSponsor))

let updateGistOnGuildCreate = async (guild, roleId, content) => {
  open Utils

  let guildId = guild->Guild.getGuildId

  let entry = {
    open Shared.BrightId.Gist
    {
      name: guild->Guild.getGuildName->Some,
      role: Some("Verified"),
      roleId: Some(roleId),
      inviteLink: None,
      sponsorshipAddress: None,
      sponsorshipAddressEth: None,
      usedSponsorships: None,
      assignedSponsorships: None,
      premiumSponsorshipsUsed: None,
      premiumExpirationTimestamp: None,
    }
  }

  await Gist.UpdateGist.addEntry(~content, ~config=gistConfig(), ~key=guildId, ~entry)
}

let rec fetchContextIds = async (~retry=5, ()) => {
  open Decode
  let requestTimeout = 60000
  let endpoint = `${brightIdVerificationEndpoint}/${context}`
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timestamp": requestTimeout,
  }
  let res = await fetch(endpoint, params)
  let json = await Response.json(res)
  switch (
    json->Json.decode(Decode_BrightId.Verifications.data),
    json->Json.decode(Decode_BrightId.Error.data),
  ) {
  | (Ok({data}), _) => Set.fromArray(data.contextIds)
  | (_, Ok(error)) =>
    let retry = retry - 1
    switch retry {
    | 0 => error->Exceptions.BrightIdError->raise
    | _ => await fetchContextIds(~retry, ())
    }
  | (Error(error), _) =>
    let retry = retry - 1
    switch retry {
    | 0 => error->Json.Decode.DecodeError->raise
    | _ => await fetchContextIds(~retry, ())
    }
  }
}

let assignRoleOnCreate = async (guild, role) => {
  let maybeMembers = switch await guild->Guild.getGuildMemberManager->GuildMemberManager.fetchAll {
  | exception _ => None
  | members => Some(members)
  }
  let contextIds = await fetchContextIds()

  let filterVerifiedMembers = (guildMember, contextIds) =>
    guildMember
    ->GuildMember.getGuildMemberId
    ->UUID.v5(envConfig["uuidNamespace"])
    ->Set.has(contextIds, _)

  let assignRoleToGuildMember = (guildMember, role) => {
    guildMember->GuildMember.getGuildMemberRoleManager->GuildMemberRoleManager.add(role, ())
  }

  let makeAddRolePromises = members => {
    Collection.filter(members, filterVerifiedMembers(_, contextIds))
    ->Collection.mapValues(assignRoleToGuildMember(_, role))
    ->Collection.values
  }

  let addRolePromises = Option.map(maybeMembers, makeAddRolePromises)

  switch addRolePromises {
  | None => 0
  | Some(promises) =>
    switch await Promise.all(promises) {
    | exception e => raise(e)
    | results => Array.length(results)
    }
  }
}

let onGuildCreate = async guild => {
  open Utils
  open Shared.Decode
  let roleManager = guild->Guild.getGuildRoleManager
  let guildId = guild->Guild.getGuildId
  let guildName = guild->Guild.getGuildName

  let id = envConfig["gistId"]
  let name = "guildData.json"
  let token = envConfig["githubAccessToken"]
  let config = Gist.makeGistConfig(~id, ~name, ~token)

  let role = await RoleManager.create(
    roleManager,
    {
      name: "Verified",
      color: "ORANGE",
      reason: "Create a role to mark verified users with BrightID",
    },
  )
  switch role {
  | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
  | role =>
    let content = await Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)

    switch await updateGistOnGuildCreate(guild, role->Role.getRoleId, content) {
    | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
    | _ =>
      Console.log(`${guildName} : ${guildId}: Successfully added to the database`)

      switch await assignRoleOnCreate(guild, role) {
      | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
      | verifiedMembersCount =>
        Console.log(
          `${guildName} : ${guildId}: Successfully assigned role to ${Int.toString(
              verifiedMembersCount,
            )} current members`,
        )
      }
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
      switch command->Nullable.toOption {
      | None => Console.error("Bot.res: Command not found")
      | Some(module(Command)) =>
        switch await Command.execute(interaction) {
        | exception e =>
          switch e {
          | Exceptions.BrightIdError({errorMessage}) =>
            Console.error2(`${guildName} : ${guildId}: `, errorMessage)
          | Exceptions.VerifyCommandError(msg) => Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.InviteCommandError(msg) => Console.error2(`${guildName} : ${guildId}: `, msg)
          | JsError(obj) => Console.error2(`${guildName} : ${guildId}: `, obj)
          | _ => Console.error2(`${guildName} : ${guildId}: `, e)
          }
        | _ =>
          Console.log(
            `${guildName} : ${guildId}: Successfully served the command ${commandName} for ${user->User.getUsername}`,
          )
        }
      }
    }

  | (false, true) => {
      let buttonCustomId = interaction->Interaction.getCustomId

      let button = buttons->Collection.get(buttonCustomId)
      switch button->Nullable.toOption {
      | None => Console.error("Bot.res: Button not found")
      | Some(module(Button)) =>
        switch await Button.execute(interaction) {
        | exception e =>
          switch e {
          | Exceptions.BrightIdError({errorMessage}) =>
            Console.error2(`${guildName} : ${guildId}: `, errorMessage)
          | Exceptions.PremiumSponsorButtonError(msg) =>
            Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.SponsorButtonError(msg) => Console.error2(`${guildName} : ${guildId}: `, msg)
          | Exceptions.ButtonVerifyHandlerError(msg) =>
            Console.error2(`${guildName} : ${guildId}: `, msg)
          | JsError(obj) => Console.error2(`${guildName} : ${guildId}: `, obj)
          | _ => Console.error2(`${guildName} : ${guildId}: `, e)
          }
        | _ =>
          Console.log(
            `${guildName} : ${guildId}: Successfully served button press "${buttonCustomId}" for ${user->User.getUsername}`,
          )
        }
      }
    }

  | (_, _) => Console.error("Bot.res: Unknown interaction")
  }
}

let onGuildDelete = async guild => {
  open Utils
  open Shared.Decode

  let guildId = Guild.getGuildId(guild)
  let guildName = Guild.getGuildName(guild)

  switch await Gist.ReadGist.content(~config=gistConfig(), ~decoder=Decode_Gist.brightIdGuilds) {
  | exception JsError(e) => Console.error2(`${guildName} : ${guildId}: `, e)
  | guilds =>
    switch guilds->Dict.get(guildId) {
    | Some(_) =>
      switch await Gist.UpdateGist.removeEntry(
        ~content=guilds,
        ~key=guildId,
        ~config=gistConfig(),
      ) {
      | _ => Console.log(`${guildName} : ${guildId}: Successfully removed guild data`)
      | exception JsError(e) => Console.error2(`${guildName} : ${guildId}: `, e)
      }

    | None => Console.error(`${guildName} : ${guildId}: Could not find guild data to delete`)
    }
  }
}

let onGuildMemberAdd = async guildMember => {
  open Utils
  open Services_VerificationInfo

  let guildName = guildMember->GuildMember.getGuild->Guild.getGuildName
  let guildId = guildMember->GuildMember.getGuild->Guild.getGuildId
  let _ = switch await getBrightIdVerification(guildMember) {
  | VerificationInfo({unique}) =>
    switch unique {
    | true =>
      switch await Gist.ReadGist.content(
        ~config=gistConfig(),
        ~decoder=Decode.Decode_Gist.brightIdGuilds,
      ) {
      | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
      | guilds =>
        let guild = guildMember->GuildMember.getGuild
        let guildId = guild->Guild.getGuildId
        let brightIdGuild = guilds->Dict.get(guildId)
        switch brightIdGuild {
        | None => Console.error2(`${guildName} : ${guildId}: `, `Guild does not exist in Gist`)
        | Some({roleId: None}) =>
          Console.error2(`${guildName} : ${guildId}: `, `Guild does not have a saved roleId`)
        | Some({roleId: Some(roleId)}) =>
          let role =
            guild
            ->Guild.getGuildRoleManager
            ->RoleManager.getCache
            ->Collection.get(roleId)
            ->Nullable.toOption
          switch role {
          | None => Console.error2(`${guildName} : ${guildId}: `, `Role does not exist`)
          | Some(role) =>
            let guildMemberRoleManager = guildMember->GuildMember.getGuildMemberRoleManager
            let _ = switch await GuildMemberRoleManager.add(
              guildMemberRoleManager,
              role,
              ~reason="User is already verified by BrightID",
              (),
            ) {
            | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
            | _ =>
              let uuid =
                guildMember->GuildMember.getGuildMemberId->UUID.v5(envConfig["uuidNamespace"])
              Console.log(`${guildName} : ${guildId} verified the user with contextId: ${uuid}`)
            }
          }
        }
      }
    | false =>
      Console.error2(
        `${guildName} : ${guildId}: `,
        `User ${guildMember->GuildMember.getDisplayName} is not unique`,
      )
    }
  | exception e =>
    switch e {
    | Exceptions.BrightIdError({errorMessage}) =>
      Console.error2(`${guildName} : ${guildId}: `, errorMessage)
    | JsError(obj) => Console.error2(`${guildName} : ${guildId}: `, obj)
    | _ => Console.error2(`${guildName} : ${guildId}: `, e)
    }
  }
}

let onRoleUpdate = async role => {
  open Utils
  let guildId = role->Role.getGuild->Guild.getGuildId
  let guildName = role->Role.getGuild->Guild.getGuildName

  switch await Gist.ReadGist.content(
    ~config=gistConfig(),
    ~decoder=Decode.Decode_Gist.brightIdGuilds,
  ) {
  | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
  | content =>
    let brightIdGuild = content->Dict.get(guildId)
    switch brightIdGuild {
    | None => Console.error2(`${guildName} : ${guildId}: `, `Guild does not exist in Gist`)
    | Some(brightIdGuild) =>
      switch brightIdGuild.roleId {
      | None => Console.error2(`${guildName} : ${guildId}: `, `Guild does not have a saved roleId`)
      | Some(roleId) =>
        let isVerifiedRole = role->Role.getRoleId === roleId
        switch isVerifiedRole {
        | true =>
          let roleName = role->Role.getName
          let entry = {
            ...brightIdGuild,
            role: Some(roleName),
          }
          switch await Gist.UpdateGist.updateEntry(
            ~content,
            ~entry,
            ~key=guildId,
            ~config=gistConfig(),
          ) {
          | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
          | _ => Console.log(`${guildName} : ${guildId} updated the role name to ${roleName}`)
          }
        | false => ()
        }
      }
    }
  }
}

let onGuildMemberUpdate = async (_, newMember) => {
  open Utils
  open Services_VerificationInfo
  let guild = newMember->GuildMember.getGuild
  let guildName = guild->Guild.getGuildName
  let guildId = guild->Guild.getGuildId

  let _ = switch await Gist.ReadGist.content(
    ~config=gistConfig(),
    ~decoder=Decode.Decode_Gist.brightIdGuilds,
  ) {
  | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
  | guilds =>
    switch guilds->Dict.get(guildId) {
    | None => ()
    | Some({roleId: None}) => ()
    | Some({roleId: Some(roleId)}) =>
      let _ = switch await guild
      ->Guild.getGuildMemberManager
      ->GuildMemberManager.fetchOne(newMember->GuildMember.getGuildMemberId) {
      | exception e => Console.error2(`${guildName} : ${guildId}: `, e)
      | member =>
        let _ = switch await getBrightIdVerification(member) {
        | VerificationInfo({unique}) =>
          let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
          let roles = guildMemberRoleManager->GuildMemberRoleManager.getCache
          let role =
            guild
            ->Guild.getGuildRoleManager
            ->RoleManager.getCache
            ->Collection.get(roleId)
            ->Nullable.toOption
          switch (role, roles->Collection.has(roleId), unique) {
          | (None, _, _) => ()
          | (Some(role), true, false) =>
            let _ = switch await GuildMemberRoleManager.removeRole(
              guildMemberRoleManager,
              role,
              ~reason="User is not verified by BrightID",
              (),
            ) {
            | exception e =>
              switch e {
              | Exn.Error(obj) =>
                switch Exn.message(obj) {
                | Some(m) => Console.error2(`${guildName} : ${guildId}: `, m)
                | None => ()
                }
              | _ => ()
              }
            | _ => ()
            }
          | (Some(role), false, true) =>
            let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
            let _ = switch await GuildMemberRoleManager.add(
              guildMemberRoleManager,
              role,
              ~reason="User is verified by BrightID",
              (),
            ) {
            | exception e =>
              switch e {
              | Exn.Error(obj) =>
                switch Exn.message(obj) {
                | Some(m) => Console.error2(`${guildName} : ${guildId}: `, m)
                | None => ()
                }
              | _ => ()
              }
            | _ => ()
            }

          | (_, _, _) => ()
          }
        | exception e =>
          switch e {
          | Exceptions.BrightIdError(_) =>
            let role =
              guild
              ->Guild.getGuildRoleManager
              ->RoleManager.getCache
              ->Collection.get(roleId)
              ->Nullable.toOption
            let guildMemberRoleManager = newMember->GuildMember.getGuildMemberRoleManager
            switch role {
            | None => ()
            | Some(role) =>
              let _ = switch await GuildMemberRoleManager.removeRole(
                guildMemberRoleManager,
                role,
                ~reason="User is not verified by BrightID",
                (),
              ) {
              | exception e =>
                switch e {
                | Exn.Error(obj) =>
                  switch Exn.message(obj) {
                  | Some(m) => Console.error2(`${guildName} : ${guildId}: `, m)
                  | None => ()
                  }
                | _ => ()
                }
              | _ => ()
              }
            }
          | Exn.Error(obj) =>
            switch Exn.message(obj) {
            | Some(m) => Console.error2(`${guildName} : ${guildId}: `, m)
            | None => ()
            }
          | _ => Console.error2(`${guildName} : ${guildId}: `, e)
          }
        }
      }
    }
  }
}

client->Client.on(
  #ready(
    () => {
      Console.log("Logged In")
    },
  ),
)

client->Client.on(#guildCreate(guild => guild->onGuildCreate->ignore))

client->Client.on(#interactionCreate(interaction => interaction->onInteraction->ignore))

client->Client.on(#guildDelete(guild => guild->onGuildDelete->ignore))

client->Client.on(#guildMemberAdd(member => member->onGuildMemberAdd->ignore))

client->Client.on(#roleUpdate((~oldRole as _, ~newRole) => newRole->onRoleUpdate->ignore))

client->Client.on(
  #guildMemberUpdate((~oldMember, ~newMember) => onGuildMemberUpdate(oldMember, newMember)->ignore),
)

client->Client.login(envConfig["discordApiToken"])->ignore
