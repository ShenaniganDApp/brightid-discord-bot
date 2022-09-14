type loaderData = {
  guild: Js.Nullable.t<Types.guild>,
  isAdmin: bool,
}

type params = {guildId: string}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open DiscordServer
  open Promise

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {guild: Js.Nullable.null, isAdmin: false}->resolve
    | Some(user) =>
      fetchGuildFromId(~guildId)->then(guild => {
        let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId
        fetchGuildMemberFromId(~guildId, ~userId)->then(guildMember => {
          let memberRoles = switch guildMember->Js.Nullable.toOption {
          | None => []
          | Some(guildMember) => guildMember.roles
          }
          fetchGuildRoles(~guildId)->then(guildRoles => {
            let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
            let isOwner = switch guild->Js.Nullable.toOption {
            | None => false
            | Some(guild) => guild.owner_id === userId
            }
            {guild: guild, isAdmin: isAdmin || isOwner}->resolve
          })
        })
      })
    }
  })
  ->catch(error => {
    switch error {
    | DiscordRateLimited => {guild: Js.Nullable.null, isAdmin: false}->resolve
    | _ => {guild: Js.Nullable.null, isAdmin: false}->resolve
    }
  })
}

let default = () => {
  open Remix
  let {guildId} = useParams()
  let context = useOutletContext()
  let {guild, isAdmin} = useLoaderData()

  let guildDisplay = switch guild->Js.Nullable.toOption {
  | None => <div> {"That Discord Server does not exist"->React.string} </div>
  | Some(guild) =>
    <div className="flex flex-col items-center">
      <div className="flex gap-4 w-full justify-start items-center">
        <img className="rounded-full h-24" src={guild->Helpers_Guild.iconUri} />
        <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
      </div>
      <div className="flex-row" />
    </div>
  }

  switch context["rateLimited"] {
  | false => ()
  | true =>
    ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(
      "The bot is being rate limited. Please try again later",
    )
  }

  <div className="flex-1 p-4">
    <ReactHotToast.Toaster />
    <div className="flex flex-col">
      <header className="flex flex-row justify-between md:justify-end m-4">
        <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
        {isAdmin ? <AdminButton guildId={guildId} /> : <> </>}
      </header>
      {guildDisplay}
    </div>
  </div>
}
