open Types
type t = reactionT

@get external getReactionEmoji: t => emojiT = "emoji"
@get external getReactionMessage: t => messageT = "message"
