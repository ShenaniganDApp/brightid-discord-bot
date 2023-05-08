open Promise
open Discord
open Shared
open NodeFetch
open Exceptions

let {brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(Endpoints)
let {context, contractAddressID, contractAddressETH} = module(Shared.Constants)

@val @scope("globalThis")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "fetch"

let abi: Shared.ABI.t = %raw(`import("../../../../packages/shared/src/abi/SP.json", {assert: {type: "json"}}).then((module) => module.default)`)

module Canvas = {
  type t
  @module("canvas") @scope("default")
  external createCanvas: (int, int) => t = "createCanvas"
  @send external toBuffer: t => Node.Buffer.t = "toBuffer"
}

module QRCode = {
  type t
  @module("qrcode") external toCanvas: (Canvas.t, string) => promise<unit> = "toCanvas"
}

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let gistConfig = () =>
  Utils.Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )

let addRoleToMember = (guildRole, member) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  guildMemberRoleManager->GuildMemberRoleManager.add(guildRole, ())
}

let embedFields = verifyUrl => {
  open MessageEmbed
  [
    {
      name: "1. Get Verified in the BrightID app",
      value: `Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet) that are hosted in the BrightID server and require members join a voice/video call.`,
    },
    {
      name: "2. Type the `/verify` command in an appropriate channel",
      value: `You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH).`,
    },
    {
      name: `3. Scan the QR Code`,
      value: `Open the BrightID app and scan the QR code. Mobile users can click [this link](${verifyUrl}).`,
    },
    {
      name: "4. Link to a Sponsored App (like 1hive, gitcoin, etc)",
      value: `The Discord bot will attempt to sponsor any verified BrightID. You can also link to these [sponsored apps](https://apps.brightid.org/) once you are verified within the app.`,
    },
    {
      name: "5. Click the button after you scanned the QR code",
      value: "Once you have scanned the QR code you can return to Discord and click the button to receive the appropriate BrightID role.",
    },
  ]
}

let makeEmbed = fields => {
  open MessageEmbed
  createMessageEmbed()
  ->setColor("#fb8b60")
  ->setTitle("How To Get Verified with Bright ID")
  ->setURL("https://www.brightid.org/")
  ->setAuthor(
    "BrightID Bot",
    "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
    "https://www.brightid.org/",
  )
  ->setDescription("Here is a step-by-step guide to help you get verified with BrightID.")
  ->setThumbnail(
    "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
  )
  ->addFields(fields)
  ->setTimestamp
  ->setFooter(
    "Bot made by the Shenanigan team",
    "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
  )
}

let makeCanvasFromUri = async uri => {
  let canvas = Canvas.createCanvas(700, 250)
  await QRCode.toCanvas(canvas, uri)
  canvas
}

let createMessageAttachmentFromCanvas = async canvas => {
  canvas->Canvas.toBuffer->Message.createMessageAttachment("qrcode.png", ())
}

let getRolebyRoleId = (guildRoleManager, roleId) => {
  let guildRole = guildRoleManager->RoleManager.getCache->Collection.get(roleId)->Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => VerifyCommandError("Could not find a role with the id " ++ roleId)->raise
  }
}

let makeLinkActionRow = verifyUrl => {
  let mobileButton =
    MessageButton.make()
    ->MessageButton.setLabel("Open QRCode in the BrightID app")
    ->MessageButton.setStyle("LINK")
    ->MessageButton.setURL(verifyUrl)
  let roleButton =
    MessageButton.make()
    ->MessageButton.setCustomId("verify")
    ->MessageButton.setLabel("Click here after scanning QR Code in the BrightID app")
    ->MessageButton.setStyle("PRIMARY")

  MessageActionRow.make()->MessageActionRow.addComponents([roleButton, mobileButton])
}
let makeBeforeSponsorActionRow = (customId, verifyUrl) => {
  let sponsorButton =
    MessageButton.make()
    ->MessageButton.setCustomId(customId)
    ->MessageButton.setLabel("Click this after scanning QR code")
    ->MessageButton.setStyle("PRIMARY")

  let mobileButton =
    MessageButton.make()
    ->MessageButton.setLabel("Open QRCode in the BrightID app")
    ->MessageButton.setStyle("LINK")
    ->MessageButton.setURL(verifyUrl)

  MessageActionRow.make()->MessageActionRow.addComponents([sponsorButton, mobileButton])
}

let linkOptions = (attachment, embed, row) => {
  {
    "embeds": [embed],
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}

let makeLinkOptions = async uuid => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let embed = verifyUrl->embedFields->makeEmbed
  let row = makeLinkActionRow(verifyUrl)
  linkOptions(attachment, embed, row)
}
let unknownErrorMessage = async interaction => {
  let options = {
    "content": "An unknown error occurred. Please try again later.",
    "ephemeral": true,
  }
  Interaction.followUp(interaction, ~options, ())
}

