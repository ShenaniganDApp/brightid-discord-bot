open Discord
let {brightIdVerificationEndpoint, brightIdSubscriptionEndpoint} = module(Endpoints)

let {context} = module(Shared.Constants)

Env.createEnv()

let envConfig = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let sponsorshipRequested = async (interaction, contextId, sponsorHash) => {
  open MessageEmbed
  let verificationStatusUrl = `${brightIdVerificationEndpoint}/${context}/${contextId}`
  let sponsorshipStatusUrl = `${brightIdSubscriptionEndpoint}/${sponsorHash}`
  let embedFields = {
    [
      {
        name: "__Status__",
        value: "Requested",
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
        value: `**Context ID:** [${contextId}](${verificationStatusUrl} "${verificationStatusUrl}")`,
      },
      {
        name: "__Sponsorship Operation Status__",
        value: `**Request Hash:** [${sponsorHash}](${sponsorshipStatusUrl} "${sponsorshipStatusUrl}")`,
      },
    ]
  }
  let messageEmbed =
    createMessageEmbed()
    ->setColor("#fb8b60")
    ->setTitle("A Sponsorship Has Been Requested")
    ->setURL(verificationStatusUrl)
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

  try {
    let channel =
      await interaction
      ->Interaction.getClient
      ->Client.getChannelManager
      ->ChannelManager.fetch(envConfig["discordLogChannelId"])
    let _ = await channel->Channel.sendWithOptions({"embeds": [messageEmbed]})
  } catch {
  | Exn.Error(obj) =>
    switch Exn.message(obj) {
    | Some(msg) => Console.error2("Failed to create sponsorship request: ", msg)
    | None => Console.error2("Failed to create sponsorship request", obj)
    }
  }
}
