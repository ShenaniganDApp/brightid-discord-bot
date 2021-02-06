const fs = require('fs')
const QRCode = require('qrcode')
const UUID = require('uuid')
const Discord = require('discord.js')
const Canvas = require('canvas')
const {
  BRIGHT_ID_APP_DEEPLINK,
  BRIGHTID_LINK_VERIFICATION_ENDPOINT,
} = require('../endpoints')

const { QRCodeError } = require('../error-utils')
const fetch = require('node-fetch')
const { readGist } = require('../updateOrReadGist')

module.exports = async function verify(member, _, message) {
  const ID = UUID.v5(member.id, process.env.UUID_NAMESPACE)
  const guilds = await readGist()
  const guild = guilds[message.guild.id]

  const role = member.guild.roles.cache.find(r => r.name === guild.role)

  const deepLink = `${BRIGHT_ID_APP_DEEPLINK}/${ID}`
  const verifyUrl = `${BRIGHTID_LINK_VERIFICATION_ENDPOINT}/${ID}`
  const generateQR = async uri => {
    try {
      const rawResponse = await fetch(
        'https://app.brightid.org/node/v5/verifications/Discord',
        {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          timeout: 60000,
        },
      )
      const {
        data: { contextIds },
      } = await rawResponse.json()

      if (contextIds.includes(ID)) {
        member.roles.add(role)
        member.send(
          `I recognize you! You're now a verified user in ${member.guild.name}`,
        )
        return
      }

      const canvas = Canvas.createCanvas(700, 250)
      await QRCode.toCanvas(canvas, uri)
      const attachment = new Discord.MessageAttachment(
        canvas.toBuffer(),
        'qrcode.png',
      )

      const embed = new Discord.MessageEmbed()
        .setColor('#fb8b60')
        .setTitle('How To Get Verified with Bright ID')
        .setURL('https://www.brightid.org/')
        .setAuthor(
          'BrightID Bot',
          'https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png',
          'https://www.brightid.org/',
        )
        .setDescription(
          'Here is a step-by-step guide to help you get verified with BrightID.',
        )
        .setThumbnail(
          'https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png',
        )
        .addFields(
          {
            name: '1. Get Verified in the BrightID app',
            value:
              'Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet "https://www.brightid.org/meet") that are hosted in the BrightID server and require members join a voice/video call.',
          },
          {
            name: '2. Link to a Sponsored App (like 1hive, gitcoin, etc)',
            value:
              'You can link to these [sponsored apps](https://apps.brightid.org/ "https://apps.brightid.org/") once you are verified within the app.',
          },
          {
            name: '3. Type the `!verify` command in any public channel',
            value:
              'You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH "https://discord.gg/gH6qAUH").',
          },
          {
            name: `4. Scan the DM'd QR Code`,
            value: `Open the BrightID app and scan the QR code. Mobile users can click [this link](${verifyUrl}).`,
          },
          {
            name: '5. Type the `!me` command in any public channel',
            value:
              'Once you have scanned the QR code you can return to any public channel and type the `!me` command which should grant you the orange verified role.',
          },
        )
        .setTimestamp()
        .setFooter(
          'Bot made by the Shenanigan team',
          'https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png',
        )
      member.send({ embed, files: [attachment] })
    } catch (err) {
      console.log('err: ', err)
      throw new QRCodeError(`QRCode could not be generated from ${uri}`)
    }
  }
  await generateQR(deepLink)
}
