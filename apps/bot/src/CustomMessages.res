open Discord
let {brightIdVerificationEndpoint, brightIdSubscriptionEndpoint} = module(Endpoints)

let {context} = module(Shared.Constants)

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let verificationStatusUrl = contextId => `${brightIdVerificationEndpoint}/${context}/${contextId}`
let sponsorshipStatusUrl = sponsorHash => `${brightIdSubscriptionEndpoint}/${sponsorHash}`

module Status = {
  type t =
    | Requested
    | Successful
    | Failed
    | Error(string)

  let toString = status =>
    switch status {
    | Requested => "Requested"
    | Successful => "Successful"
    | Failed => "Failed"
    | Error(msg) => `Error: ${msg}`
    }
}

let sponsorshipRequestedMessage = (
  interaction,
  ~status=Status.Requested,
  contextId,
  maybeSponsorHash,
) => {
  open MessageEmbed
  let nowInSeconds = Math.round(Date.now() /. 1000.)
  let fifteenMinutesAfter = 15. *. 60. +. nowInSeconds
  let embedFields = {
    [
      {
        name: "__Status__",
        value: Status.toString(status),
      },
      {
        name: "__Server__",
        value: `**Server Name:** ${interaction
          ->Interaction.getGuild
          ->Guild.getGuildName}\n **Server ID:** ${interaction
          ->Interaction.getGuild
          ->Guild.getGuildId}`,
      },
      {
        name: "__Bright ID Verification Status__",
        value: `[${contextId}](${verificationStatusUrl(contextId)} )`,
      },
      {
        name: "__Sponsorship Operation Status__",
        value: `[${maybeSponsorHash->Option.getUnsafe}](${sponsorshipStatusUrl(
            maybeSponsorHash->Option.getUnsafe,
          )} )`,
      },
      {
        name: "__Timeout:__",
        value: `<t:${fifteenMinutesAfter->Float.toString}:R>`,
      },
    ]
  }
  let messageEmbed =
    createMessageEmbed()
    ->setColor("#fb8b60")
    ->setTitle("A Sponsorship Has Been Requested")
    ->setURL(verificationStatusUrl(contextId))
    ->setAuthor(
      "BrightID Bot",
      "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
      "https://www.brightid.org/",
    )
    ->setDescription(
      `A member of ${interaction
        ->Interaction.getGuild
        ->Guild.getGuildName} is attempting to get sponsored`,
    )
    ->setThumbnail(
      "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
    )
    ->addFields(embedFields)
    ->setTimestamp

  {"embeds": [messageEmbed]}
}

let editSponsorMessageContent = (message, interaction, ~status, contextId, maybeSponsorHash) => {
  open MessageEmbed
  let embedFields = {
    [
      {
        name: "__Status__",
        value: Status.toString(status),
      },
      {
        name: "__Server__",
        value: `**Server Name:** ${interaction
          ->Interaction.getGuild
          ->Guild.getGuildName}\n **Server ID:** ${message
          ->Message.getMessageGuild
          ->Guild.getGuildId}`,
      },
      {
        name: "__Bright ID Verification Status__",
        value: `[${contextId}](${verificationStatusUrl(contextId)})`,
      },
      {
        name: "__Sponsorship Operation Status__",
        value: `[${maybeSponsorHash->Option.getUnsafe}](${sponsorshipStatusUrl(
            maybeSponsorHash->Option.getUnsafe,
          )} )`,
      },
    ]
  }
  let messageEmbed =
    createMessageEmbed()
    ->setColor("#fb8b60")
    ->setTitle("A Sponsorship Has Been Requested")
    ->setURL(verificationStatusUrl(contextId))
    ->setAuthor(
      "BrightID Bot",
      "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
      "https://www.brightid.org/",
    )
    ->setDescription(
      `A member of ${interaction
        ->Interaction.getGuild
        ->Guild.getGuildName} is attempting to get sponsored`,
    )
    ->setThumbnail(
      "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png",
    )
    ->addFields(embedFields)
    ->setTimestamp

  {"embeds": [messageEmbed]}
}

let sponsorshipRequested = async (interaction, contextId, sponsorHash) => {
  try {
    let channel =
      await interaction
      ->Interaction.getClient
      ->Client.getChannelManager
      ->ChannelManager.fetch(envConfig["discordLogChannelId"])
    let messageContent = sponsorshipRequestedMessage(interaction, contextId, sponsorHash)
    Some(await channel->Channel.sendWithOptions(messageContent))
  } catch {
  | Exn.Error(obj) =>
    switch Exn.message(obj) {
    | Some(msg) =>
      Console.error2("Failed to create sponsorship request: ", msg)
      None
    | None =>
      Console.error2("Failed to create sponsorship request", obj)
      None
    }
  }
}

let editSponsorshipMessage = async (message, interaction, status, contextId, maybeSponsorHash) => {
  try {
    let messageContent = editSponsorMessageContent(
      message,
      interaction,
      ~status,
      contextId,
      maybeSponsorHash,
    )
    Some(await message->Message.edit(messageContent))
  } catch {
  | Exn.Error(obj) =>
    switch Exn.message(obj) {
    | Some(msg) =>
      Console.error2("Failed to edit sponsorship request: ", msg)
      None
    | None =>
      Console.error2("Failed to edit sponsorship request", obj)
      None
    }
  }
}