let beforeSponsorMessageOptions = async (customId, uuid) => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let row = makeBeforeSponsorActionRow(customId, verifyUrl)
  {
    "content": "Please scan this QR code in the BrightID app to link Discord. \n\n **__You can download the app on Android and iOS__** \n Android: <https://play.google.com/store/apps/details?id=org.brightid> \n\n iOS: <https://apps.apple.com/us/app/brightid/id1428946820> \n\n",
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}

exception NoAvailableSP
let getAssignedSPFromAddress = (maybeSponsorshipAddress, contractAddress, url) => {
  let getBalance = sponsorshipAddress => {
    let provider = Ethers.Providers.jsonRpcProvider(~url)
    let contract = Ethers.Contract.make(~provider, ~address=contractAddress, ~abi)

    let formattedContext = Ethers.Utils.formatBytes32String("Discord")
    let contract = BrightId.SPContract.make(contract)
    BrightId.SPContract.contextBalance(contract, ~address=sponsorshipAddress, ~formattedContext)
  }
  Option.mapWithDefault(maybeSponsorshipAddress, resolve(Ethers.BigNumber.zero), getBalance)
}

let totalUnusedSponsorships = (usedSponsorships, assignedSponsorships, assignedSponsorshipsEth) => {
  open Ethers.BigNumber
  let totalAssignedSponsorships = assignedSponsorshipsEth->add(assignedSponsorships)
  let unusedSponsorships = totalAssignedSponsorships->sub(usedSponsorships)

  unusedSponsorships->lte(zero) ? raise(NoAvailableSP) : unusedSponsorships
}

