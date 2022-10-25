open Types
type loaderData = {
  user: Js.Nullable.t<RemixAuth.User.t>,
  verificationCount: Js.Nullable.t<float>,
  unusedSponsorships: Js.Nullable.t<float>,
  assignedSponsorships: Js.Nullable.t<float>,
  verifyStatus: verifyStatus,
}

let context = "Discord"

let brightIdVerificationEndpoint = "https://app.brightid.org/node/v5/verifications/Discord"
let brightIdAppEndpoint = "https://app.brightid.org/node/v5/apps/Discord"

let loader: Remix.loaderFunction<loaderData> = async ({request}) => {
  open Webapi.Fetch

  let uuidNamespace = Remix.process["env"]["UUID_NAMESPACE"]
  let init = RequestInit.make(~method_=Get, ())

  // fetch Verification Count
  let req = Request.makeWithInit(brightIdVerificationEndpoint, init)
  let res = await fetchWithRequest(req)
  let json = await Response.json(res)
  let data =
    json->Js.Json.decodeObject->Belt.Option.getUnsafe->Js.Dict.get("data")->Belt.Option.getExn

  let verificationCount =
    data
    ->Js.Json.decodeObject
    ->Belt.Option.getUnsafe
    ->Js.Dict.get("count")
    ->Belt.Option.flatMap(Js.Json.decodeNumber)
    ->Js.Nullable.fromOption

  // fetch Sponsorship Data
  let req = Request.makeWithInit(brightIdAppEndpoint, init)
  let res = await fetchWithRequest(req)
  let json = await Response.json(res)
  let data =
    json->Js.Json.decodeObject->Belt.Option.getUnsafe->Js.Dict.get("data")->Belt.Option.getExn

  let unusedSponsorships =
    data
    ->Js.Json.decodeObject
    ->Belt.Option.getUnsafe
    ->Js.Dict.get("unusedSponsorships")
    ->Belt.Option.flatMap(Js.Json.decodeNumber)
    ->Js.Nullable.fromOption

  let assignedSponsorships =
    data
    ->Js.Json.decodeObject
    ->Belt.Option.getUnsafe
    ->Js.Dict.get("assignedSponsorships")
    ->Belt.Option.flatMap(Js.Json.decodeNumber)
    ->Js.Nullable.fromOption

  let user = await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request)

  switch user->Js.Nullable.toOption {
  | None => {
      user: Js.Nullable.null,
      verificationCount,
      unusedSponsorships,
      assignedSponsorships,
      verifyStatus: NotVerified,
    }
  | Some(existingUser) => {
      let userId = existingUser->RemixAuth.User.getProfile->RemixAuth.User.getId
      let contextId = userId->UUID.v5(uuidNamespace)
      let json = await BrightId.verifyContextId(~context, ~contextId, ())

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
      {
        user,
        unusedSponsorships,
        assignedSponsorships,
        verificationCount,
        verifyStatus,
      }
    }
  }
}
