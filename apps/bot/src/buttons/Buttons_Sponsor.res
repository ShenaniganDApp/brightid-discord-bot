open Discord
open Shared
open NodeFetch
open Exceptions

let {brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(Endpoints)

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

let sponsorRequestSubmittedMessageOptions = async () => {
  let nowInSeconds = Math.round(Date.now() /. 1000.)
  let fifteenMinutesAfter = 15. *. 60. +. nowInSeconds
  let content = `You sponsor request has been submitted! \n\n Make sure you have scanned the QR code above in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:${fifteenMinutesAfter->Float.toString}:R>.\n\nPlease be patient as the BrightID nodes sync your request \n`
  {
    "content": content,
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

type sponsorship = Sponsorship(BrightId.Sponsorships.t)
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
      switch guilds->Dict.get(guildId) {
      | None =>
        let _ = await noWriteToGistMessage(interaction)
        SponsorButtonError(
          `Buttons_Sponsor: Guild with guildId: ${guildId} not found in gist`,
        )->raise
      | Some(guildData) =>
        open Services_Sponsor
        let _ = switch await handleSponsor(interaction, uuid, Helpers.fifteenMinutesFromNow()) {
        | exception e => e->raise
        | SponsorshipUsed =>
          let usedSponsorships =
            guildData.usedSponsorships->Option.getWithDefault(
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
            Console.error2("Buttons Sponsor: Error updating used sponsorships", err)
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
