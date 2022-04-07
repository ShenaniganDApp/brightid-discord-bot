open Types
type t = guildManagerT

@get external getCache: t => Discord_Collection.t<string, guildT> = "cache"
