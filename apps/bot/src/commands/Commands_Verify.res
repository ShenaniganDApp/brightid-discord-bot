open Promise
open Discord
open Shared
open NodeFetch

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context, contractAddressID} = module(Shared.Constants)

exception VerifyHandlerError(string)
exception BrightIdError(BrightId.Error.t)

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

let sleep: int => Js.Promise.t<unit> = ms =>
  %raw(` new Promise((resolve) => setTimeout(resolve, ms))`)

@module external abi: {"default": Shared.ABI.t} = "../../../../packages/shared/src/abi/SP.json"

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

let fetchVerification = async uuid => {
  open Decode.Decode_BrightId
  let endpoint = `${brightIdVerificationEndpoint}/${context}/${uuid}?timestamp=seconds`
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timeout": 60000,
  }
  let res = switch await fetch(endpoint, params) {
  | res => res
  | exception JsError(obj) =>
    switch Js.Exn.message(obj) {
    | Some(msg) =>
      Js.Console.error(msg)
      VerifyHandlerError(msg)->raise
    | None =>
      Js.Console.error(obj)
      VerifyHandlerError("Fetch Verification Error")->raise
    }
  }
  switch await Response.json(res) {
  | json =>
    switch (json->Json.decode(ContextId.data), json->Json.decode(Error.data)) {
    | (Ok({data}), _) => data
    | (_, Ok(error)) => error->BrightIdError->raise
    | (Error(err), _) => err->Json.Decode.DecodeError->raise
    }
  }
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
  | None => VerifyHandlerError("Could not find a role with the id " ++ roleId)->raise
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
let makeBeforeSponsorActionRow = (label, verifyUrl) => {
  let sponsorButton =
    MessageButton.make()
    ->MessageButton.setCustomId("before-sponsor")
    ->MessageButton.setLabel(label)
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

let beforeSponsorMessageOptions = async uuid => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let row = makeBeforeSponsorActionRow("Click this after scanning QR code ", verifyUrl)
  {
    "content": "Please scan the QR code in the BrightID app. \n\n **__You can download the app on Android and iOS__** \n Android: <https://play.google.com/store/apps/details?id=org.brightid> \n\n iOS: <https://apps.apple.com/us/app/brightid/id1428946820> \n\n",
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
let getAssignedSPFromContract = async sponsorshipAddress => {
  let provider = Ethers.Providers.jsonRpcProvider(~url="https://idchain.one/rpc")
  let contract = Ethers.Contract.make(~provider, ~address=contractAddressID, ~abi=abi["default"])

  let formattedContext = Ethers.Utils.formatBytes32String("Discord")
  let contract = BrightId.SPContract.make(contract)

  switch await BrightId.SPContract.contextBalance(
    contract,
    ~address=sponsorshipAddress,
    ~formattedContext,
  ) {
  | spBalance =>
    if spBalance->Ethers.BigNumber.isZero {
      NoAvailableSP->raise
    }
    spBalance
  | exception JsError(obj) =>
    switch Js.Exn.message(obj) {
    | Some(msg) =>
      Js.Console.error(msg)
      NoAvailableSP->raise
    | None =>
      Js.Console.error(obj)
      NoAvailableSP->raise
    }
  }
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

    Gist.ReadGist.content(~config=gistConfig(), ~decoder=Decode_Gist.brightIdGuilds)
    ->then(guilds => {
      let guildId = guild->Guild.getGuildId
      let guildData = guilds->Js.Dict.get(guildId)
      switch guildData {
      | None =>
        let options = {
          "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightId",
        }
        interaction
        ->Interaction.editReply(~options, ())
        ->then(
          _ => VerifyHandlerError(`Guild Id ${guildId} could not be found in the database`)->reject,
        )

      | Some(guildData) => {
          let roleId = guildData.roleId->Belt.Option.getExn //@TODO return a better error if there is no role id
          let sponsorshipAddress = guildData.sponsorshipAddress
          let guildRole = guildRoleManager->getRolebyRoleId(roleId)
          uuid
          ->fetchVerification
          ->then(
            contextId =>
              switch contextId.unique {
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
                interaction->Interaction.editReply(~options, ())->then(_ => resolve())
              },
          )
          ->catch(
            async e => {
              switch e {
              | BrightIdError({errorNum, errorMessage}) =>
                switch (errorNum, sponsorshipAddress) {
                // No Sponsorship Address Set
                | (4, None) =>
                  let _ = await noSponsorshipsMessage(interaction)
                | (4, Some(sponsorshipAddress)) =>
                  let _ = switch await getAssignedSPFromContract(sponsorshipAddress) {
                  | assignedSponsorships =>
                    let availableSponsorships =
                      assignedSponsorships->Ethers.BigNumber.subWithString(
                        guildData.usedSponsorships->Belt.Option.getWithDefault("0"),
                      )
                    let assignedSponsorships = assignedSponsorships->Ethers.BigNumber.toString
                    let entry = guilds->Js.Dict.get(guildId)->Belt.Option.getExn
                    let updateAssignedSponsorships = await Utils.Gist.UpdateGist.updateEntry(
                      ~config=gistConfig(),
                      ~content=guilds,
                      ~key=guildId,
                      ~entry={...entry, assignedSponsorships: Some(assignedSponsorships)},
                    )
                    let hasAvailableSponsorships = !Ethers.BigNumber.isZero(availableSponsorships)
                    switch (updateAssignedSponsorships, hasAvailableSponsorships) {
                    | (Ok(_), false) =>
                      let _ = await noSponsorshipsMessage(interaction)
                    | (Ok(_), true) =>
                      let options = await beforeSponsorMessageOptions(uuid)
                      let _ = await Interaction.editReply(interaction, ~options, ())
                    | (Error(_), _) =>
                      let _ = await noWriteToGistMessage(interaction)
                    }

                  | exception NoAvailableSP =>
                    let _ = await noSponsorshipsMessage(interaction)
                  | exception JsError(obj) =>
                    switch Js.Exn.message(obj) {
                    | Some(msg) => Js.Console.error(msg)
                    | None => Js.Console.error(obj)
                    }
                  }
                | (_, _) => {
                    let _ = switch await handleUnverifiedGuildMember(errorNum, interaction, uuid) {
                    | data => Some(data)
                    | exception JsError(_) =>
                      Js.Console.error(`${member->GuildMember.getDisplayName}: ${errorMessage}`)
                      None
                    }
                  }
                }
              | _ => Js.Console.error("Verify Handler: Unknown error")
              }
            },
          )
        }
      }
    })
    ->catch(e => {
      switch e {
      | VerifyHandlerError(msg) => Js.Console.error(msg)->resolve
      | Json.Decode.DecodeError(msg) => Js.Console.error(msg)->resolve
      | JsError(obj) =>
        switch Js.Exn.message(obj) {
        | Some(msg) => Js.Console.error("Verify Handler: " ++ msg)->resolve
        | None => Js.Console.error2("Verify Handler: Unknown error", obj)->resolve
        }
      | _ => Js.Console.error("Verify Handler: Unknown error")->resolve
      }
    })
  })
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("verify")
  ->SlashCommandBuilder.setDescription(
    "Sends a BrightID QR code for users to connect with their BrightId",
  )
