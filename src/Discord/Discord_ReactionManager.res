open Types
type t = reactionManagerT

@send external removeAll: t => Js.Promise.t<messageT> = "removeAll"
