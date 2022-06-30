let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

type loaderData = RemixAuth.User.t

let loader: Remix.loaderFunction<loaderData> = ({request, params}): Promise.t<loaderData> => {
  open RemixAuth

  let options = CreateAuthenticateOptions.make(~successRedirect="/", ~failureRedirect="/login", ())
  authenticator->Authenticator.authenticateWithOptions("discord", request, ~options, ())
}
