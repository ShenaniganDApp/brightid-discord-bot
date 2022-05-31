open Promise

//@TODO move all top level exceptions to a new file
exception VerificationInfoError(string)
exception FetchVerificationInfoError({error: string, fetching: bool})

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("uuid") external v5: (string, string) => t = "v5"
}

//@TODO I shouldnt have to keep importing this
Env.createEnv()

let config = Env.getConfig()

let uuidNAMESPACE = switch config {
| Ok(config) => config["uuidNamespace"]
| Error(err) => err->VerificationInfoError->raise
}

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

type response = {
  "data": Js.Nullable.t<{
    "unique": Js.Nullable.t<bool>,
    "timestamp": Js.Nullable.t<int>,
    "contextIds": Js.Nullable.t<array<string>>,
  }>,
  "error": Js.Nullable.t<bool>,
  "errorNum": Js.Nullable.t<int>,
  "errorMessage": Js.Nullable.t<string>,
  "code": Js.Nullable.t<int>,
}

@module("node-fetch")
external fetch: (string, 'params) => Promise.t<Response.t<response>> = "default"

let {contextId} = module(Constants)
let {brightIdVerificationEndpoint} = module(Endpoints)

let {notFoundCode, errorCode, canNotBeVerified} = module(Services_ResponseCodes)

let verificationPollingEvery = 3000
let requestTimeout = 60000

type verification = {
  authorExist: bool,
  authorUnique: bool,
  timestamp: int,
  userAddresses: array<string>,
  userVerified: bool,
  fetching: bool,
}

let defaultVerification = {
  authorExist: false,
  authorUnique: false,
  timestamp: 0,
  userAddresses: [],
  userVerified: false,
  fetching: false,
}

let rec fetchVerificationInfo = (~retry=5, id): Promise.t<verification> => {
  let id = id->UUID.v5(uuidNAMESPACE)
  let endpoint = `${brightIdVerificationEndpoint}/${contextId}/${id}?timestamp=seconds`

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
  ->then(res => {
    switch Js.Nullable.toOption(res["data"]) {
    | Some(data) =>
      switch (
        data["unique"]->Js.Nullable.toOption,
        data["timestamp"]->Js.Nullable.toOption,
        data["contextIds"]->Js.Nullable.toOption,
      ) {
      | (Some(unique), Some(timestamp), Some(contextIds)) =>
        {
          authorExist: true,
          authorUnique: unique,
          timestamp: timestamp,
          userAddresses: contextIds,
          userVerified: true,
          fetching: false,
        }->resolve
      | _ =>
        VerificationInfoError("Necessary Verification Info missing after successful fetch ")->reject
      }
    | None =>
      switch (
        res["code"]->Js.Nullable.toOption,
        res["errorMessage"]->Js.Nullable.toOption,
        res["errorNum"]->Js.Nullable.toOption,
      ) {
      | (Some(_), Some(errorMessage), Some(_)) =>
        FetchVerificationInfoError({
          error: errorMessage,
          fetching: false,
        })->reject
      | _ => VerificationInfoError(`No code or errorMessage`)->reject
      }
    }
  })
  ->catch(e => {
    switch e {
    | VerificationInfoError(msg) => Js.Console.error(msg)
    | FetchVerificationInfoError({error}) =>
      Js.Console.error(`Fetch Verification Info Error: ${error}`)
    | JsError(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Js.Console.error(msg)
      | None => Js.Console.error("Must be some non-error value")
      }
    | _ => Js.Console.error("Some unknown error")
    }
    let retry = retry - 1
    switch retry {
    | 0 => defaultVerification->resolve
    | _ => fetchVerificationInfo(~retry, id)
    }
  })
}

let getBrightIdVerification = (member: Discord.GuildMember.t) => {
  let id = member->Discord.GuildMember.getGuildMemberId
  id->fetchVerificationInfo
}
