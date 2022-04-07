type t

type embedFieldData = {name: string, value: string}

@module("discord.js") @new external createMessageEmbed: unit => t = "MessageEmbed"
@send external setColor: (t, string) => t = "setColor"
@send external setTitle: (t, string) => t = "setTitle"
@send external setURL: (t, string) => t = "setURL"
@send external setAuthor: (t, string, string, string) => t = "setAuthor"
@send external setDescription: (t, string) => t = "setDescription"
@send external setThumbnail: (t, string) => t = "setThumbnail"
@send external addField: (t, string, string, bool) => t = "addField"
@send external addFields: (t, array<embedFieldData>) => t = "addFields"
@send external setTimestamp: t => t = "setTimestamp"
@send external setFooter: (t, string, string) => t = "setFooter"
