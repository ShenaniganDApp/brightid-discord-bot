open Types
type loaderData = {
  user: Js.Nullable.t<RemixAuth.User.t>,
  verificationCount: Js.Nullable.t<float>,
  verifyStatus: verifyStatus,
}

let context = "Discord"

let brightIdVerificationEndpoint = "https://app.brightid.org/node/v5/verifications/Discord"

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Promise
  open Webapi.Fetch

  let uuidNamespace = Remix.process["env"]["UUID_NAMESPACE"]

  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None =>
      {
        user: Js.Nullable.null,
        verificationCount: Js.Nullable.null,
        verifyStatus: NotVerified,
      }->resolve
    | Some(existingUser) => {
        let init = RequestInit.make(~method_=Get, ())

        brightIdVerificationEndpoint
        ->Request.makeWithInit(init)
        ->fetchWithRequest
        ->then(res => res->Response.json)
        ->then(json => {
          let data =
            json
            ->Js.Json.decodeObject
            ->Belt.Option.getUnsafe
            ->Js.Dict.get("data")
            ->Belt.Option.getExn
          let verificationCount =
            data
            ->Js.Json.decodeObject
            ->Belt.Option.getUnsafe
            ->Js.Dict.get("count")
            ->Belt.Option.flatMap(Js.Json.decodeNumber)
            ->Js.Nullable.fromOption

          let userId = existingUser->RemixAuth.User.getProfile->RemixAuth.User.getId
          let contextId = userId->UUID.v5(uuidNamespace)
          BrightId.verifyContextId(~context, ~contextId, ())->then(json => {
            let unique =
              json
              ->Js.Json.decodeObject
              ->Belt.Option.getUnsafe
              ->Js.Dict.get("unique")
              ->Belt.Option.flatMap(Js.Json.decodeBoolean)

            let verifyStatus = switch unique {
            | Some(_) => Unique
            | None => {
                let data =
                  json
                  ->Js.Json.decodeObject
                  ->Belt.Option.getUnsafe
                  ->Js.Dict.get("data")
                  ->Belt.Option.getExn

                let errorNum =
                  data
                  ->Js.Json.decodeObject
                  ->Belt.Option.getUnsafe
                  ->Js.Dict.get("errorNum")
                  ->Belt.Option.flatMap(Js.Json.decodeNumber)
                switch errorNum {
                | Some(2.) => NotLinked

                | Some(3.) => NotVerified

                | Some(4.) => NotSponsored

                | _ => Unknown
                }
              }
            }
            {user: user, verificationCount: verificationCount, verifyStatus: verifyStatus}->resolve
          })
        })
      }
    }
  })
}
