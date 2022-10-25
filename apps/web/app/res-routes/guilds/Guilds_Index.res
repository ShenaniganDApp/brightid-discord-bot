type params = {guildId: string}

type state = {
  guild: option<Types.guild>,
  isAdmin: bool,
  brightIdGuild: option<Shared.BrightId.brightIdGuild>,
  loading: bool,
  oauthGuild: option<Types.oauthGuild>,
}

let state = {
  guild: None,
  isAdmin: false,
  brightIdGuild: None,
  loading: true,
  oauthGuild: None,
}

type actions =
  | SetGuild(option<Types.guild>)
  | SetIsAdmin(bool)
  | SetBrightIdGuild(option<Shared.BrightId.brightIdGuild>)
  | SetLoading(bool)
  | SetOAuthGuild(option<Types.oauthGuild>)

let reducer = (state, action) =>
  switch action {
  | SetGuild(guild) => {
      ...state,
      guild,
    }
  | SetIsAdmin(isAdmin) => {
      ...state,
      isAdmin,
    }
  | SetBrightIdGuild(brightIdGuild) => {
      ...state,
      brightIdGuild,
    }
  | SetLoading(loading) => {...state, loading}
  | SetOAuthGuild(oauthGuild) => {...state, oauthGuild}
  }

let default = () => {
  open Remix
  let {guildId} = useParams()
  let context = useOutletContext()

  let fetcher = Remix.useFetcher()

  let (state, dispatch) = React.useReducer(reducer, state)

  React.useEffect1(() => {
    switch fetcher->Fetcher._type {
    | "init" =>
      fetcher->Fetcher.load(~href=`/guilds/${guildId}/Guilds_FetchGuild`)
      Js.log(fetcher)
      SetLoading(true)->dispatch

    | "done" =>
      switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
      | None => SetLoading(false)->dispatch

      | Some(data) =>
        Js.log2("data: ", data)
        data["guild"]->SetGuild->dispatch

        data["isAdmin"]->SetIsAdmin->dispatch
        data["brightIdGuild"]->SetBrightIdGuild->dispatch
        SetLoading(false)->dispatch
      }
    | _ => ()
    }

    None
  }, [fetcher])

  React.useEffect1(() => {
    let contextGuilds: array<Types.oauthGuild> = context["guilds"]
    switch contextGuilds->Belt.Array.getIndexBy(guild => guild.id === guildId) {
    | None => ()
    | Some(index) => contextGuilds->Belt.Array.get(index)->SetOAuthGuild->dispatch
    }
    None
  }, [context])

  // let guildDisplay = switch state.guild {
  // | None => <div> {"That Discord Server does not exist"->React.string} </div>
  // | Some(guild) =>
  //   <div className="flex flex-col items-center">
  //     <div className="flex gap-4 w-full justify-start items-center">
  //       <img className="rounded-full h-24" src={guild->Helpers_Guild.iconUri} />
  //       <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
  //     </div>
  //     <div className="flex-row" />
  //   </div>
  // }

  let guildHeader = switch state.oauthGuild {
  | None => <div className="text-2xl md:text-3xl font-semibold text-white" />
  | Some(guild) =>
    <div className="flex gap-6 w-full justify-start items-center">
      <img
        className="rounded-full h-24"
        src={guild.icon
        ->Belt.Option.map(icon => `https://cdn.discordapp.com/icons/${guild.id}/${icon}.png`)
        ->Belt.Option.getWithDefault("")}
      />
      <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
      {state.isAdmin ? <AdminButton guildId={guildId} /> : <> </>}
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
    switch state.isAdmin {
    | true =>
      switch state.brightIdGuild {
      | Some({sponsorshipAddress: Some(_)}) => ()
      | _ =>
        ReactHotToast.Toaster.makeCustomToaster(
          t => {
            <span
              onClick={_ => {t->ReactHotToast.Toaster.dismiss("sponsor")}}
              className="flex flex-col font-bold bg-dark outline-2 border-brightid text-white cursor-pointer">
              {React.string(
                "This server is not setup to sponsor its members. Start sponsoring ➡️",
              )}
            </span>
          },
          ~options={
            "duration": 100000,
            "icon": `⚠️`,
            "id": "sponsor",
            "position": "bottom-right",
            "style": {
              "background": "transparent",
              "border": "2px solid ",
              "border-color": "#ed7a5c",
            },
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
      <header className="flex flex-row justify-between md:justify-end items-center m-4">
        <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
        <div className="flex flex-col md:flex-row gap-2 items-center justify-center">
          <RainbowKit.ConnectButton className="h-full" />
        </div>
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
              {" Avaliable Sponsors"->React.string}
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
