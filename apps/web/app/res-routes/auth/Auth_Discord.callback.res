type loaderData = RemixAuth.User.t

let loader: Remix.loaderFunction<loaderData> = ({request}): Promise.t<loaderData> => {
  open RemixAuth

  let options = CreateAuthenticateOptions.make(~successRedirect="/", ~failureRedirect="/login", ())
  AuthServer.authenticator->Authenticator.authenticateWithOptions("discord", request, ~options)
}
