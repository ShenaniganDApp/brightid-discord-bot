type bot = Bot(bool)
type user = {bot: bot}

let validateBot = bot => {
  switch bot {
  | Bot(bot) => bot
  }
}