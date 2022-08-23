open Discord
open Promise

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context} = module(Constants)

exception ButtonVerifyHandlerError(string)

Env.createEnv()

let config = Env.getConfig()

let config = switch config {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let getRolebyRoleId = (guildRoleManager, roleId) => {
  let guildRole =
    guildRoleManager->RoleManager.getCache->Collection.get(roleId)->Js.Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => ButtonVerifyHandlerError("Could not find a role with the id " ++ roleId)->raise
  }
}

let getGuildDataFromGist = (guilds, guildId, interaction) => {
  let guildData = guilds->Js.Dict.get(guildId)
  switch guildData {
  | None =>
    interaction
    ->Interaction.editReply(
      ~options={"content": "Failed to retreive data for this Discord Guild"},
      (),
    )
    ->ignore
    ButtonVerifyHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let verifyMember = (guildRole, member) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  guildMemberRoleManager->GuildMemberRoleManager.add(guildRole, ())
}

let noMultipleAccounts = member => {
  member
  ->GuildMember.send(
    "You are currently limited to one Discord account with BrightID. If there has been a mistake, message the BrightID team on Discord https://discord.gg/N4ZbNjP",
    (),
  )
  ->ignore
  ButtonVerifyHandlerError(
    "Verification Info can not be retrieved from more than one Discord account.",
  )->reject
}

let handleUnverifiedGuildMember = (errorNum, interaction) => {
  switch errorNum {
  | 2 =>
    interaction
    ->Interaction.followUp(
      ~options={
        "content": "Please scan the above QR code in the BrightID mobile app",
      },
      (),
    )
    ->ignore
    resolve()
  | 3 =>
    interaction
    ->Interaction.followUp(
      ~options={
        "content": "I haven't seen you at a Bright ID Connection Party yet, so your brightid is not verified. You can join a party in any timezone at https://meet.brightid.org",
      },
      (),
    )
    ->ignore
    resolve()
  | 4 =>
    interaction
    ->Interaction.followUp(
      ~options={
        "content": "Whoops! You haven't received a sponsor. There are plenty of apps with free sponsors, such as the [EIDI Faucet](https://idchain.one/begin/). \n\n See all the apps available at https://apps.brightid.org",
      },
      (),
    )
    ->ignore
    resolve()

  | _ =>
    interaction
    ->Interaction.followUp(
      ~options={
        "content": "Something unexpected happened. Please try again later.",
      },
      (),
    )
    ->ignore
    resolve()
  }
}

let execute = interaction => {
  open Utils
  let config = Gist.makeGistConfig(
    ~id=config["gistId"],
    ~name="guildData.json",
    ~token=config["githubAccessToken"],
  )
  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager

  let guildId = guild->Guild.getGuildId
  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    Gist.ReadGist.content(~config, ~decoder=Decode.Gist.brightIdGuilds)->then(guilds => {
      let guildData = guilds->getGuildDataFromGist(guildId, interaction)
      let guildRole = guildData["roleId"]->Belt.Option.getExn->getRolebyRoleId(guildRoleManager, _)
      member
      ->Services_VerificationInfo.getBrightIdVerification
      ->then(
        verificationInfo => {
          switch verificationInfo {
          | JsError(obj) => {
              interaction
              ->Interaction.followUp(
                ~options={
                  "content": "Something unexpected happened. Try again later",
                },
                (),
              )
              ->ignore
              JsError(obj)->reject
            }

          | BrightIdError({errorNum}) => errorNum->handleUnverifiedGuildMember(interaction)
          | VerificationInfo(verificationInfo) =>
            switch verificationInfo.contextIds->Belt.Array.length > 1 {
            | true => member->noMultipleAccounts
            | false =>
              switch verificationInfo.unique {
              | true => {
                  guildRole
                  ->verifyMember(member)
                  ->then(
                    _ => {
                      interaction->Interaction.editReply(
                        ~options={
                          "content": `Hey, I recognize you! I just gave you the \`${guildRole->Role.getName}\` role. You are now BrightID verified in ${guild->Guild.getGuildName} server!`,
                        },
                        (),
                      )
                    },
                  )
                  ->ignore
                  resolve()
                }

              | false => {
                  interaction
                  ->Interaction.editReply(
                    ~options={
                      "content": "Hey, I recognize you, but your account seems to be linked to a sybil attack. You are not properly BrightID verified. If this is a mistake, contact one of the support channels",
                    },
                    (),
                  )
                  ->ignore
                  ButtonVerifyHandlerError(
                    `Member ${member->GuildMember.getDisplayName} is not unique`,
                  )->reject
                }
              }
            }
          }
        },
      )
    })
  })
  ->catch(e => {
    switch e {
    | ButtonVerifyHandlerError(msg) => Js.Console.error(msg)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    resolve()
  })
}

let customId = "verify"
