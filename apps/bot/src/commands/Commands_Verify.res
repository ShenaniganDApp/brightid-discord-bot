open Promise
open Discord
open NodeFetch
open Exceptions

let {brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(Endpoints)
let {context, contractAddressID, contractAddressETH} = module(Constants)

@val @scope("globalThis")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "fetch"

module QRCode = {
  @module("qrcode") external toBuffer: string => promise<Buffer.t> = "toBuffer"
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

let embedFields = verifyUrl => {
  open MessageEmbed
  [
    {
      name: "1. Get Verified in the BrightID app",
      value: `Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet) that are hosted in the BrightID server and require members join a voice/video call.`,
    },
    {
      name: "2. Type the `/verify` command in an appropriate channel",
      value: `You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH).`,
    },
    {
      name: `3. Scan the QR Code`,
      value: `Open the BrightID app and scan the QR code. Mobile users can click [this link](${verifyUrl}).`,
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

let createMessageAttachmentFromUri = async uri => {
  let buffer = await QRCode.toBuffer(uri)
  buffer->Message.createMessageAttachment("qrcode.png", ())
}

let getRolebyRoleId = (guildRoleManager, roleId) => {
  let guildRole = guildRoleManager->RoleManager.getCache->Collection.get(roleId)->Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => VerifyCommandError("Could not find a role with the id " ++ roleId)->raise
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
let makeBeforeSponsorActionRow = (customId, verifyUrl) => {
  let sponsorButton =
    MessageButton.make()
    ->MessageButton.setCustomId(customId)
    ->MessageButton.setLabel("Click this after scanning QR code")
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
  let attachment = await createMessageAttachmentFromUri(uri)
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

let beforeSponsorMessageOptions = async (customId, uuid) => {
  let uri = `${brightIdAppDeeplink}/${uuid}`
  let verifyUrl = `${brightIdLinkVerificationEndpoint}/${uuid}`
  let attachment = await createMessageAttachmentFromUri(uri)
  let row = makeBeforeSponsorActionRow(customId, verifyUrl)
  {
    "content": "Please scan this QR code in the BrightID app to link Discord. \n\n **__You can download the app on Android and iOS__** \n Android: <https://play.google.com/store/apps/details?id=org.brightid> \n\n iOS: <https://apps.apple.com/us/app/brightid/id1428946820> \n\n",
    "files": [attachment],
    "ephemeral": true,
    "components": [row],
  }
}

exception NoAvailableSP
let totalUnusedSponsorships = (usedSponsorships, assignedSponsorships, assignedSponsorshipsEth) => {
  open Ethers.BigNumber
  let totalAssignedSponsorships = assignedSponsorshipsEth->add(assignedSponsorships)
  let unusedSponsorships = totalAssignedSponsorships->sub(usedSponsorships)

  unusedSponsorships->lte(zero) ? raise(NoAvailableSP) : unusedSponsorships
}

let noSponsorshipsMessage = async interaction => {
  let options = {
    "content": "Whoops! You have not yet been sponsored. You can get sponsored from within the BrightID mobile app https://www.brightid.org/ \n\n ",
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
      "content": "Your BrightID is linked, but it has not completed the required verification. Check your status in the BrightID app and attend a verification party: https://www.brightid.org/meet",
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

let getAppUnusedSponsorships = async context => {
  switch await Services_AppInfo.getAppInfo(context) {
  | exception error =>
    Console.error2("Failed to retrieve BrightID sponsorship availability", error)
    None
  | data => Some(data.unusedSponsorships->BigInt.fromFloat)
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
    open Decode

    Gist.ReadGist.content(
      ~config=gistConfig(),
      ~decoder=Decode_Gist.brightIdGuilds,
    )->then(guilds => {
      let guildId = guild->Guild.getGuildId
      let guildData = guilds->Dict.get(guildId)
      switch guildData {
      | None =>
        let options = {
          "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightId",
        }
        interaction
        ->Interaction.editReply(~options, ())
        ->then(_ => VerifyCommandError(`Guild could not be found in the database`)->reject)

      | Some(guildData) =>
        switch guildData.roleId {
        | None =>
          let options = {
            "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightID. Try reinviting the bot. \n\n **Note: This will create a new role BrightID Role.**",
          }
          interaction
          ->Interaction.editReply(~options, ())
          ->then(_ => VerifyCommandError(`Guild does not have a saved roleId`)->reject)
        | Some(roleId) =>
          let guildRole = guildRoleManager->getRolebyRoleId(roleId)
          Services_VerificationInfo.getBrightIdVerification(member)
          ->then(
            verificationInfo => {
              switch verificationInfo {
              | VerificationInfo({unique, contextIds}) =>
                switch unique {
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

                | false if contextIds->Array.length === 0 =>
                  makeLinkOptions(uuid)
                  ->then(options => Interaction.editReply(interaction, ~options, ()))
                  ->then(_ => resolve())
                | false =>
                  let options = {
                    "content": `Your Discord account is linked, but its BrightID verification is not currently valid. Check your verification status in the BrightID app or contact BrightID support.`,
                    "ephemeral": true,
                  }
                  interaction
                  ->Interaction.editReply(~options, ())
                  ->then(
                    _ =>
                      VerifyCommandError(
                        `Commands_Verify: User with contextId: ${uuid} is not unique `,
                      )->reject,
                  )
                }
              }
            },
          )
          ->catch(
            async e =>
              switch e {
              | Exceptions.BrightIdError(error)
                if error.errorNum === 4 && Exceptions.isUnverifiedError(error) =>
                switch await getAppUnusedSponsorships(context) {
                | None =>
                  let _ = await unknownErrorMessage(interaction)
                | Some(available) if available <= BigInt.fromInt(0) =>
                  let _ = await noSponsorshipsMessage(interaction)
                | Some(_) =>
                  let options = await beforeSponsorMessageOptions("before-premium-sponsor", uuid)
                  let _ = await Interaction.editReply(interaction, ~options, ())
                }
              | Exceptions.BrightIdError(error) if Exceptions.isUnverifiedError(error) =>
                await handleUnverifiedGuildMember(error.errorNum, interaction, uuid)
              | _ =>
                let _ = await unknownErrorMessage(interaction)
                raise(e)
              },
          )
        }
      }
    })
  })
  ->catch(reject)
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("verify")
  ->SlashCommandBuilder.setDescription(
    "Sends a BrightID QR code for users to connect with their BrightId",
  )
