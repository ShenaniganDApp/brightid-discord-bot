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
  let res = await fetch(endpoint, params)
  let json = await Response.json(res)

  switch (json->Json.decode(ContextId.data), json->Json.decode(Error.data)) {
  | (Ok({data}), _) => data
  | (_, Ok(error)) => error->BrightIdError->raise
  | (Error(err), _) => err->Json.Decode.DecodeError->raise
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

let makeVerifyActionRow = verifyUrl => {
  let roleButton =
    MessageButton.make()
    ->MessageButton.setLabel("Open QRCode in the BrightID app")
    ->MessageButton.setStyle("LINK")
    ->MessageButton.setURL(verifyUrl)
  let mobileButton =
    MessageButton.make()
    ->MessageButton.setCustomId("verify")
    ->MessageButton.setLabel("Click here after scanning QR Code in the BrightID app")
    ->MessageButton.setStyle("PRIMARY")

  MessageActionRow.make()->MessageActionRow.addComponents([mobileButton, roleButton])
}
let makeSponsorActionRow = (customId, label) => {
  let checkButton =
    MessageButton.make()
    ->MessageButton.setCustomId(customId)
    ->MessageButton.setLabel(label)
    ->MessageButton.setStyle("PRIMARY")

  MessageActionRow.make()->MessageActionRow.addComponents([checkButton])
}

let notLinkedOptions = (attachment, embed, row) => {
  {
    "embeds": [embed],
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}

let makeNotLinkedOptions = async (uri, verifyUrl) => {
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let embed = verifyUrl->embedFields->makeEmbed
  let row = makeVerifyActionRow(verifyUrl)
  notLinkedOptions(attachment, embed, row)
}
let unknownErrorMessage = async interaction => {
  let options = {
    "content": "An unknown error occurred. Please try again later.",
    "ephemeral": true,
  }
  Interaction.followUp(interaction, ~options, ())
}
type sponsorhip = Sponsorship(BrightId.Sponsorships.t)
let checkSponsor = async uuid => {
  open Shared.Decode.Decode_BrightId
  let endpoint = `https://app.brightid.org/node/v6/sponsorships/${uuid}`
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timeout": 60000,
  }
  let res = await fetch(endpoint, params)
  let json = await Response.json(res)

  switch (json->Json.decode(Sponsorships.data), json->Json.decode(Error.data)) {
  | (Ok({data}), _) => Sponsorship(data)
  | (_, Ok(error)) => error->BrightIdError->raise
  | (Error(err), _) => err->Json.Decode.DecodeError->raise
  }
}

let sleep: int => Js.Promise.t<unit> = ms =>
  %raw(` new Promise((resolve) => setTimeout(resolve, ms))`)

exception ErrorCheckingSponsorshipStatus
type sponsor =
  | SponsorSuccess(BrightId.Sponsorships.sponsor)
  | BrightIdError(BrightId.Error.t)
  | JsError(Js.Exn.t)
type handleSponsor = SPUsed | SPNotUsed | ErrorCheckingSponsorshipStatus
let rec handleSponsor = async (interaction, uuid, ~maybeHash=None, ~attempts=10, ()) => {
  open Shared.BrightId
  open Shared.Decode
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let secondsBetweenAttempts = 30

  switch attempts {
  | 0 => SPNotUsed
  | _ =>
    let json = await sponsor(~key=envConfig["sponsorshipKey"], ~context="Discord", ~contextId=uuid)

    switch (
      json->Json.decode(Decode_BrightId.Sponsorships.sponsor),
      json->Json.decode(Decode_BrightId.Error.data),
    ) {
    | (Ok({hash}), _) =>
      let options = {
        "content": "You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID.",
        "files": [attachment],
        "ephemeral": true,
      }
      let _ = await Interaction.editReply(interaction, ~options, ())
      await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ())

    | (_, Ok({errorNum})) =>
      switch errorNum {
      //No Unused Sponsorships
      | 38 =>
        let options = {
          "content": "There are no sponsorhips available in the premium pool at this moment. Please try again later.",
          "ephemeral": true,
        }
        let _ = await interaction->Interaction.editReply(~options, ())
        SPNotUsed
      //Sponsorship already assigned
      | 39 =>
        switch maybeHash {
        | Some(_) =>
          switch await checkSponsor(uuid) {
          | exception BrightIdError(_) =>
            let _ = await sleep(secondsBetweenAttempts * 1000)
            let attempts = attempts - 1
            await handleSponsor(interaction, uuid, ~maybeHash, ~attempts, ())
          | exception JsError(err) =>
            Js.log2("Sponsorship already assigned: \n", err)
            switch await unknownErrorMessage(interaction) {
            | _ => ErrorCheckingSponsorshipStatus->raise
            }
          | Sponsorship(_) => {
              let row = makeSponsorActionRow("verify", "Assign BrightID Verified Role")
              let options = {
                "content": "You have succesfully been sponsored \n\n If you are verified in BrightID you are all done. Click the button below",
                "files": [attachment],
                "ephemeral": true,
                "components": [row],
              }
              let _ = await Interaction.editReply(interaction, ~options, ())
              SPUsed
            }
          }

        | None =>
          let options = {
            "content": "You have already been sponsored by another BrightID App \n\n You should never see tis message. Please contact BrightID support if you do.",
            "files": [attachment],
            "ephemeral": true,
          }
          let _ = await Interaction.editReply(interaction, ~options, ())
          SPNotUsed
        }

      //App authorized before
      | 45 =>
        switch maybeHash {
        | Some(_) =>
          switch await checkSponsor(uuid) {
          | exception BrightIdError(_) =>
            let _ = await sleep(secondsBetweenAttempts * 1000)
            let attempts = attempts - 1
            await handleSponsor(interaction, uuid, ~maybeHash, ~attempts, ())
          | exception JsError(err) =>
            Js.log2("App Authorized Before: \n", err)
            switch await unknownErrorMessage(interaction) {
            | _ => ErrorCheckingSponsorshipStatus->raise
            }
          | Sponsorship(_) => {
              let row = makeSponsorActionRow("verify", "Assign BrightID Verified Role")
              let options = {
                "content": "You have succesfully been sponsored \n\n If you are verified in BrightID you are all done. Click the button below",
                "files": [attachment],
                "ephemeral": true,
                "components": [row],
              }
              let _ = await Interaction.editReply(interaction, ~options, ())
              SPUsed
            }
          }

        | None =>
          let options = {
            "content": "You have already been sponsored by a Discord Server \n\n You should never see tis message. Please contact BrightID support if you do.",
            "files": [attachment],
            "ephemeral": true,
          }
          let _ = await Interaction.editReply(interaction, ~options, ())
          SPNotUsed
        }

      // // Spend Request Submitted
      // | 46 =>
      //   let row = makeSponsorActionRow("spend-success", "Check Sponsor Status")
      //   let options = {
      //     "content": "You sponsor request has been approved! \n\n A spend request has now been made to the BrightId node. Please continue waiting \n\n While you wait, you can scan this QR code in the BrightID mobile app to link Discord to BrightID.",
      //     "files": [attachment],
      //     "ephemeral": true,
      //     "components": [row],
      //   }
      //   let _ = await interaction->Interaction.editReply(~options, ())
      // Sponsored Request Recently
      | 47 =>
        switch maybeHash {
        | Some(_) =>
          switch await checkSponsor(uuid) {
          | exception BrightIdError(_) =>
            let _ = await sleep(secondsBetweenAttempts * 1000)
            let attempts = attempts - 1
            await handleSponsor(interaction, uuid, ~maybeHash, ~attempts, ())
          | exception JsError(err) =>
            Js.log2("Sponsored Request Recently: \n", err)
            switch await unknownErrorMessage(interaction) {
            | _ => ErrorCheckingSponsorshipStatus->raise
            }
          | Sponsorship(_) => {
              let row = makeSponsorActionRow("verify", "Assign BrightID Verified Role")
              let options = {
                "content": "You have succesfully been sponsored \n\n If you are verified in BrightID you are all done. Click the button below",
                "files": [attachment],
                "ephemeral": true,
                "components": [row],
              }
              let _ = await Interaction.editReply(interaction, ~options, ())
              SPUsed
            }
          }
        | None =>
          let options = {
            "content": "We are still processing your sponsor wait patiently!",
            "files": [attachment],
            "ephemeral": true,
          }
          let _ = interaction->Interaction.followUp(~options, ())
          let _ = await sleep(secondsBetweenAttempts * 1000)
          let attempts = attempts - 1
          await handleSponsor(interaction, uuid, ~maybeHash, ~attempts, ())
        }
      | _ =>
        let _ = await unknownErrorMessage(interaction)
        ErrorCheckingSponsorshipStatus->raise
      }

    | (Error(_), _) =>
      let _ = unknownErrorMessage(interaction)
      ErrorCheckingSponsorshipStatus->raise
    }
  }
}

