open Promise
open Endpoints
open Types
open Variants
exception VerifyHandlerError(string)

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("UUID") external _v5: (string, string) => t = "v5"

  let validateNamespace = namespace =>
    switch namespace {
    | Env.UUIDNamespace(namespace) => namespace
    }
  let validateName = name =>
    switch name {
    | UUIDName(name) => name
    }

  let v5 = (name, namespace) => {
    let name = name->validateName
    let namespace = namespace->validateNamespace
    _v5(name, namespace)
  }
}

module Canvas = {
  type t
  @module("Canvas") external _createCanvas: (int, int) => t = "createCanvas"
  @send external toBuffer: t => Node.Buffer.t = "toBuffer"
}

module QRCode = {
  type t
  @module("QRCode") external _toCanvas: (Canvas.t, string) => Promise.t<unit> = "toCanvas"
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

@module
external fetch: (string, 'params) => Promise.t<Response.t<response>> = "node-fetch"

Env.createEnv()

let config = Env.getConfig()

let uuidNAMESPACE = switch config {
| Ok(config) => config["uuidNamespace"]
| Error(err) => err->VerifyHandlerError->raise
}

let addVerifiedRole = (member: Types.guildMember, role: Types.role, reason) => {
  let guildMemberRoleManager = member.roles->wrapGuildMemberRoleManager
  let guild = member.guild->wrapGuild
  guildMemberRoleManager->Discord_GuildMemberRoleManager.add(role, reason)->ignore
  member->Discord_GuildMember.send(
    `I recognize you! You're now a verified user in ${guild.name->Discord_Guild.validateGuildName}`,
  )
}

let idExists = id => {
  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timeout": 60000,
  }
  fetch("https://app.brightid.org/node/v5/verifications/Discord", params)
  ->then(res => res->Response.json)
  ->then(res =>
    switch Js.Nullable.toOption(res["data"]) {
    | Some(data) => resolve(data)
    | None => reject(VerifyHandlerError("No data"))
    }
  )
  ->then(data => {
    //Notice we use pattern matching to extract the json
    //Heavily relient on backend specification
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
          switch exists {
          | true => resolve(exists)
          | false => resolve(exists)
          }
        }
      }
    }
  })
  ->catch(e => {
    switch e {
    | VerifyHandlerError(msg) => Js.Console.error(msg)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    resolve(false)
  })
}

let makeEmbed = verifyUrl => {
  let fields: array<Discord_MessageEmbed.embedFieldData> = [
    {
      name: "1. Get Verified in the BrightID app",
      value: `Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet "https://www.brightid.org/meet") that are hosted in the BrightID server and require members join a voice/video call.`,
    },
    {
      name: "2. Link to a Sponsored App (like 1hive, gitcoin, etc)",
      value: `You can link to these [sponsored apps](https://apps.brightid.org/ "https://apps.brightid.org/") once you are verified within the app.`,
    },
    {
      name: "3. Type the `!verify` command in any public channel",
      value: `You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH "https://discord.gg/gH6qAUH").`,
    },
    {
      name: `4. Scan the DM"d QR Code`,
      value: `Open the BrightID app and scan the QR code. Mobile users can click [this link](${verifyUrl}).`,
    },
    {
      name: "5. Type the `!me` command in any public channel",
      value: "Once you have scanned the QR code you can return to any public channel and type the `!me` command which should grant you the orange verified role.",
    },
  ]
  open Discord_MessageEmbed

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
  let canvas = Canvas._createCanvas(700, 250)

  QRCode._toCanvas(canvas, uri)->then(_ => {
    let attachment = Discord_Message.createMessageAttachment(
      canvas->Canvas.toBuffer,
      "qrcode.png",
      (),
    )
    resolve(attachment)
  })
}

let getRolebyRoleName = (guildRoleManager, roleName) => {
  let guildRole = guildRoleManager.cache->Belt.Map.findFirstBy((_, role) => {
    let role = role->wrapRole
    role.name->Discord_Role.validateRoleName === roleName
  })
  switch guildRole {
  | Some((_, guildRole)) => guildRole->wrapRole
  | None => VerifyHandlerError("Could not find a role with the name " ++ roleName)->raise
  }
}

let verify = (member: guildMember, _: client, message: message) => {
  let guild = member.guild->wrapGuild
  let guildRoleManager = guild.roles->wrapRoleManager
  let guildMemberRoleManager = member.roles->wrapGuildMemberRoleManager
  let memberId = member.id->Discord_Snowflake.validateSnowflake
  let id = memberId->UUIDName->UUID.v5(uuidNAMESPACE)
  Handlers_Role.readGist()->then(guilds => {
    let guildId = guild.id->Discord_Snowflake.validateSnowflake
    let guildData = guilds->Js.Dict.get(guildId)
    switch guildData {
    | None =>
      message
      ->Discord_Message.reply(Types.Content("Failed to retrieve role data for guild"))
      ->ignore
      reject(VerifyHandlerError("Guild does not exist"))
    | Some(guildData) => {
        let guildRole = guildRoleManager->getRolebyRoleName(guildData.role)
        let deepLink = `${brightIdAppDeeplink}/${id}`
        let verifyUrl = `${brightIdLinkVerificationEndpoint}/${id}`
        id
        ->idExists
        ->then(exists => {
          open Discord_GuildMemberRoleManager
          switch exists {
          | true => {
              guildMemberRoleManager->add(guildRole, Reason(""))->ignore
              member->Discord_GuildMember.send(
                `I recognize you! You're now a verified user in ${guild.name->Discord_Guild.validateGuildName}`,
                (),
              )
            }
          | false =>
            deepLink
            ->createMessageAttachmentFromUri
            ->then(attachment => {
              open Discord_GuildMember
              let embed = verifyUrl->makeEmbed
              member->send({"embed": embed, "files": [attachment]}, ())->ignore
              resolve(message.t)
            })
          }
        })
      }
    }
  })
}
