open Promise
open Discord

exception DeployCommandsError(string)
module Rest = {
  type t
  @module("@discordjs/rest") @new external make: {"version": int} => t = "REST"
  @send external setToken: (t, string) => t = "setToken"
  @send
  external put: (t, string, {"body": array<SlashCommandBuilder.json>}) => Js.Promise.t<unit> = "put"
}

module Routes = {
  type t
  @module("discord-api-types/v9") @scope("Routes")
  external applicationCommands: (~clientId: string) => string = "applicationCommands"
}

Env.createEnv()

let envConfig = Env.getConfig()
let envConfig = switch envConfig {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let token = envConfig["discordApiToken"]
let clientId = envConfig["discordClientId"]

// @TODO: Shouldn't need to hardcode each command, instaed loop through files
let helpCommand = Commands_Help.data->SlashCommandBuilder.toJSON
let verifyCommand = Commands_Verify.data->SlashCommandBuilder.toJSON
let roleCommand = Commands_Role.data->SlashCommandBuilder.toJSON

let commands = [helpCommand, verifyCommand, roleCommand]

let rest = Rest.make({"version": 9})->Rest.setToken(token)

let applicationGuildCommands = Routes.applicationCommands(~clientId)

rest
->Rest.put(applicationGuildCommands, {"body": commands})
->thenResolve(() => Js.log("Successfully registered application commands."))
->catch(e => {
  switch e {
  | DeployCommandsError(msg) => Js.Console.error("Deploy Commands Error:" ++ msg)
  | JsError(obj) =>
    switch Js.Exn.message(obj) {
    | Some(msg) => Js.Console.error("Deploy Commands Error: " ++ msg)
    | None => Js.Console.error("Must be some non-error value")
    }
  | _ => Js.Console.error("Some unknown error")
  }
  resolve()
})
->ignore
