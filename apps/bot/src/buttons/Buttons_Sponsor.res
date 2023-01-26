open Discord
open Shared
open NodeFetch
open Exceptions

let {brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(Endpoints)

let {makeCanvasFromUri, createMessageAttachmentFromCanvas, makeBeforeSponsorActionRow} = module(
  Commands_Verify
)

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

let sleep: int => Js.Promise.t<unit> = _ms =>
  %raw(` new Promise((resolve) => setTimeout(resolve, _ms))`)

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let noUnusedSponsorshipsOptions = () =>
  {
    "content": "There are no sponsorships available in the Discord pool. Please try again later.",
    "ephemeral": true,
  }

let unsuccessfulSponsorMessageOptions = async uuid => {
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let row = makeBeforeSponsorActionRow("Retry Sponsor", verifyUrl)
  {
    "content": "Your sponsor request failed. \n\n This is often due to the BrightID App not being linked to Discord. Please scan this QR code in the BrightID mobile app then retry your sponsorship request.\n\n",
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}
let sponsorRequestSubmittedMessageOptions = async uuid => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let nowInSeconds = Js.Math.round(Js.Date.now() /. 1000.)
  let fifteenMinutesAfter = 15. *. 60. +. nowInSeconds
  let content = `You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:${fifteenMinutesAfter->Belt.Float.toString}:R>.\n\nPlease be patient until time expires \n`
  {
    "content": content,
    "files": [attachment],
    "ephemeral": true,
  }
}

let noWriteToGistMessage = async interaction => {
  let options = {
    "content": "It seems like I can't write to my database at the moment. Please try again or contact the BrightID support.",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
}

let makeAfterSponsorActionRow = label => {
  let verifyButton =
    MessageButton.make()
    ->MessageButton.setCustomId("verify")
    ->MessageButton.setLabel(label)
    ->MessageButton.setStyle("PRIMARY")

  MessageActionRow.make()->MessageActionRow.addComponents([verifyButton])
}

let successfulSponsorMessageOptions = async uuid => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let row = makeAfterSponsorActionRow("Assign BrightID Verified Role")
  {
    "content": "You have succesfully been sponsored \n\n If you are verified in BrightID you are all done. Click the button below to assign your role.\n\n",
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}

type sponsorship = Sponsorship(BrightId.Sponsorships.t)
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
  | (_, Ok(error)) => error->Exceptions.BrightIdError->raise
  | (Error(err), _) => err->Json.Decode.DecodeError->raise
  }
}

exception HandleSponsorError(string)
type sponsor = SponsorSuccess(BrightId.Sponsorships.sponsor)
type handleSponsor =
  | SponsorshipUsed
  | RetriedCommandDuring
  | NoUnusedSponsorships
  | TimedOut

@raises([HandleSponsorError, Js.Exn.Error, Json.Decode.DecodeError])
let rec handleSponsor = async (interaction, ~maybeHash=None, ~attempts=30, uuid) => {
  open Shared.BrightId
  open Shared.Decode
  let guildId = interaction->Interaction.getGuild->Guild.getGuildId
  let secondsBetweenAttempts = 29 //29 seconds between attempts to leave time for timeout message
  switch attempts {
  | 0 => TimedOut
  | _ =>
    try {
      let json = await sponsor(
        ~key=envConfig["sponsorshipKey"],
        ~context="Discord",
        ~contextId=uuid,
      )
      switch json->Json.decode(Decode_BrightId.Sponsorships.sponsor) {
      | Ok({hash}) =>
        let options = await sponsorRequestSubmittedMessageOptions(uuid)
        let _ = await Interaction.editReply(interaction, ~options, ())
        Js.log2(
          `A sponsor request has been submitted`,
          {"guild": guildId, "contextId": uuid, "hash": hash},
        )
        let _ = await CustomMessages.sponsorshipRequested(interaction, hash, uuid)
        await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=30)
      | Error(err) => Json.Decode.DecodeError(err)->raise
      }
    } catch {
    | Js.Exn.Error(error) =>
      let json = switch Js.Json.stringifyAny(error) {
      | Some(json) => json->Js.Json.parseExn
      | None =>
        HandleSponsorError(
          "Handle Sponsor Error: There was a problem JSON parsing the error from sponsor()",
        )->raise
      }
      try {
        switch json->Json.decode(Decode_BrightId.Error.data) {
        | Error(err) => err->Json.Decode.DecodeError->raise
        | Ok({errorNum, errorMessage}) =>
          switch (errorNum, maybeHash) {
          //No Sponsorships in the Discord App
          | (38, _) => NoUnusedSponsorships
          //Sponsorship already assigned
          | (_, None) => RetriedCommandDuring
          | (39, Some(_)) =>
            let Sponsorship({spendRequested}) = await checkSponsor(uuid)
            if spendRequested {
              let options = successfulSponsorMessageOptions(uuid)
              let _ = await Interaction.editReply(interaction, ~options, ())
              SponsorshipUsed
            } else {
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
            }
          //App authorized before
          | (45, Some(_)) =>
            let Sponsorship({spendRequested}) = await checkSponsor(uuid)
            if spendRequested {
              let options = successfulSponsorMessageOptions(uuid)
              let _ = await Interaction.editReply(interaction, ~options, ())
              SponsorshipUsed
            } else {
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
            }

          // Spend Request Submitted
          | (46, Some(_)) =>
            let options = await successfulSponsorMessageOptions(uuid)
            let _ = await interaction->Interaction.editReply(~options, ())
            SponsorshipUsed

          // Sponsored Request Recently
          | (47, Some(_)) =>
            let Sponsorship({spendRequested}) = await checkSponsor(uuid)
            if spendRequested {
              let options = successfulSponsorMessageOptions(uuid)
              let _ = await Interaction.editReply(interaction, ~options, ())
              SponsorshipUsed
            } else {
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
            }

          | _ => HandleSponsorError(errorMessage)->raise
          }
        }
      } catch {
      | Exceptions.BrightIdError(_) =>
        let _ = await sleep(secondsBetweenAttempts * 1000)
        await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
      | Js.Exn.Error(obj) =>
        switch Js.Exn.message(obj) {
        | Some(msg) => HandleSponsorError(msg)->raise
        | None =>
          Js.Console.error(obj)
          HandleSponsorError("Handle Sponsor: Unknown Error")->raise
        }
      }
    }
  }
}

