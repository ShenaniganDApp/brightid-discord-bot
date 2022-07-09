let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

let fetchGuildFromId: (
  ~guildId: string,
) => Js.Promise.t<Js.Nullable.t<Types.guild>> = %raw(`require( "~/bot.server").fetchGuildFromId`)

let fetchGuildMemberFromId: (
  ~guildId: string,
  ~userId: string,
) => Js.Promise.t<
  Js.Nullable.t<Types.guildMember>,
> = %raw(`require( "~/bot.server").fetchGuildMemberFromId`)

let fetchGuildRoles: (
  ~guildId: string,
) => Js.Promise.t<Js.Array.t<Types.role>> = %raw(`require( "~/bot.server").fetchGuildRoles`)

let memberIsAdmin: (
  ~guildRoles: array<Types.role>,
  ~memberRoles: array<string>,
) => bool = %raw(`require( "~/bot.server").memberIsAdmin`)

type loaderData = {
  guild: Js.Nullable.t<Types.guild>,
  isAdmin: bool,
}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open Promise

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getExn
  authenticator
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
}

let default = () => {
  open Remix
  let context = useOutletContext()
  let {guild, isAdmin} = useLoaderData()
  Js.log2("isAdmin: ", isAdmin)

  let guildDisplay = switch guild->Js.Nullable.toOption {
  | None => <div> {"That Discord Server does not exist"->React.string} </div>
  | Some(guild) => <div> <div> {guild.name->React.string} </div> </div>
  }
  <div>
    <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
    <div> {guildDisplay} </div>
    {isAdmin ? <div> {"You are an admin"->React.string} </div> : <> </>}
  </div>
}
