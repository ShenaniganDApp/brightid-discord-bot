type loaderData = string
let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

@module("remix") external useOutletContext: unit => 'a = "useOutletContext"

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open Promise

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getExn
  authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => ""->resolve
    | Some(_) => guildId->resolve
    }
  })
}

let default = () => {
  let context = useOutletContext()
  let gistId = Remix.useLoaderData()

  <div>
    <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
    <h1> {gistId->React.string} </h1>
  </div>
}
