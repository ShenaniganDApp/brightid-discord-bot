open Discord
open NodeFetch

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)

let {makeCanvasFromUri, createMessageAttachmentFromCanvas, makeBeforeSponsorActionRow} = module(
  Commands_Verify
)

@val @scope("globalThis")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "fetch"

let sleep: int => promise<unit> = _ms => %raw(` new Promise((resolve) => setTimeout(resolve, _ms))`)

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

exception RetryAsync(string)
let rec retry = async (fn, n) => {
  try {
    let _ = await sleep(1000)
    await fn()
  } catch {
  | _ =>
    if n > 0 {
      await retry(fn, n - 1)
    }
  }
  RetryAsync(j`Failed $fn retrying $n times`)->raise
}

let noUnusedSponsorshipsOptions = () =>
  {
    "content": "There are no sponsorhips available in the Discord pool. Please try again later.",
    "ephemeral": true,
  }

let unsuccessfulSponsorMessageOptions = async uuid => {
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let row = makeBeforeSponsorActionRow("Retry Sponsor", verifyUrl)
  {
    "content": "Your sponsor request failed. \n\n This is often due to the BrightID App not being linked to Discord. Please scan the previous QR code in the BrightID mobile app then retry your sponsorship request.\n\n",
    "ephemeral": true,
    "components": [row],
  }
}
let sponsorRequestSubmittedMessageOptions = async () => {
  let nowInSeconds = Math.round(Date.now() /. 1000.)
  let fifteenMinutesAfter = 15. *. 60. +. nowInSeconds
  let content = `You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:${fifteenMinutesAfter->Float.toString}:R>.\n\n`
  {
    "content": content,
    "ephemeral": true,
  }
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

exception HandleSponsorError(string)
type sponsor = SponsorSuccess(Shared.BrightId.Sponsorships.sponsor)
type handleSponsor =
  | SponsorshipUsed
  | RetriedCommandDuring
  | NoUnusedSponsorships
  | TimedOut

type sponsorship = Sponsorship(Shared.BrightId.Sponsorships.t)
let checkSponsor = async uuid => {
  open Shared.Decode
  let endpoint = `https://app.brightid.org/node/v5/sponsorships/${uuid}`
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

  switch (
    json->Json.decode(Decode_BrightId.Sponsorships.data),
    json->Json.decode(Decode_BrightId.Error.data),
  ) {
  | (Ok({data}), _) => Sponsorship(data)
  | (_, Ok(error)) => error->Exceptions.BrightIdError->raise
  | (Error(err), _) => err->Json.Decode.DecodeError->raise
  }
}

@raises([HandleSponsorError, Exn.Error, Json.Decode.DecodeError])
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
        let options = await sponsorRequestSubmittedMessageOptions()
        let _ = await Interaction.editReply(interaction, ~options, ())
        Console.log2(
          `A sponsor request has been submitted`,
          {"guild": guildId, "contextId": uuid, "hash": hash},
        )
        let _ = await CustomMessages.sponsorshipRequested(interaction, uuid, hash)
        await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=30)
      | Error(err) => Json.Decode.DecodeError(err)->raise
      }
    } catch {
    | Exn.Error(error) =>
      try {
        let brightIdError =
          JSON.stringifyAny(error)
          ->Option.map(JSON.parseExn)
          ->Option.map(Json.decode(_, Decode_BrightId.Error.data))

        switch brightIdError {
        | None =>
          HandleSponsorError(
            "Handle Sponsor Error: There was a problem JSON parsing the error from sponsor()",
          )->raise
        | Some(Error(err)) => err->Json.Decode.DecodeError->raise
        | Some(Ok({errorNum})) =>
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

          | _ =>
            let _ = await sleep(secondsBetweenAttempts * 1000)
            await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
          }
        }
      } catch {
      | Exceptions.BrightIdError(_) =>
        let _ = await sleep(secondsBetweenAttempts * 1000)
        await handleSponsor(interaction, uuid, ~maybeHash, ~attempts=attempts - 1)
      | Json.Decode.DecodeError(msg) =>
        if msg->String.includes("503 Service Temporarily Unavailable") {
          let _ = await sleep(3000)
          await handleSponsor(interaction, uuid, ~maybeHash, ~attempts)
        } else {
          HandleSponsorError(msg)->raise
        }
      | Exn.Error(obj) =>
        switch Exn.name(obj) {
        | Some("FetchError") =>
          let _ = await sleep(3000)
          await handleSponsor(interaction, uuid, ~maybeHash, ~attempts)
        | _ =>
          switch Exn.message(obj) {
          | Some(msg) => HandleSponsorError(msg)->raise
          | None =>
            Console.error(obj)
            HandleSponsorError("Handle Sponsor: Unknown Error")->raise
          }
        }
      }
    }
  }
}
