open Discord
open Promise

exception GuildHandlerError(string)

type brightIdGuildData = {
  name: string,
  role: string,
  inviteLink: Js.Nullable.t<string>,
}

@module("../updateOrReadGist.js")
external readGist: unit => Promise.t<Js.Dict.t<brightIdGuildData>> = "readGist"

let getGuildDataFromGist = (guilds, guildId, message) => {
  let guildData = guilds->Js.Dict.get(guildId)
  switch guildData {
  | None =>
    message->Message.reply("Failed to retreive data for this Discord Guild")->ignore
    GuildHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let generateEmbed = (guilds: array<Guild.t>, message, offset) => {
  open MessageEmbed
  let current = guilds->Belt.Array.slice(~offset, ~len=offset + 10)

  let embed =
    createMessageEmbed()->setTitle(
      `Showing guilds ${(offset + 1)->Js.Int.toString}-${(offset + current->Belt.Array.length)
          ->Js.Int.toString} out of ${guilds->Belt.Array.length->Js.Int.toString}`,
    )

  readGist()->then(guilds => {
    current->Belt.Array.forEach(g => {
      let guildData = guilds->getGuildDataFromGist(g->Guild.getGuildId, message)
      let guildLink = switch guildData.inviteLink->Js.Nullable.toOption {
      | None => "No Invite Link Available"
      | Some(inviteLink) => `**Invite:** ${inviteLink}`
      }

      embed->addField(g->Guild.getGuildName, guildLink, false)->ignore
    })
    embed->resolve
  })
}

let guilds = (member: GuildMember.t, client: Client.t, message: Message.t) => {
  let clientGuildManager = client->Client.getGuildManager
  let unsortedGuilds = clientGuildManager->GuildManager.getCache
  let guilds =
    unsortedGuilds
    ->Collection.sort((a, b) => a->Guild.getMemberCount > b->Guild.getMemberCount ? -1 : 1)
    ->Collection.array
  guilds
  ->generateEmbed(message, 0)
  ->then(embed => message->Message.reply({"embed": embed}))
  ->then(guildsMessage => {
    switch guilds->Belt.Array.length < 10 {
    | true => ()
    | false =>
      // react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
      guildsMessage->Message.react(`➡️`)->ignore
      let collector =
        guildsMessage->ReactionCollector.createReactionCollector(
          // only collect left and right arrow reactions from the message author
          (reaction, user) => {
            let emoji = reaction->Reaction.getReactionEmoji
            let name = emoji->Emoji.getEmojiName
            ([`⬅️`, `➡️`]->Belt.Array.some(arrow => name === arrow) &&
              user->User.getUserId === member->GuildMember.getGuildMemberId)->resolve
          },
          {"time": 60000},
        )
      let currentIndex = 0
      collector->ReactionCollector.on(
        #collect(
          reaction => {
            open Message
            guildsMessage->getMessageReactions->ReactionManager.removeAll->ignore

            let emoji = reaction->Reaction.getReactionEmoji

            let name = emoji->Emoji.getEmojiName
            let currentIndex = name === `⬅️` ? currentIndex - 10 : currentIndex + 10
            guilds->generateEmbed(message, currentIndex)->then(message->Message.edit(_))->ignore
            switch currentIndex {
            | 0 =>
              // react with the left arrow (so that the user can click it)
              guildsMessage->Message.react(`⬅️`)->ignore
            | _ =>
              currentIndex + 10 < guilds->Belt.Array.length
                ? guildsMessage->Message.react(`➡️`)->ignore
                : () //react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
            }
          },
        ),
      )
    }
    message->resolve
  })
  ->catch(e => {
    switch e {
    | GuildHandlerError(msg) => Js.Console.error(msg)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    message->resolve
  })
}
