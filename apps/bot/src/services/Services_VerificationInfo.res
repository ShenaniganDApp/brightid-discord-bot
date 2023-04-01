open Promise
open NodeFetch
open Shared

type verificationInfo = VerificationInfo(BrightId.ContextId.t)

module UUID = {
  type t = string
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
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "default"

let sleep: int => promise<unit> = _ms => %raw(` new Promise((resolve) => setTimeout(resolve, _ms))`)

let {context} = module(Constants)
let {brightIdVerificationEndpoint, nodes} = module(Endpoints)

let requestTimeout = 60000

let rec fetchVerificationInfo = (~retry=5, id) => {
  let uuid = id->UUID.v5(config["uuidNamespace"])
  FetchTools.fetchWithFallback(~relativeUrl=`/verifications/${context}/${uuid}`, nodes[0], nodes)
  ->then(maybeRes =>
    switch maybeRes {
    | None => reject(FetchTools.NoRes)
    | Some(res) => Response.json(res)
    }
  )
  ->then(json => {
    open Decode

    switch (
      json->Json.decode(Decode_BrightId.ContextId.data),
      json->Json.decode(Decode_BrightId.Error.data),
    ) {
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
      | 0 => e->raise
      | _ => sleep(3000)->then(_ => fetchVerificationInfo(~retry, id))
      }
    }
  })
}

let getBrightIdVerification = member => {
  let id = member->Discord.GuildMember.getGuildMemberId
  id->fetchVerificationInfo
}
