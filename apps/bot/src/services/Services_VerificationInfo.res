open Promise
open NodeFetch
open Shared

//@TODO move all top level exceptions to a new file
exception BrightIdError(BrightId.Error.t)

type verificationInfo =
  VerificationInfo(BrightId.ContextId.t) | BrightIdError(BrightId.Error.t) | JsError(Js.Exn.t)

// let defaultVerification = {
//   open Shared.BrightId.ContextId
//   {
//     unique: false,
//     app: "",
//     context: "Discord",
//     contextIds: [],
//     timestamp: 0,
//   }
// }

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("uuid") external v5: (string, string) => t = "v5"
}

//@TODO I shouldnt have to keep importing this
Env.createEnv()

let config = Env.getConfig()

let config = switch config {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

@module("node-fetch")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "default"

let {context} = module(Constants)
let {brightIdVerificationEndpoint} = module(Endpoints)

let {notFoundCode, errorCode, canNotBeVerified} = module(Services_ResponseCodes)

let verificationPollingEvery = 3000
let requestTimeout = 60000

let rec fetchVerificationInfo = (~retry=5, id): Promise.t<verificationInfo> => {
  let uuid = id->UUID.v5(config["uuidNamespace"])
  let endpoint = `${brightIdVerificationEndpoint}/${context}/${uuid}?timestamp=seconds`

  let params = {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    "timestamp": requestTimeout,
  }
  endpoint
  ->fetch(params)
  ->then(Response.json)
    open Decode.Decode_BrightId
    switch (json->Json.decode(ContextId.data), json->Json.decode(Error.data)) {
    | (_, Ok(error)) => error->BrightIdError->reject
    | (Error(err), _) => err->Json.Decode.DecodeError->reject
    }
  )
  ->catch(e => {
    let retry = retry - 1
    switch retry {
    | 0 =>
      switch e {
      | BrightIdError(error) => BrightIdError(error)->resolve
      | JsError(obj) => JsError(obj)->resolve
      | _ => e->raise
      }

    | _ => fetchVerificationInfo(~retry, id)
    }
  })
}

let getBrightIdVerification = member => {
  let id = member->Discord.GuildMember.getGuildMemberId
  id->fetchVerificationInfo
}
