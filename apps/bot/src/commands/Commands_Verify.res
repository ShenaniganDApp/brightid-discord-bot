open Promise
open Discord
open Shared
open NodeFetch
open Exceptions

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context, contractAddressID, contractAddressETH} = module(Shared.Constants)

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

let sleep: int => Js.Promise.t<unit> = ms =>
  %raw(` new Promise((resolve) => setTimeout(resolve, ms))`)

let abi: Shared.ABI.t = %raw(`import("../../../../packages/shared/src/abi/SP.json", {assert: {type: "json"}}).then((module) => module.default)`)

module Canvas = {
  type t
  @module("canvas") @scope("default")
  external createCanvas: (int, int) => t = "createCanvas"
  @send external toBuffer: t => Node.Buffer.t = "toBuffer"
}

module QRCode = {
  type t
  @module("qrcode") external toCanvas: (Canvas.t, string) => Promise.t<unit> = "toCanvas"
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

let noUnusedSponsorshipsOptions = () =>
  {
    "content": "There are no sponsorships available in the Discord pool. Please try again later.",
    "ephemeral": true,
  }

let embedFields = verifyUrl => {
  open MessageEmbed
  [
    {
      name: "1. Get Verified in the BrightID app",
      value: `Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet "https://www.brightid.org/meet") that are hosted in the BrightID server and require members join a voice/video call.`,
    },
    {
      name: "2. Link to a Sponsored App (like 1hive, gitcoin, etc)",
      value: `You can link to these [sponsored apps](https://apps.brightid.org/ "https://apps.brightid.org/") once you are verified within the app.`,
    },
    {
      name: "3. Type the `/verify` command in an appropriate channel",
      value: `You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH "https://discord.gg/gH6qAUH").`,
    },
    {
      name: `4. Scan the DM"d QR Code`,
      value: `Open the BrightID app and scan the QR code. Mobile users can click [this link](${verifyUrl}).`,
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
  let guildRole =
    guildRoleManager->RoleManager.getCache->Collection.get(roleId)->Js.Nullable.toOption

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

let noWriteToGistMessage = async interaction => {
  let options = {
    "content": "It seems like I can't write to my database at the moment. Please try again or contact the BrightID support.",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
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
  Belt.Option.mapWithDefault(maybeSponsorshipAddress, resolve(Ethers.BigNumber.zero), getBalance)
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
    let options = {
      "content": "I haven't seen you at a Bright ID Connection Party yet, so your brightid is not verified. You can join a party in any timezone at https://meet.brightid.org",
      "ephemeral": true,
    }
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
    let now = Js.Date.now()
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
  | Some(assignedSponsorships) => Belt.Array.reduce(assignedSponsorships, zero, sumAmounts)
  }
}

let getGuildSponsorshipTotals = guilds => {
  open Ethers.BigNumber
  open Shared.BrightId.Gist

  let calculateAssignedAndUnusedTotals = (acc, key) => {
    let (totalAssignedSponsorships, totalUsedSponsorships) = acc
    let guild = guilds->Js.Dict.unsafeGet(key)
    let assignedSponsorships = getServerAssignedSponsorships(guild)
    let usedSponsorships = guild.usedSponsorships->Belt.Option.getWithDefault("0")->fromString
    let totalAssignedSponsorships = add(totalAssignedSponsorships, assignedSponsorships)
    let totalUsedSponsorships = add(totalUsedSponsorships, usedSponsorships)
    (totalAssignedSponsorships, totalUsedSponsorships)
  }

  guilds->Js.Dict.keys->Belt.Array.reduce((zero, zero), calculateAssignedAndUnusedTotals)
}

let execute = interaction => {
  open Utils

  let guild = interaction->Interaction.getGuild
  let guildName = guild->Guild.getGuildName
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
      let guildData = guilds->Js.Dict.get(guildId)
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
                  ->Js.String2.split(",")
                  ->Js.Array2.includes(guild->Guild.getGuildId)
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
                    ->Belt.Float.toString
                    ->Ethers.BigNumber.fromString
                    ->Ethers.BigNumber.sub(unusedGuildSponsorships)

                  let isPremiumActive =
                    unusedPremiumSponsorships->Ethers.BigNumber.gt(Ethers.BigNumber.zero) &&
                      hasPremium(guildData)

                  switch (errorNum, isPremiumActive, inWhitelist) {
                  //Not in beta whitelist
                  | (4, _, false) =>
                    let _ = await noSponsorshipsMessage(interaction)
                    VerifyCommandError("Guild not in beta whitelist")->raise
                  // Premium is active
                  | (4, true, _) =>
                    Js.log2(
                      "Unused Sponsorships in premium pool: ",
                      Ethers.BigNumber.toString(unusedPremiumSponsorships),
                    )
                    let options = await beforeSponsorMessageOptions("before-premium-sponsor", uuid)
                    let _ = await Interaction.editReply(interaction, ~options, ())

                  // Use server sponsor
                  | (4, false, true) =>
                    let assignedSponsorshipsID = await getAssignedSPFromAddress(
                      guildData.sponsorshipAddress,
                      contractAddressID,
                      "https://idchain.one/rpc",
                    )
                    let assignedSponsorshipsEth = await getAssignedSPFromAddress(
                      guildData.sponsorshipAddressEth,
                      contractAddressETH,
                      "https://rpc.ankr.com/eth",
                    )
                    let totalUnusedSponsorships = totalUnusedSponsorships(
                      assignedSponsorshipsID,
                      assignedSponsorshipsEth,
                    )
                    switch totalUnusedSponsorships {
                    | exception NoAvailableSP =>
                      let _ = await noSponsorshipsMessage(interaction)
                      VerifyCommandError("This server has no usable sponsorships")->raise
                    | exception e => raise(e)
                    | _ =>
                      open Ethers.BigNumber
                      let usedSponsorships =
                        guildData.usedSponsorships->Belt.Option.mapWithDefault(zero, fromString)

                      let assignedSponsorships =
                        assignedSponsorshipsID->add(assignedSponsorshipsEth)
                      let availableSponsorships = assignedSponsorships->sub(usedSponsorships)

                      let hasAvailableSponsorships = !isZero(availableSponsorships)
                      switch hasAvailableSponsorships {
                      | false =>
                        //@TODO: Error no available SP
                        let _ = await noSponsorshipsMessage(interaction)
                      | true =>
                        let options = await beforeSponsorMessageOptions("before-sponsor", uuid)
                        let _ = await Interaction.editReply(interaction, ~options, ())
                      }
                    }
                  // No Sponsorship Address and No Premium
                  // | (4, false, true) =>
                  //   let _ = await noSponsorshipsMessage(interaction)
                  //   VerifyCommandError("Does not have a sponsorship address set")->raise
                  //Non sponsorship error
                  | (_, _, _) =>
                    let _ = switch await handleUnverifiedGuildMember(errorNum, interaction, uuid) {
                    | data => Some(data)
                    | exception JsError(obj) =>
                      Js.Console.error(obj)
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
