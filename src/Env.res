@module("dotenv") external createEnv: unit => unit = "config"
type uuidNamespace = UUIDNamespace(string)
let nodeEnv = Node.Process.process["env"]

let env = name =>
  switch Js.Dict.get(nodeEnv, name) {
  | Some(value) => Ok(value)
  | None => Error(`Environment variable ${name} is missing`)
  }

let getConfig = () =>
  switch (env("DISCORD_API_TOKEN"), env("UUID_NAMESPACE")) {
  // Got all vars
  | (Ok(discordApiToken), Ok(uuidNamespace)) =>
    Ok({
      "discordApiToken": discordApiToken,
      "uuidNamespace": uuidNamespace,
    })
  // Did not get one or more vars, return the first error
  | (Error(_) as err, _)
  | (_, Error(_) as err) => err
  }
