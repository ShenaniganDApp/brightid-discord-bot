type bot = Bot(bool)
type t
type user = {bot: bot}

@get external getUserBot: t => bool = "bot"

let validateBot = bot => {
  switch bot {
  | Bot(bot) => bot
  }
}

let make = user => {
  let bot = getUserBot(user)
  {bot: Bot(bot)}
}
