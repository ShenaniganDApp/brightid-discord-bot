open Types
type loaderData = {
  user: Nullable.t<RemixAuth.User.t>,
  verificationCount: Nullable.t<float>,
  unusedSponsorships: Nullable.t<float>,
  assignedSponsorships: Nullable.t<float>,
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
  let data = json->JSON.Decode.object->Option.getUnsafe->Dict.get("data")->Option.getExn

  let verificationCount =
    data
    ->JSON.Decode.object
    ->Option.getUnsafe
    ->Dict.get("count")
    ->Option.flatMap(JSON.Decode.float)
    ->Nullable.fromOption

  // fetch Sponsorship Data
  let req = Request.makeWithInit(brightIdAppEndpoint, init)
  let res = await fetchWithRequest(req)
  let json = await Response.json(res)
  let data = json->JSON.Decode.object->Option.getUnsafe->Dict.get("data")->Option.getExn

  let unusedSponsorships =
    data
    ->JSON.Decode.object
    ->Option.getUnsafe
    ->Dict.get("unusedSponsorships")
    ->Option.flatMap(JSON.Decode.float)
    ->Nullable.fromOption

  let assignedSponsorships =
    data
    ->JSON.Decode.object
    ->Option.getUnsafe
    ->Dict.get("assignedSponsorships")
    ->Option.flatMap(JSON.Decode.float)
    ->Nullable.fromOption

  let user = await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request)

  switch user->Nullable.toOption {
  | None => {
      user: Nullable.null,
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
        ->JSON.Decode.object
        ->Option.getUnsafe
        ->Dict.get("unique")
        ->Option.flatMap(JSON.Decode.bool)

      let verifyStatus = switch unique {
      | Some(_) => Unique
      | None => {
          let data = json->JSON.Decode.object->Option.getUnsafe->Dict.get("data")->Option.getExn

          let errorNum =
            data
            ->JSON.Decode.object
            ->Option.getUnsafe
            ->Dict.get("errorNum")
            ->Option.flatMap(JSON.Decode.float)
          switch errorNum {
          | Some(2.) => NotLinked

          | Some(3.) => NotVerified

          | Some(4.) => NotSponsored

          | _ => Types.Unknown
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
