type loaderData = unit

let action: Remix.actionFunction<loaderData> = ({request}) => {
  AuthServer.authenticator->RemixAuth.Authenticator.logout(request, ~options={"redirectTo": "/"})
}
