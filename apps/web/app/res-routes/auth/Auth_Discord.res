open Promise

type loaderData = RemixAuth.User.t

let loader: Remix.loaderFunction<Webapi.Fetch.Response.t> = _ => Remix.redirect("/")->resolve

let action: Remix.actionFunction<loaderData> = ({request}) => {
  AuthServer.authenticator->RemixAuth.Authenticator.authenticate("discord", request)
}
