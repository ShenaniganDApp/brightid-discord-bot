type loaderData = {
  guild: Js.Nullable.t<Types.guild>,
  isAdmin: bool,
}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open DiscordServer
  open Promise

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getExn
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
  let context = useOutletContext()
  let {guild, isAdmin} = useLoaderData()

  let icon = ({id, icon}: Types.guild) => {
    switch icon {
    | None => "/assets/brightid_logo_white.png"
    | Some(icon) => `https://cdn.discordapp.com/icons/${id}/${icon}.png`
    }
  }

  let guildDisplay = switch guild->Js.Nullable.toOption {
  | None => <div> {"That Discord Server does not exist"->React.string} </div>
  | Some(guild) =>
    <div className="flex flex-col">
      <div className="flex gap-2">
        <img className="rounded-full h-10" src={guild->icon} />
        <p className="text-3xl font-bold text-white"> {guild.name->React.string} </p>
      </div>
      <div className="flex-row">
        <div> {"Verified Users"->React.string} </div> <div> {"Sponsored Users"->React.string} </div>
      </div>
    </div>
  }

  switch context["rateLimited"] {
  | false => ()
  | true =>
    ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(
      "The bot is being rate limited. Please try again later",
    )
  }

  <div className="p-4">
    <ReactHotToast.Toaster />
    <div className="flex">
      <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
      {guildDisplay}
      {isAdmin ? <div> {"You are an admin"->React.string} </div> : <> </>}
    </div>
  </div>
}
