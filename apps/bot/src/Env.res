exception EnvError(string)
@module("find-up") external findUpSync: (string, 'options) => string = "findUpSync"
@module("dotenv") external createEnv: {"path": string} => unit = "config"

@val @scope("process")
external nodeEnv: option<Dict.t<string>> = "env"

let createEnv = () => {
  let path = switch nodeEnv->Option.flatMap(Dict.get(_,"ENV_FILE")) {
  | None => ".env.local"->findUpSync()
  | Some(envFile) => envFile->findUpSync()
  }
  createEnv({"path": path})
}

let env = name =>
  switch nodeEnv->Option.flatMap(Dict.get(_,name)) {
  | Some(value) => Ok(value)
  | None => Error(`Environment variable ${name} is missing`)
  }

let getConfig = () =>
  switch (
    env("DISCORD_API_TOKEN"),
    env("DISCORD_CLIENT_ID"),
    env("UUID_NAMESPACE"),
    env("GIST_ID"),
    env("GITHUB_ACCESS_TOKEN"),
    env("DISCORD_LOG_CHANNEL_ID"),
  ) {
  // Got all vars
  | (
      Ok(discordApiToken),
      Ok(discordClientId),
      Ok(uuidNamespace),
      Ok(gistId),
      Ok(githubAccessToken),
      Ok(discordLogChannelId),
    ) =>
    Ok({
      "discordApiToken": discordApiToken,
      "discordClientId": discordClientId,
      "uuidNamespace": uuidNamespace,
      "gistId": gistId,
      "githubAccessToken": githubAccessToken,
      "discordLogChannelId": discordLogChannelId,
    })
  // Did not get one or more vars, return the first error
  | (Error(_) as err, _, _, _, _, _ )
  | (_, Error(_) as err, _, _, _, _ )
  | (_, _, Error(_) as err, _, _, _ )
  | (_, _, _, Error(_) as err, _, _)
  | (_, _, _, _, Error(_) as err, _ )
  | (_, _, _, _, _, Error(_) as err) => err
  }
