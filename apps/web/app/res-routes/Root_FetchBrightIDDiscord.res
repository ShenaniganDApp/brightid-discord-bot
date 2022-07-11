type loaderData = {user: Js.Nullable.t<RemixAuth.User.t>, verificationCount: Js.Nullable.t<float>}

let brightIdVerificationEndpoint = "https://app.brightid.org/node/v5/verifications/Discord"

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Promise
  open Webapi.Fetch

  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    let init = RequestInit.make(~method_=Get, ())

    brightIdVerificationEndpoint
    ->Request.makeWithInit(init)
    ->fetchWithRequest
    ->then(res => res->Response.json)
    ->then(json => {
      let data =
        json->Js.Json.decodeObject->Belt.Option.getUnsafe->Js.Dict.get("data")->Belt.Option.getExn
      let verificationCount =
        data
        ->Js.Json.decodeObject
        ->Belt.Option.getUnsafe
        ->Js.Dict.get("count")
        ->Belt.Option.flatMap(Js.Json.decodeNumber)
        ->Js.Nullable.fromOption

      {user: user, verificationCount: verificationCount}->resolve
    })
  })
}
