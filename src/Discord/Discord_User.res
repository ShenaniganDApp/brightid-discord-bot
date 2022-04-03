type t = Types.userT

@get external getUserBot: t => bool = "bot"

let validateBot = bot => {
  switch bot {
  | Types.Bot(bot) => bot
  }
}
