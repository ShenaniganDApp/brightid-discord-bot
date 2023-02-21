type loaderData = RemixAuth.User.t

let loader: Remix.loaderFunction<loaderData> = ({request}): promise<loaderData> => {
  open RemixAuth

  let options = CreateAuthenticateOptions.make(~successRedirect="/", ~failureRedirect="/login", ())
  AuthServer.authenticator->Authenticator.authenticateWithOptions("discord", request, ~options)
}