let noSponsorshipsMessage = async interaction => {
  let options = {
    "content": "Whoops! You haven't received a sponsor. There are plenty of apps with free sponsors, such as the [EIDI Faucet](https://idchain.one/begin/). \n\n See all the apps available at https://apps.brightid.org \n\n ",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
}

let handleUnverifiedGuildMember = async (errorNum, interaction, uuid) => {
  switch errorNum {
  | 2 =>
    let options = await makeLinkOptions(uuid)
    let _ = await Interaction.editReply(interaction, ~options, ())

  | 3 =>
    let options = await makeLinkOptions(uuid)
    let _ = await Interaction.editReply(interaction, ~options, ())

  | _ =>
    let options = {
      "content": "Something unexpected happened. Please try again later.",
      "ephemeral": true,
    }
    let _ = await Interaction.editReply(interaction, ~options, ())
  }
}

let hasPremium = (guildData: BrightId.Gist.brightIdGuild) =>
  switch guildData.premiumExpirationTimestamp {
  | Some(premiumExpirationTimestamp) =>
    let now = Date.now()
    now < premiumExpirationTimestamp
  | None => false
  }

let getAppUnusedSponsorships = async context => {
  switch await Services_AppInfo.getAppInfo(context) {
  | exception Exceptions.BrightIdError(_) => None
  | exception JsError(_) => None
  | data => Some(data.unusedSponsorships)
  }
}
let getServerAssignedSponsorships = guildData => {
  open Shared.BrightId.Gist
  open Ethers.BigNumber

  let sumAmounts = (acc, {amount}) => {
    amount->fromString->add(acc)
  }

  switch guildData.assignedSponsorships {
  | None => zero
  | Some(assignedSponsorships) => Array.reduce(assignedSponsorships, zero, sumAmounts)
  }
}

let getGuildSponsorshipTotals = guilds => {
  open Ethers.BigNumber
  open Shared.BrightId.Gist

  let calculateAssignedAndUnusedTotals = (acc, key) => {
    let (totalAssignedSponsorships, totalUsedSponsorships) = acc
    let guild = guilds->Dict.get(key)->Option.getUnsafe
    let assignedSponsorships = getServerAssignedSponsorships(guild)
    let usedSponsorships = guild.usedSponsorships->Option.getWithDefault("0")->fromString
    let totalAssignedSponsorships = add(totalAssignedSponsorships, assignedSponsorships)
    let totalUsedSponsorships = add(totalUsedSponsorships, usedSponsorships)
    (totalAssignedSponsorships, totalUsedSponsorships)
  }

  guilds->Dict.keysToArray->Array.reduce((zero, zero), calculateAssignedAndUnusedTotals)
}

let execute = interaction => {
  open Utils

  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager
  let memberId = member->GuildMember.getGuildMemberId
  let uuid = memberId->UUID.v5(envConfig["uuidNamespace"])

  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    open Shared.Decode

    Gist.ReadGist.content(
      ~config=gistConfig(),
      ~decoder=Decode_Gist.brightIdGuilds,
    )->then(guilds => {
      let guildId = guild->Guild.getGuildId
      let guildData = guilds->Dict.get(guildId)
      switch guildData {
      | None =>
        let options = {
          "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightId",
        }
        interaction
        ->Interaction.editReply(~options, ())
        ->then(_ => VerifyCommandError(`Guild could not be found in the database`)->reject)

      | Some(guildData) =>
        switch guildData.roleId {
        | None =>
          let options = {
            "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightID. Try reinviting the bot. \n\n **Note: This will create a new role BrightID Role.**",
          }
          interaction
          ->Interaction.editReply(~options, ())
          ->then(_ => VerifyCommandError(`Guild does not have a saved roleId`)->reject)
        | Some(roleId) =>
          let guildRole = guildRoleManager->getRolebyRoleId(roleId)
          Services_VerificationInfo.getBrightIdVerification(member)
          ->then(
            verificationInfo => {
              switch verificationInfo {
              | VerificationInfo({unique}) =>
                switch unique {
                | true =>
                  guildRole
                  ->addRoleToMember(member)
                  ->then(
                    _ => {
                      let options = {
                        "content": `Hey, I recognize you! I just gave you the \`${guildRole->Role.getName}\` role. You are now BrightID verified in ${guild->Guild.getGuildName} server!`,
                        "ephemeral": true,
                      }
                      interaction->Interaction.editReply(~options, ())->then(_ => resolve())
                    },
                  )

                | false =>
                  let options = {
                    "content": `Hey, I recognize you, but your account seems to be linked to a sybil attack. You have multiple Discord accounts on the same BrightID. If this is a mistake, contact one of the support channels. `,
                    "ephemeral": true,
                  }
                  interaction
                  ->Interaction.editReply(~options, ())
                  ->then(
                    _ =>
                      VerifyCommandError(
                        `Commands_Verify: User with contextId: ${uuid} is not unique `,
                      )->reject,
                  )
                }
              }
            },
          )
          ->catch(
            async e =>
              switch e {
              | Exceptions.BrightIdError({errorNum}) =>
                let inWhitelist =
                  envConfig["sponsorshipsWhitelist"]
                  ->String.split(",")
                  ->Array.includes(guild->Guild.getGuildId) ||
                    envConfig["sponsorshipsWhitelist"] == "*"
                switch await getAppUnusedSponsorships(context) {
                | None =>
                  let _ = await noSponsorshipsMessage(interaction)
                  VerifyCommandError("No sponsorships available in Discord pool")->raise
                | Some(appUnusedSponsorships) =>
                  let (
                    totalGuildAssignedSponsorships,
                    totalGuildUsedSponsorships,
                  ) = getGuildSponsorshipTotals(guilds)
                  let unusedGuildSponsorships =
                    totalGuildAssignedSponsorships->Ethers.BigNumber.sub(totalGuildUsedSponsorships)
                  let unusedPremiumSponsorships =
                    appUnusedSponsorships
                    ->Float.toString
                    ->Ethers.BigNumber.fromString
                    ->Ethers.BigNumber.sub(unusedGuildSponsorships)
                  let premiumSponsorshipsUsed =
                    guildData.premiumSponsorshipsUsed
                    ->Option.getWithDefault("0")
                    ->Ethers.BigNumber.fromString

                  let shouldUsePremiumSponsorships = {
                    open Ethers.BigNumber

                    (unusedPremiumSponsorships->gt(zero) &&
                      premiumSponsorshipsUsed->ltWithString("10")) ||
                    unusedPremiumSponsorships->gt(zero) && hasPremium(guildData) ||
                    inWhitelist
                  }

                  switch (errorNum, shouldUsePremiumSponsorships) {
                  // Premium is active
                  | (4, true) =>
                    Console.log2(
                      "Unused Sponsorships in premium pool: ",
                      Ethers.BigNumber.toString(unusedPremiumSponsorships),
                    )
                    let options = await beforeSponsorMessageOptions("before-premium-sponsor", uuid)
                    let _ = await Interaction.editReply(interaction, ~options, ())

                  // Use server sponsor
                  | (4, false) =>
                    // THis will probably have to be updated optimistically in order to avoid double spending
                    open Ethers.BigNumber
                    switch unusedGuildSponsorships->gt(zero) {
                    | false =>
                      let _ = await noSponsorshipsMessage(interaction)
                      VerifyCommandError("This server has no usable sponsorships")->raise
                    | true =>
                      let options = await beforeSponsorMessageOptions("before-sponsor", uuid)
                      let _ = await Interaction.editReply(interaction, ~options, ())
                    }
                  | (_, _) =>
                    let _ = switch await handleUnverifiedGuildMember(errorNum, interaction, uuid) {
                    | data => Some(data)
                    | exception JsError(obj) =>
                      Console.error(obj)
                      VerifyCommandError("Unknown JS Error")->raise
                    }
                  }
                }
              | _ => e->raise
              },
          )
        }
      }
    })
  })
  ->catch(reject)
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("verify")
  ->SlashCommandBuilder.setDescription(
    "Sends a BrightID QR code for users to connect with their BrightId",
  )