let gistConfig = () =>
  Utils.Gist.makeGistConfig(
    ~id=envConfig["gistId"],
    ~name="guildData.json",
    ~token=envConfig["githubAccessToken"],
  )

let execute = async interaction => {
  open Utils
  open Shared.Decode
  let guild = interaction->Interaction.getGuild
  let guildId = guild->Guild.getGuildId
  let member = interaction->Interaction.getGuildMember
  let memberId = member->GuildMember.getGuildMemberId
  let uuid = memberId->UUID.v5(envConfig["uuidNamespace"])
  switch await Interaction.deferReply(interaction, ~options={"ephemeral": true}, ()) {
  | exception e => e->raise
  | _ =>
    switch await Gist.ReadGist.content(~config=gistConfig(), ~decoder=Decode_Gist.brightIdGuilds) {
    | exception e => e->raise
    | guilds =>
      switch guilds->Js.Dict.get(guildId) {
      | None =>
        let _ = await noWriteToGistMessage(interaction)
        SponsorButtonError(
          `Buttons_Sponsor: Guild with guildId: ${guildId} not found in gist`,
        )->raise
      | Some(guildData) =>
        let _ = switch await handleSponsor(interaction, uuid) {
        | exception e => e->raise
        | SponsorshipUsed =>
          let usedSponsorships =
            guildData.usedSponsorships->Belt.Option.getWithDefault(
              Ethers.BigNumber.zero->Ethers.BigNumber.toString,
            )
          let usedSponsorships =
            usedSponsorships
            ->Ethers.BigNumber.fromString
            ->Ethers.BigNumber.addWithString("1")
            ->Ethers.BigNumber.toString

          let updateUsedSponsorships = await Utils.Gist.UpdateGist.updateEntry(
            ~config=gistConfig(),
            ~content=guilds,
            ~key=guildId,
            ~entry={...guildData, usedSponsorships: Some(usedSponsorships)},
          )
          switch updateUsedSponsorships {
          | Ok(_) =>
            let options = await successfulSponsorMessageOptions(uuid)
            let _ = await Interaction.followUp(interaction, ~options, ())
          | Error(err) =>
            Js.Console.error2("Buttons Sponsor: Error updating used sponsorships", err)
            let _ = await noWriteToGistMessage(interaction)
          }

        | NoUnusedSponsorships =>
          let _ = await Interaction.followUp(
            interaction,
            ~options=noUnusedSponsorshipsOptions(),
            (),
          )

        | RetriedCommandDuring =>
          let options = {
            "content": "Your request is still processing. Maybe you haven't scanned the QR code yet?\n\n If you have already scanned the code, please wait a few minutes for BrightID nodes to sync your sponsorship request",
            "ephemeral": true,
          }
          let _ = await Interaction.followUp(interaction, ~options, ())
        | TimedOut =>
          let options = await unsuccessfulSponsorMessageOptions(uuid)
          let _ = await Interaction.editReply(interaction, ~options, ())
        }
      }
    }
  }
}

let customId = "before-sponsor"
