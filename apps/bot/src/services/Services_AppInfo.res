open Promise
open NodeFetch
open Shared

let {context} = module(Constants)

let {brightIdAppsEndpoint} = module(Endpoints)
//@TODO move all top level exceptions to a new file
exception BrightIdError(BrightId.Error.t)

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("uuid") external v5: (string, string) => t = "v5"
}

Env.createEnv()

let config = Env.getConfig()

let config = switch config {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

@module("node-fetch")
external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "default"

let verificationPollingEvery = 3000
let requestTimeout = 60000

let rec fetchAppInformation = (~retry=5, context): Promise.t<BrightId.App.t> => {
  let endpoint = `${brightIdAppsEndpoint}/${context}`

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
    switch (json->Json.decode(App.data), json->Json.decode(Error.data)) {
    | (Ok({data}), _) => data->resolve
    | (_, Ok(error)) => error->BrightIdError->reject
    | (Error(err), _) => err->Json.Decode.DecodeError->reject
    }
  })
  ->catch(e => {
    let retry = retry - 1
    switch retry {
    | 0 =>
      switch e {
      | exception BrightIdError(error) => BrightIdError(error)->reject
      | exception JsError(obj) => JsError(obj)->reject
      | _ => e->raise
      }

    | _ => fetchAppInformation(~retry, context)
    }
  })
}

let getAppInfo = context => {
  fetchAppInformation(context)
}
