open Promise
let authenticator = %raw(`require("~/auth.server").auth`)

type loaderData = Webapi.Fetch.Response.t

let loader = (): Promise.t<loaderData> => Remix.redirect("/")->resolve

let action = (args: {"request": Webapi.Fetch.Request.t, "params": {"provider": 'a}}) => {
  %raw(`authenticator.authenticate("discord", args.request)`)
}
