let authenticator = %raw(`require( "~/auth.server").auth`)

type loaderData = Webapi.Fetch.Response.t

let loader = (args: {"request": Webapi.Fetch.Request.t, "params": {"provider": 'a}}): Promise.t<
  loaderData,
> => {
  %raw(`authenticator.authenticate("discord", args.request, {
      successRedirect: "/",
      failureRedirect: "/login",
    })`)
}
