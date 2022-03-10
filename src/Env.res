@module("dotenv") external createEnv: unit => unit = "config"

type discordToken = DiscordToken(string)

let nodeEnv = Node.Process.process["env"]

let env = name =>
  switch Js.Dict.get(nodeEnv, name) {
  | Some(value) => Ok(value)
  | None => Error(`Environment variable ${name} is missing`)
  }

let getConfig = () =>
  switch env("DISCORD_API_TOKEN") {
  | Ok(discordApiToken) => {
      Ok({DiscordToken(discordApiToken)})
    }
  // Did not get one or more vars, return the first error
  | Error(_) as err => err
  }
