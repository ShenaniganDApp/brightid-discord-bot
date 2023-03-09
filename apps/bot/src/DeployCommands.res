open Promise
open Discord

exception DeployCommandsError(string)
module Rest = {
  type t
  @module("@discordjs/rest") @new external make: {"version": int} => t = "REST"
  @send external setToken: (t, string) => t = "setToken"
  @send
  external put: (t, string, {"body": array<SlashCommandBuilder.json>}) => promise<unit> = "put"
  @send
  external delete: (t, string) => promise<unit> = "delete"
}

module Routes = {
  type t
  @module("discord-api-types/v9") @scope("Routes")
  external applicationCommands: (~clientId: string) => string = "applicationCommands"
  @module("discord-api-types/v9") @scope("Routes")
  external applicationCommand: (~clientId: string, ~commandId: string) => string =
    "applicationCommand"
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
let inviteCommand = Commands_Invite.data->SlashCommandBuilder.toJSON

let commands = [helpCommand, verifyCommand, inviteCommand]

let rest = Rest.make({"version": 9})->Rest.setToken(token)

rest
->Rest.put(Routes.applicationCommands(~clientId), {"body": commands})
->thenResolve(() => Console.log("Successfully registered application commands."))
->catch(e => {
  switch e {
  | DeployCommandsError(msg) => Console.error("Deploy Commands Error:" ++ msg)
  | Exn.Error(obj) =>
    switch Exn.message(obj) {
    | Some(msg) => Console.error("Deploy Commands Error: " ++ msg)
    | None => Console.error("Must be some non-error value")
    }
  | _ => Console.error("Some unknown error")
  }
  resolve()
})
->ignore

// delete guilds command
// rest
// ->Rest.delete(Routes.applicationCommand(~clientId, ~commandId="981007485634748511"))
// ->then(_ => {
//   Console.log("Successfully deleted guilds command.")->resolve
// })
// ->catch(e => {
//   Console.log(e)
//   resolve()
// })
// ->ignore
