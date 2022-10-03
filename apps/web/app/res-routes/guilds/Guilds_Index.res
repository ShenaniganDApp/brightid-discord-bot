type loaderData = {
  guild: Js.Nullable.t<Types.guild>,
  brightIdGuild: Js.Nullable.t<Shared.BrightId.brightIdGuild>,
  isAdmin: bool,
}

type params = {guildId: string}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open DiscordServer
  open Promise
  open Shared

  let config = WebUtils_Gist.makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {guild: Js.Nullable.null, isAdmin: false, brightIdGuild: Js.Nullable.null}->resolve
    | Some(user) =>
      WebUtils_Gist.ReadGist.content(
        ~config,
        ~decoder=Decode.Gist.brightIdGuilds,
      )->then(brightIdGuilds => {
        let brightIdGuild = brightIdGuilds->Js.Dict.get(guildId)->Js.Nullable.fromOption
        fetchGuildFromId(~guildId)->then(
          guild => {
            let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId
            fetchGuildMemberFromId(~guildId, ~userId)->then(
              guildMember => {
                let memberRoles = switch guildMember->Js.Nullable.toOption {
                | None => []
                | Some(guildMember) => guildMember.roles
                }
                fetchGuildRoles(~guildId)->then(
                  guildRoles => {
                    let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
                    let isOwner = switch guild->Js.Nullable.toOption {
                    | None => false
                    | Some(guild) => guild.owner_id === userId
                    }
                    {guild, isAdmin: isAdmin || isOwner, brightIdGuild}->resolve
                  },
                )
              },
            )
          },
        )
      })
    }
  })
  ->catch(error => {
    switch error {
    | DiscordRateLimited =>
      {guild: Js.Nullable.null, isAdmin: false, brightIdGuild: Js.Nullable.null}->resolve
    | _ => {guild: Js.Nullable.null, isAdmin: false, brightIdGuild: Js.Nullable.null}->resolve
    }
  })
}

let default = () => {
  open Remix
  let {guildId} = useParams()
  let context = useOutletContext()
  let {guild, isAdmin, brightIdGuild} = useLoaderData()

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

  let guildHeader = switch guild->Js.Nullable.toOption {
  | None => <div> {"That Discord Server does not exist"->React.string} </div>
  | Some(guild) =>
    <div className="flex gap-4 w-full justify-start items-center">
      <img className="rounded-full h-24" src={guild->Helpers_Guild.iconUri} />
      <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
    </div>
  }

  React.useEffect0(() => {
    switch context["rateLimited"] {
    | false => ()
    | true =>
      ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(
        "The bot is being rate limited. Please try again later",
        (),
      )
    }
    switch isAdmin {
    | true =>
      switch brightIdGuild->Js.Nullable.toOption {
      | Some({sponsorshipAddress: Some(_)}) => ()
      | _ =>
        ReactHotToast.Toaster.makeCustomToaster(
          t => {
            <span
              onClick={_ => t->ReactHotToast.Toaster.dismiss("sponsor")}
              className="flex flex-col bg-dark outline-2 border-brightid text-white">
              {React.string("This server is not setup to sponsor its members ")}
            </span>
          },
          ~options={
            "duration": 100000,
            "icon": `⚠️`,
            "id": "sponsor",
            "position": "bottom-right",
          },
          (),
        )
      }
    | _ => ()
    }
    None
  })

  <div className="flex-1 p-4">
    <ReactHotToast.Toaster />
    <div className="flex flex-col h-screen">
      <header className="flex flex-row justify-between md:justify-end m-4">
        <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
        {isAdmin ? <AdminButton guildId={guildId} /> : <> </>}
      </header>
      {guildHeader}
      <div className="flex flex-1 flex-col  justify-around items-center text-center">
        <section
          className="width-full flex flex-col md:flex-row justify-around items-center w-full">
          <div
            className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
            <div className="text-3xl font-bold text-white">
              {"Verified Server Members"->React.string}
            </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {"1000"->React.string}
            </div>
          </div>
          <div
            className="flex flex-col  rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
            <div className="text-3xl font-bold text-white"> {"Users Sponsored"->React.string} </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {"125"->React.string}
            </div>
          </div>
          <div
            className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
            <div className="text-3xl font-bold text-white">
              {"Total Used Sponsors"->React.string}
            </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {"0"->React.string}
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
}
