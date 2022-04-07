type t = Types.userT

@get external getUserBot: t => bool = "bot"
@get external getUserId: t => string = "id"

let validateBot = bot => {
  switch bot {
  | Types.Bot(bot) => bot
  }
}
