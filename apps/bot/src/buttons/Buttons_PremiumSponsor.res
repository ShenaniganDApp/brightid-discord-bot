open Discord
open Promise
open Shared
open NodeFetch

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context} = module(Constants)

let {
  makeCanvasFromUri,
  createMessageAttachmentFromCanvas,
  makeBeforeSponsorActionRow,
  unknownErrorMessage,
} = module(Commands_Verify)

exception BrightIdError(BrightId.Error.t)
exception ButtonSponsorHandlerError(string)

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

let sleep: int => Js.Promise.t<unit> = ms =>
  %raw(` new Promise((resolve) => setTimeout(resolve, ms))`)

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let noUnusedSponsorshipsOptions = () =>
  {
    "content": "There are no sponsorhips available in the Discord pool. Please try again later.",
    "ephemeral": true,
  }

let unsuccessfulSponsorMessageOptions = async uuid => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let canvas = await makeCanvasFromUri(uri)
  let attachment = await createMessageAttachmentFromCanvas(canvas)
  let row = makeBeforeSponsorActionRow("Retry Sponsor")
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
  let content = `You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:${fiveMinutesAfter->Belt.Float.toString}:R>.\n\nPlease be patient until time expires \n`
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
  | (_, Ok(error)) => error->BrightIdError->raise
  | (Error(err), _) => err->Json.Decode.DecodeError->raise
  }
}

exception HandleSponsorError(string)
type sponsor =
  | SponsorSuccess(BrightId.Sponsorships.sponsor)
  | BrightIdError(BrightId.Error.t)
  | JsError(Js.Exn.t)
type handleSponsor =
  | SponsorshipUsed
  | RetriedCommandDuring
  | NoUnusedSponsorships
  | TimedOut

