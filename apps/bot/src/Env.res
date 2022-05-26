exception EnvError(string)
@module("find-up") external findUpSync: (string, 'options) => string = "findUpSync"
@module("dotenv") external createEnv: {"path": string} => unit = "config"

type uuidNamespace = UUIDNamespace(string)
let nodeEnv = Node.Process.process["env"]

let createEnv = () => {
  let path = switch nodeEnv->Js.Dict.get("ENV_FILE") {
  | None => ".env.local"->findUpSync()
  | Some(envFile) => envFile->findUpSync()
  }
  createEnv({"path": path})
}

let env = name =>
  switch Js.Dict.get(nodeEnv, name) {
  | Some(value) => Ok(value)
  | None => Error(`Environment variable ${name} is missing`)
  }

let getConfig = () =>
  switch (env("DISCORD_API_TOKEN"), env("DISCORD_CLIENT_ID"), env("UUID_NAMESPACE")) {
  // Got all vars
  | (Ok(discordApiToken), Ok(discordClientId), Ok(uuidNamespace)) =>
    Ok({
      "discordApiToken": discordApiToken,
      "discordClientId": discordClientId,
      "uuidNamespace": uuidNamespace,
    })
  // Did not get one or more vars, return the first error
  | (Error(_) as err, _, _)
  | (_, Error(_) as err, _)
  | (_, _, Error(_) as err) => err
  }
