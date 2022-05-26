exception RequestHandlerError({date: float, message: string})

let commands = ["!verify", "!me", "!guilds", "!invite", "!role", "!brightid"]

let detectHandler = message => {
  let content = message->Discord.Message.getMessageContent
  if !Js.String2.includes(content, "!") {
    ()
  }
  let command = Js.String2.split(content, " ")[0]

  let receivedHandler = Handlers.handlers->Belt.Map.String.get(command)

  if !Js.Array2.includes(commands, command) {
    Js.Console.error(
      RequestHandlerError({
        date: Js.Date.now(),
        message: "Command not found",
      }),
    )
  }
  receivedHandler
}