let rec handleSponsor = async (interaction, ~maybeHash=None, ~attempts=30, uuid) => {
  open Shared.BrightId
  open Shared.Decode
  let guildId = interaction->Interaction.getGuild->Guild.getGuildId
  let secondsBetweenAttempts = 30
  switch attempts {
  | 0 => TimedOut
  | _ =>
    switch await sponsor(~key=envConfig["sponsorshipKey"], ~context="Discord", ~contextId=uuid) {
    | json =>
      switch json->Json.decode(Decode_BrightId.Sponsorships.sponsor) {
      | Ok({hash}) =>
        let options = await sponsorRequestSubmittedMessageOptions(uuid)
        let _ = await Interaction.editReply(interaction, ~options, ())
        Js.log2(
          `A sponsor request has been submitted`,
          {"guild": guildId, "contextId": uuid, "hash": hash},
        )
        await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=30)
      | Error(err) => Json.Decode.DecodeError(err)->raise
      }
    | exception Js.Exn.Error(error) =>
      let json = switch Js.Json.stringifyAny(error) {
      | Some(json) => json->Js.Json.parseExn
      | None =>
        HandleSponsorError(
          "Handle Sponsor Error: There was a problem JSON parsing the error from sponsor()",
        )->raise
      }
      switch json->Json.decode(Decode_BrightId.Error.data) {
      | Error(err) => err->Json.Decode.DecodeError->raise
      | Ok({errorNum, errorMessage}) =>
        switch errorNum {
        //No Sponsorships in the Discord App
        | 38 => NoUnusedSponsorships
        //Sponsorship already assigned
        | 39 =>
          switch maybeHash {
          | Some(hash) =>
            switch await checkSponsor(uuid) {
            | Sponsorship({spendRequested}) =>
              if spendRequested {
                let options = successfulSponsorMessageOptions(uuid)
                let _ = await Interaction.editReply(interaction, ~options, ())
                SponsorshipUsed
              } else {
                let _ = await sleep(secondsBetweenAttempts * 1000)
                await handleSponsor(
                  interaction,
                  uuid,
                  ~maybeHash=Some(hash),
                  ~attempts=attempts - 1,
                )
              }
            | exception BrightIdError(_) =>
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=attempts - 1)
            | exception JsError(obj) =>
              switch Js.Exn.message(obj) {
              | Some(msg) => HandleSponsorError(msg)->raise

              | None =>
                Js.Console.error(obj)
                HandleSponsorError("Handle Sponsor: Unknown Error")->raise
              }
            }
          | None => RetriedCommandDuring
          }
        //App authorized before
        | 45 =>
          switch maybeHash {
          | Some(hash) =>
            switch await checkSponsor(uuid) {
            | Sponsorship({spendRequested}) =>
              if spendRequested {
                let options = successfulSponsorMessageOptions(uuid)
                let _ = await Interaction.editReply(interaction, ~options, ())
                SponsorshipUsed
              } else {
                let _ = await sleep(secondsBetweenAttempts * 1000)
                await handleSponsor(
                  interaction,
                  uuid,
                  ~maybeHash=Some(hash),
                  ~attempts=attempts - 1,
                )
              }
            | exception BrightIdError(_) =>
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=attempts - 1)
            | exception JsError(obj) =>
              switch Js.Exn.message(obj) {
              | Some(msg) => HandleSponsorError(msg)->raise

              | None =>
                Js.Console.error(obj)
                HandleSponsorError("Handle Sponsor: Unknown Error")->raise
              }
            }
          | None => RetriedCommandDuring
          }

        // // Spend Request Submitted
        | 46 =>
          switch maybeHash {
          | Some(_) =>
            let options = await successfulSponsorMessageOptions(uuid)
            let _ = await interaction->Interaction.editReply(~options, ())
            SponsorshipUsed
          | None => RetriedCommandDuring
          }
        // Sponsored Request Recently
        | 47 =>
          switch maybeHash {
          | Some(hash) =>
            switch await checkSponsor(uuid) {
            | Sponsorship({spendRequested}) =>
              if spendRequested {
                let options = successfulSponsorMessageOptions(uuid)
                let _ = await Interaction.editReply(interaction, ~options, ())
                SponsorshipUsed
              } else {
                let _ = await sleep(secondsBetweenAttempts * 1000)
                await handleSponsor(
                  interaction,
                  uuid,
                  ~maybeHash=Some(hash),
                  ~attempts=attempts - 1,
                )
              }
            | exception BrightIdError(_) =>
              let _ = await sleep(secondsBetweenAttempts * 1000)
              await handleSponsor(interaction, uuid, ~maybeHash=Some(hash), ~attempts=attempts - 1)
            | exception JsError(obj) =>
              switch Js.Exn.message(obj) {
              | Some(msg) => HandleSponsorError(msg)->raise

              | None =>
                Js.Console.error(obj)
                HandleSponsorError("Handle Sponsor: Unknown Error")->raise
              }
            }
          | None => RetriedCommandDuring
          }

        | _ => HandleSponsorError(errorMessage)->raise
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
  | exception JsError(obj) =>
    switch Js.Exn.message(obj) {
    | Some(msg) => Js.Console.error(msg)

    | None => Js.Console.error("Must be some non-error value")
    }
  | _ =>
    switch await Gist.ReadGist.content(~config=gistConfig(), ~decoder=Decode_Gist.brightIdGuilds) {
    | exception JsError(msg) =>
      Js.Console.error(msg)
      let _ = await unknownErrorMessage(interaction)

    | exception Json.Decode.DecodeError(msg) =>
      Js.Console.error(msg)
      let _ = await unknownErrorMessage(interaction)

    | guilds =>
      switch guilds->Js.Dict.get(guildId) {
      | None =>
        Js.Console.error(`Buttons_Sponsor: Guild with guildId: ${guildId} not found in gist`)
        let _ = noWriteToGistMessage(interaction)
      | Some(guildData) =>
        let _ = switch await handleSponsor(interaction, uuid) {
        | SponsorshipUsed =>
          let premiumSponsorshipsUsed =
            guildData.premiumSponsorshipsUsed->Belt.Option.getWithDefault(
              Ethers.BigNumber.zero->Ethers.BigNumber.toString,
            )
          let premiumSponsorshipsUsed =
            premiumSponsorshipsUsed
            ->Ethers.BigNumber.fromString
            ->Ethers.BigNumber.addWithString("1")
            ->Ethers.BigNumber.toString

          let updatePremiumSponsorshipsUsed = await Utils.Gist.UpdateGist.updateEntry(
            ~config=gistConfig(),
            ~content=guilds,
            ~key=guildId,
            ~entry={...guildData, premiumSponsorshipsUsed: Some(premiumSponsorshipsUsed)},
          )
          switch updatePremiumSponsorshipsUsed {
          | Ok(_) =>
            let options = await successfulSponsorMessageOptions(uuid)
            let _ = await Interaction.followUp(interaction, ~options, ())
          | Error(err) =>
            Js.Console.error2("Buttons Sponsor: Error updating premium used sponsorships", err)
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
          let _ = await Interaction.followUp(interaction, ~options, ())
        | exception HandleSponsorError(errorMessage) =>
          let guildName = guild->Guild.getGuildName
          Js.Console.error2(
            `User: ${uuid} from server ${guildName} ran into an unexpected error: `,
            errorMessage,
          )
          let _ = await unknownErrorMessage(interaction)
        | exception JsError(err) =>
          let guildName = guild->Guild.getGuildName
          Js.Console.error2(
            `User: ${uuid} from server ${guildName} ran into an unexpected error: `,
            err,
          )
          let _ = await unknownErrorMessage(interaction)
        }
      }
    }
  }
}

let customId = "before-premium-sponsor"
