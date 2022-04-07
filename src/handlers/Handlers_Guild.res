open Types
open Variants
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
    message
    ->Discord_Message.reply(Content("Failed to retreive data for this Discord Guild"))
    ->ignore
    GuildHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let generateEmbed = (guilds: array<guild>, message, offset) => {
  open Discord_MessageEmbed
  let current = guilds->Belt.Array.slice(~offset, ~len=offset + 10)

  let embed =
    createMessageEmbed()->setTitle(
      `Showing guilds ${(offset + 1)->Js.Int.toString}-${(offset + current->Belt.Array.length)
          ->Js.Int.toString} out of ${guilds->Belt.Array.length->Js.Int.toString}`,
    )

  readGist()->then(guilds => {
    current->Belt.Array.forEach(g => {
      let guildData = getGuildDataFromGist(
        guilds,
        g.id->Discord_Snowflake.validateSnowflake,
        message,
      )
      let guildLink = switch guildData.inviteLink->Js.Nullable.toOption {
      | None => "No Invite Link Available"
      | Some(inviteLink) => `**Invite:** ${inviteLink}`
      }

      embed->addField(g.name->Discord_Guild.validateGuildName, guildLink, false)->ignore
    })
    embed->resolve
  })
}

let guilds = (member: guildMember, client: client, message: message) => {
  let clientGuildManager = client.guilds->wrapGuildManager
  let unsortedGuilds = clientGuildManager.cache
  let guilds =
    unsortedGuilds
    ->Belt.Map.valuesToArray
    ->Belt.Array.map(wrapGuild)
    ->Belt.SortArray.stableSortBy((a, b) => a.memberCount > b.memberCount ? -1 : 1)
  guilds
  ->generateEmbed(message, 0)
  ->then(embed => message.t->Discord_Message._reply({"embed": embed}))
  ->then(guildsMessage => {
    switch guilds->Belt.Array.length < 10 {
    | true => ()
    | false =>
      // react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
      guildsMessage->Discord_Message._react(`➡️`)->ignore
      let collector =
        guildsMessage->Discord_ReactionCollector.createReactionCollector(
          // only collect left and right arrow reactions from the message author
          (reaction, user) => {
            let emoji = reaction.emoji->wrapEmoji
            let name = emoji.name->Discord_Message.validateEmojiName
            ([`⬅️`, `➡️`]->Belt.Array.some(arrow => name === arrow) &&
              user.id === member.id)->resolve
          },
          {"time": 60000},
        )
      let currentIndex = 0
      collector->Discord_ReactionCollector.on(
        #collect(
          reaction => {
            open Discord_Message
            guildsMessage->getMessageReactions->Discord_ReactionManager.removeAll->ignore

            let emoji = reaction.emoji->wrapEmoji

            let name = emoji.name->validateEmojiName
            let currentIndex = name === `⬅️` ? currentIndex - 10 : currentIndex + 10
            guilds->generateEmbed(message, currentIndex)->then(message.t->_edit(_))->ignore
            switch currentIndex {
            | 0 =>
              // react with the left arrow (so that the user can click it)
              guildsMessage->_react(`⬅️`)->ignore
            | _ =>
              currentIndex + 10 < guilds->Belt.Array.length
                ? guildsMessage->_react(`➡️`)->ignore
                : () //react with the right arrow (so that the user can click it) (left arrow isn't needed because it is the start)
            }
          },
        ),
      )
    }
    message.t->resolve
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
    resolve(message.t)
  })
}
