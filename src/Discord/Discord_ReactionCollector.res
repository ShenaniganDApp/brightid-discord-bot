open Types

type t = reactionCollectorT

@send
external createReactionCollector: (
  messageT,
  (reaction, user) => Js.Promise.t<bool>,
  'options,
) => t = "createReactionCollector"

@send
external on: (
  t,
  @string
  [
    | #collect(reaction => unit)
  ],
) => unit = "on"
