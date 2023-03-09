open Discord
open Promise

exception GuildHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
  inviteLink: Nullable.t<string>,
}

@module("../updateOrReadGist.mjs")
external readGist: unit => promise<Dict.t<brightIdGuildData>> = "readGist"

let getGuildDataFromGist = (guilds, guildId, interaction) => {
  let guildData = guilds->Dict.get(guildId)
  switch guildData {
  | None =>
    interaction
    ->Interaction.editReply(
      ~options={"content": "Failed to retrieve data from this server from Bright ID"},
      (),
    )
    ->ignore
    GuildHandlerError(`Commands_Guild: The guild id:${guildId} did not return any data`)->raise
  | Some(guildData) => guildData
  }
}

let generateEmbed = (guilds, interaction, start) => {
  open MessageEmbed
  let current = guilds->Array.slice(~start, ~end=start + 10)
  let embedTitle = `Showing guilds ${(start + 1)->Int.toString}-${(start + current->Array.length)
      ->Int.toString} out of ${guilds->Array.length->Int.toString}`
  let embed = createMessageEmbed()->setTitle(embedTitle)

  readGist()->then(guilds => {
    current->Array.forEach(g => {
      let guildData = guilds->getGuildDataFromGist(g->Guild.getGuildId, interaction)
      let guildLink = switch guildData.inviteLink->Nullable.toOption {
      | None => "No Invite Link Available"
      | Some(inviteLink) => `**Invite:** ${inviteLink}`
      }

      embed->addField(g->Guild.getGuildName, guildLink, false)->ignore
    })
    embed->resolve
  })
}

let execute = interaction => {
  let client = interaction->Interaction.getClient
  let clientGuildManager = client->Client.getGuildManager
  let member = interaction->Interaction.getGuildMember
  let unsortedGuilds = clientGuildManager->GuildManager.getCache
  let guilds =
    unsortedGuilds
    ->Collection.sort((a, b) => a->Guild.getMemberCount > b->Guild.getMemberCount ? -1 : 1)
    ->Collection.toJSON

  interaction
  ->Interaction.deferReply()
  ->then(_ => {
    guilds
    ->generateEmbed(interaction, 0)
    ->then(embed => {
      interaction->Interaction.editReply(~options={"embeds": [embed]}, ())
    })
    ->then(guildsMessage => {
      switch guilds->Array.length < 1 {
      | true => ()
      | false => {
          // react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
          guildsMessage->Message.react(`➡️`)->ignore
          let filter = (reaction, user) => {
            Console.log2("reaction: ", reaction)
            let emoji = reaction->Reaction.getReactionEmoji
            Console.log2("emoji: ", emoji)
            let name = emoji->Emoji.getEmojiName
            ([`⬅️`, `➡️`]->Array.some(arrow => name === arrow) &&
              user->User.getUserId === member->GuildMember.getGuildMemberId)->resolve
          }
          let collector = guildsMessage->ReactionCollector.createReactionCollector({
            "filter": filter,
            "time": 60000,
          })

          let currentIndex = 0
          collector->ReactionCollector.on(
            #collect(
              reaction => {
                Console.log2("reaction: ", reaction)
                open Message
                guildsMessage->getMessageReactions->ReactionManager.removeAll->ignore

                let emoji = reaction->Reaction.getReactionEmoji

                let name = emoji->Emoji.getEmojiName
                let currentIndex = name === `⬅️` ? currentIndex - 10 : currentIndex + 10
                guilds
                ->generateEmbed(interaction, currentIndex)
                ->then(
                  embed => interaction->Interaction.editReply(~options={"embeds": [embed]}, ()),
                )
                ->ignore
                switch currentIndex {
                | 0 =>
                  // react with the left arrow (so that the user can click it)
                  guildsMessage->Message.react(`⬅️`)->ignore
                | _ =>
                  currentIndex + 10 < guilds->Array.length
                    ? guildsMessage->Message.react(`➡️`)->ignore
                    : () //react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
                }
              },
            ),
          )
        }
      }
      resolve()
    })
    ->catch(e => {
      switch e {
      | GuildHandlerError(msg) => Console.error(msg)
      | Exn.Error(obj) =>
        switch Exn.message(obj) {
        | Some(msg) => Console.error(msg)
        | None => Console.error("Must be some non-error value")
        }
      | _ => Console.error("Some unknown error")
      }
      resolve()
    })
  })
}

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("guilds")
  ->SlashCommandBuilder.setDescription("See a list of Discord Servers using the BrightID bot")
