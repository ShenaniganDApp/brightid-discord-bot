open Promise
open Discord
open BrightId
open NodeFetch

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context} = module(Constants)

exception VerifyHandlerError(string)
exception BrightIdError(brightIdError)

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

@val @scope("globalThis")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

Env.createEnv()

let config = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let addRoleToMember = (guildRole, member) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  guildMemberRoleManager->GuildMemberRoleManager.add(guildRole, ())
}
let fetchVerification = uuid => {
  let endpoint = `${brightIdVerificationEndpoint}/${context}/${uuid}?timestamp=seconds`
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timeout": 60000,
  }
  endpoint
  ->fetch(params)
  ->then(res => res->Response.json)
  ->then(json => {
    switch (json->Json.decode(Decode.BrightId.data), json->Json.decode(Decode.BrightId.error)) {
    | (Ok({data}), _) => data->resolve
    | (_, Ok(error)) => error->BrightIdError->reject
    | (Error(err), _) => err->Json.Decode.DecodeError->reject
    }
  })
}

let makeEmbed = verifyUrl => {
  let fields: array<MessageEmbed.embedFieldData> = [
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

let createMessageAttachmentFromUri = uri => {
  let canvas = Canvas.createCanvas(700, 250)

  QRCode.toCanvas(canvas, uri)->then(_ => {
    let attachment = Message.createMessageAttachment(canvas->Canvas.toBuffer, "qrcode.png", ())
    attachment->resolve
  })
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

let handleUnverifiedGuildMember = (errorNum, interaction, uuid) => {
  let deepLink = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  switch errorNum {
  | 2 =>
    deepLink
    ->createMessageAttachmentFromUri
    ->then(attachment => {
      let embed = verifyUrl->makeEmbed
      let row = verifyUrl->makeVerifyActionRow
      let options = {
        "embeds": [embed],
        "files": [attachment],
        "ephemeral": true,
        "components": [row],
      }
      interaction->Interaction.editReply(~options, ())->then(_ => resolve())
    })
  | 3 =>
    let options = {
      "content": "I haven't seen you at a Bright ID Connection Party yet, so your brightid is not verified. You can join a party in any timezone at https://meet.brightid.org",
    }
    interaction->Interaction.editReply(~options, ())->then(_ => resolve())
  | 4 =>
    deepLink
    ->createMessageAttachmentFromUri
    ->then(attachment => {
      let embed = verifyUrl->makeEmbed
      let row = verifyUrl->makeVerifyActionRow
      let options = {
        "embeds": [embed],
        "files": [attachment],
        "ephemeral": true,
        "components": [row],
      }
      interaction
      ->Interaction.editReply(~options, ())
      ->then(_ => {
        let options = {
          "content": "Whoops! You haven't received a sponsor. There are plenty of apps with free sponsors, such as the [EIDI Faucet](https://idchain.one/begin/). \n\n See all the apps available at https://apps.brightid.org \n\n Then scan the QR code above in the BrightID mobile app.",
        }
        interaction->Interaction.followUp(~options, ())->then(_ => resolve())
      })
    })
  | _ =>
    let options = {
      "content": "Something unexpected happened. Please try again later.",
    }
    interaction->Interaction.editReply(~options, ())->then(_ => resolve())
  }
}

let execute = (interaction: Interaction.t) => {
  open Utils

  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager
  let memberId = member->GuildMember.getGuildMemberId
  let uuid = memberId->UUID.v5(config["uuidNamespace"])
  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    let config = Gist.makeGistConfig(
      ~id=config["gistId"],
      ~name="guildData.json",
      ~token=config["githubAccessToken"],
    )
    Gist.ReadGist.content(~config, ~decoder=Decode.Gist.brightIdGuilds)
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
          let roleId = guildData["roleId"]->Belt.Option.getExn
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
                  "content": `Hey, I recognize you, but your account seems to be linked to a sybil attack. You are not properly BrightID verified. If this is a mistake, contact one of the support channels`,
                  "ephemeral": true,
                }
                interaction->Interaction.editReply(~options, ())->then(_ => resolve())
              },
          )
        }
      }
    })
    ->catch(e => {
      switch e {
      | BrightIdError({errorNum, errorMessage}) =>
        errorNum
        ->handleUnverifiedGuildMember(interaction, uuid)
        ->then(
          _ => Js.Console.error(`${member->GuildMember.getDisplayName}: ${errorMessage}`)->resolve,
        )
      | VerifyHandlerError(msg) => Js.Console.error(msg)->resolve
      | Json.Decode.DecodeError(msg) => Js.Console.error(msg)->resolve
      | JsError(obj) =>
        switch Js.Exn.message(obj) {
        | Some(msg) => Js.Console.error(msg)->resolve
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