exception NoAvailableSP
let getServerSPBalance = async sponsorshipAddress => {
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
  | exception JsError(_) => NoAvailableSP->raise
  }
}

let noSponsorshipsMessage = async interaction => {
  let options = {
    "content": "Whoops! You haven't received a sponsor. There are plenty of apps with free sponsors, such as the [EIDI Faucet](https://idchain.one/begin/). \n\n See all the apps available at https://apps.brightid.org \n\n Then scan the QR code above in the BrightID mobile app.",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
}

let noWriteToGistMessage = async interaction => {
  let options = {
    "content": "It seems like I can't write to my database at the moment. Please try again or contact the BrightID support.",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
}

let handleUnverifiedGuildMember = async (errorNum, interaction, uuid) => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  switch errorNum {
  | 2 =>
    let options = await makeNotLinkedOptions(uri, verifyUrl)
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

let execute = (interaction: Interaction.t) => {
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
          _ => VerifyHandlerError(`Guild Id ${guildId} could not be found in the gist`)->reject,
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
                switch 4 {
                | 4 =>
                  switch sponsorshipAddress {
                  | None =>
                    let _ = await noSponsorshipsMessage(interaction)
                  | Some(sponsorshipAddress) =>
                    let _ = switch await getServerSPBalance(sponsorshipAddress) {
                    | assignedSponsorships =>
                      let availableSponsorships =
                        assignedSponsorships->Ethers.BigNumber.subWithString(
                          guildData.usedSponsorships->Belt.Option.getWithDefault("0"),
                        )
                      let assignedSponsorships = assignedSponsorships->Ethers.BigNumber.toString
                      let entry = guilds->Js.Dict.get(guildId)->Belt.Option.getExn
                      switch (
                        await Utils.Gist.UpdateGist.updateEntry(
                          ~config=gistConfig(),
                          ~content=guilds,
                          ~key=guildId,
                          ~entry={...entry, assignedSponsorships: Some(assignedSponsorships)},
                        ),
                        availableSponsorships->Ethers.BigNumber.isZero,
                      ) {
                      | (Ok(_), true) =>
                        let _ = await noSponsorshipsMessage(interaction)
                      | (Ok(_), false) =>
                        let _ = switch await handleSponsor(interaction, uuid, ()) {
                        | SPNotUsed => ()
                        | SPUsed =>
                          open Ethers.BigNumber
                          let usedSponsorships =
                            guildData.usedSponsorships
                            ->Belt.Option.getWithDefault("0")
                            ->fromString
                            ->addWithString("1")
                            ->toString
                          switch await Utils.Gist.UpdateGist.updateEntry(
                            ~config=gistConfig(),
                            ~content=guilds,
                            ~key=guildId,
                            ~entry={...entry, usedSponsorships: Some(usedSponsorships)},
                          ) {
                          | Ok(_) => Js.log("Successfully sponsored user with context id: " ++ uuid)
                          | Error(err) =>
                            let guildName = guild->Guild.getGuildName
                            Js.log2(
                              `User with context id ${uuid} from server ${guildName} was unable to write their sponsorship to the gist: `,
                              err,
                            )
                            let _ = await noWriteToGistMessage(interaction)
                          }
                        | ErrorCheckingSponsorshipStatus =>
                          let guildName = guild->Guild.getGuildName
                          Js.log(
                            `User with context id ${uuid} from server ${guildName} was unable to check their sponsorship status properly: `,
                          )
                          let _ = await noWriteToGistMessage(interaction)
                        }
                      | (Error(_), _) =>
                        let _ = await noWriteToGistMessage(interaction)
                      }

                    | exception NoAvailableSP =>
                      let _ = await noSponsorshipsMessage(interaction)
                    | exception JsError(_) => Js.Console.error("Verify Handler: Unknown error")
                    }
                  }
                | _ => {
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
        | None => Js.Console.error("Verify Handler: Unknown error")->resolve
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
