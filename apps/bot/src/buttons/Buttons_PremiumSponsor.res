open Discord
open Shared
open NodeFetch
open Exceptions

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

let sleep: int => promise<unit> = _ms => %raw(` new Promise((resolve) => setTimeout(resolve, _ms))`)

@val @scope("globalThis")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "fetch"

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let noWriteToGistMessage = async interaction => {
  let options = {
    "content": "It seems like I can't write to my database at the moment. Please try again or contact the BrightID support.",
    "ephemeral": true,
  }

  await Interaction.followUp(interaction, ~options, ())
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
  | exception e => raise(e)
  | _ =>
    switch await Gist.ReadGist.content(~config=gistConfig(), ~decoder=Decode_Gist.brightIdGuilds) {
    | exception e =>
      let _ = await unknownErrorMessage(interaction)
      raise(e)

    | guilds =>
      switch guilds->Dict.get(guildId) {
      | None =>
        let _ = await noWriteToGistMessage(interaction)
        PremiumSponsorButtonError(
          `Buttons_PremiumSponsor: Guild with guildId: ${guildId} not found in gist`,
        )->raise
      | Some(guildData) =>
        open Services_Sponsor
        let _ = switch await handleSponsor(interaction, uuid) {
        | SponsorshipUsed =>
          let premiumSponsorshipsUsed =
            guildData.premiumSponsorshipsUsed->Option.getWithDefault(
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
            Console.error2("Buttons Sponsor: Error updating premium used sponsorships", err)
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
        | exception HandleSponsorError(errorMessage) =>
          let guildName = guild->Guild.getGuildName
          Console.error2(
            `User: ${uuid} from server ${guildName} ran into an unexpected error: `,
            errorMessage,
          )
          let _ = await unknownErrorMessage(interaction)
        | exception JsError(err) =>
          let guildName = guild->Guild.getGuildName
          Console.error2(
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
