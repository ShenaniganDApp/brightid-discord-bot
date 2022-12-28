open Promise
open NodeFetch
open Shared

type verificationInfo = VerificationInfo(BrightId.ContextId.t)

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
  ->then(json => {
    open Decode.Decode_BrightId

    switch (json->Json.decode(ContextId.data), json->Json.decode(Error.data)) {
    | (Ok({data}), _) => VerificationInfo(data)->resolve
    | (_, Ok(error)) => error->Exceptions.BrightIdError->reject
    | (Error(err), _) => err->Json.Decode.DecodeError->reject
    }
  })
  ->catch(e => {
    switch e {
    | Exceptions.BrightIdError(_) => e->raise
    | _ =>
      let retry = retry - 1
      switch retry {
      | 0 =>
        switch e {
        | _ => e->raise
        }

      | _ => fetchVerificationInfo(~retry, id)
      }
    }
  })
}

let getBrightIdVerification = member => {
  let id = member->Discord.GuildMember.getGuildMemberId
  id->fetchVerificationInfo
}
