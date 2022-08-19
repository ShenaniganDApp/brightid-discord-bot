open Promise
open Endpoints
open Discord
exception VerifyHandlerError(string)

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("uuid") external v5: (string, string) => t = "v5"
}

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

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}
type response = {
  "data": Js.Nullable.t<{
    "count": Js.Nullable.t<int>,
    "contextIds": Js.Nullable.t<array<string>>,
    "error": Js.Nullable.t<bool>,
    "errorMessage": Js.Nullable.t<string>,
  }>,
}

type brightIdGuildData = {
  name: string,
  role: string,
  inviteLink: Js.Nullable.t<string>,
}

@module("../updateOrReadGist.mjs")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

@module("node-fetch")
external fetch: (string, 'params) => Promise.t<Response.t<response>> = "default"

Env.createEnv()

let config = Env.getConfig()

let uuidNAMESPACE = switch config {
| Ok(config) => config["uuidNamespace"]
| Error(err) => err->VerifyHandlerError->raise
}

let addVerifiedRole = (member, role, reason) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  let guild = member->GuildMember.getGuild
  guildMemberRoleManager->GuildMemberRoleManager.add(role, reason)->ignore
  member->GuildMember.send(
    `I recognize you! You're now a verified user in ${guild->Guild.getGuildName}`,
  )
}

let isIdInVerifications = (data, id) => {
  switch Js.Nullable.toOption(data["error"]) {
  | Some(_) =>
    switch Js.Nullable.toOption(data["errorMessage"]) {
    | None => reject(VerifyHandlerError("No error message"))
    | Some(msg) => reject(VerifyHandlerError(msg))
    }
  | None =>
    switch Js.Nullable.toOption(data["contextIds"]) {
    | None => reject(VerifyHandlerError("Didn't return contextIds"))
    | Some(contextIds) => {
        let exists = contextIds->Belt.Array.some(contextId => id === contextId)
        exists->resolve
      }
    }
  }
}

let fetchVerifications = () => {
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timeout": 60000,
  }
  "https://app.brightid.org/node/v5/verifications/Discord"
  ->fetch(params)
  ->then(res => res->Response.json)
  ->then(res =>
    switch Js.Nullable.toOption(res["data"]) {
    | Some(data) => data->resolve
    | None => VerifyHandlerError("No data")->reject
    }
  )
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

let getRolebyRoleName = (guildRoleManager, roleName) => {
  let guildRole =
    guildRoleManager
    ->RoleManager.getCache
    ->Collection.find(role => role->Role.getName === roleName)
    ->Js.Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => VerifyHandlerError("Could not find a role with the name " ++ roleName)->raise
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

let execute = (interaction: Interaction.t) => {
  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  let memberId = member->GuildMember.getGuildMemberId
  let id = memberId->UUID.v5(uuidNAMESPACE)
  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    readGist()
    ->then(guilds => {
      let guildId = guild->Guild.getGuildId
      let guildData = guilds->Js.Dict.get(guildId)
      switch guildData {
      | None =>
        interaction
        ->Interaction.editReply(
          ~options={
            "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightId",
          },
          (),
        )
        ->ignore
        VerifyHandlerError("Guild does not exist")->reject
      | Some(guildData) => {
          let guildRole = guildRoleManager->getRolebyRoleName(guildData.role)
          let deepLink = `${brightIdAppDeeplink}/${id}`
          let verifyUrl = `${brightIdLinkVerificationEndpoint}/${id}`
          fetchVerifications()
          ->then(data => isIdInVerifications(data, id))
          ->then(idExists => {
            idExists
              ? {
                    guildMemberRoleManager->GuildMemberRoleManager.add(guildRole, ())->ignore
                  interaction
                  ->Interaction.editReply(
                    ~options={
                      "content": `Hey, I recognize you! I just gave you the \`${guildRole->Role.getName}\` role. You are now BrightID verified in ${guild->Guild.getGuildName} server!`,
                      "ephemeral": true,
                    },
                    (),
                  )
                  ->ignore
                  resolve()
                }
              : deepLink
                ->createMessageAttachmentFromUri
                ->then(attachment => {
                  let embed = verifyUrl->makeEmbed
                  let row = verifyUrl->makeVerifyActionRow
                  interaction
                  ->Interaction.editReply(
                    ~options={
                      "embeds": [embed],
                      "files": [attachment],
                      "ephemeral": true,
                      "components": [row],
                    },
                    (),
                  )
                  ->ignore
                  resolve()
                })
          })
        }
      }
    })
    ->catch(e => {
      switch e {
      | VerifyHandlerError(msg) => Js.Console.error(msg)
      | JsError(obj) =>
        switch Js.Exn.message(obj) {
        | Some(msg) => Js.Console.error(msg)
        | None => Js.Console.error("Verify Handler: Unknown error")
        }
      | _ => Js.Console.error("Verify Handler: Unknown error")
      }
      resolve()
    })
  })
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("verify")
  ->SlashCommandBuilder.setDescription(
    "Sends a BrightID QR code for users to connect with their BrightId",
  )
