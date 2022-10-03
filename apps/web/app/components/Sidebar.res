module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}

type state = {
  userGuilds: array<Types.oauthGuild>,
  botGuilds: array<Types.oauthGuild>,
  after: option<string>,
  loading: bool,
}

let state = {
  userGuilds: [],
  botGuilds: [],
  after: Some("0"),
  loading: true,
}

type actions =
  | AddBotGuilds(array<Types.oauthGuild>)
  | UserGuilds(array<Types.oauthGuild>)
  | SetAfter(option<string>)
  | SetLoading(bool)

let reducer = (state, action) =>
  switch action {
  | AddBotGuilds(newBotGuilds) => {
      ...state,
      botGuilds: state.botGuilds->Belt.Array.concat(newBotGuilds),
    }
  | UserGuilds(userGuilds) => {...state, userGuilds}
  | SetAfter(after) => {...state, after}
  | SetLoading(loading) => {...state, loading}
  }

@react.component
let make = (~toggled, ~handleToggleSidebar, ~user) => {
  open ReactProSidebar

  let fetcher = Remix.useFetcher()
  let (state, dispatch) = React.useReducer(reducer, state)

  let icon = ({id, icon}: Types.oauthGuild) => {
    switch icon {
    | None => "/assets/brightid_logo_white.png"
    | Some(icon) => `https://cdn.discordapp.com/icons/${id}/${icon}.png`
    }
  }

  React.useEffect1(() => {
    open Remix
    switch state.after {
    | None => ()
    | Some(after) =>
      switch fetcher->Fetcher._type {
      | "init" =>
        fetcher->Fetcher.load(~href=`/Root_FetchGuilds?after=${after}`)
        SetLoading(true)->dispatch

      | "done" =>
        switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
        | None =>
          SetLoading(false)->dispatch
          None->SetAfter->dispatch
        | Some(data) =>
          switch data["userGuilds"] {
          | [] => ()
          | _ => data["userGuilds"]->UserGuilds->dispatch
          }
          switch data["botGuilds"] {
          | [] => None->SetAfter->dispatch
          | _ => data["botGuilds"]->AddBotGuilds->dispatch
          }
          if state.after === data["after"] {
            None->SetAfter->dispatch
            SetLoading(false)->dispatch
          } else {
            data["after"]->SetAfter->dispatch
            fetcher->Fetcher.load(~href=`/Root_FetchGuilds?after=${data["after"]}`)
          }
        }
      | _ => ()
      }
    }

    None
  }, [fetcher])

  let discordLogoutButton = switch user->Js.Nullable.toOption {
  | None =>
    // <MenuItem>
    <> </>
  // </MenuItem>
  | Some(_) => <DiscordLogoutButton label={`⤇`} />
  }

  let guilds =
    state.userGuilds->Js.Array2.filter(userGuild =>
      state.botGuilds->Js.Array2.findIndex(botGuild => botGuild.id === userGuild.id) !== -1
    )

  let sidebarElements = {
    switch user->Js.Nullable.toOption {
    | None => <> </>
    | Some(_) =>
      switch (state.botGuilds, state.userGuilds, state.loading) {
      | (_, _, true) =>
        let intersection = guilds->Belt.Array.mapWithIndex((i, guild: Types.oauthGuild) => {
          <Menu iconShape="square" key={(i + 1)->Belt.Int.toString}>
            <MenuItem
              className="bg-extraDark"
              icon={<img
                className=" bg-extraDark rounded-lg border-1 border-white" src={guild->icon}
              />}>
              <Remix.Link
                className="font-semibold text-xl" to={`/guilds/${guild.id}`} prefetch={#intent}>
                {guild.name->React.string}
              </Remix.Link>
            </MenuItem>
          </Menu>
        })
        let loading = Belt.Array.range(0, 4)->Belt.Array.map(i => {
          <Menu iconShape="square" key={(i + 1)->Belt.Int.toString}>
            <MenuItem
              className="flex animate-pulse flex-row h-full bg-extraDark "
              icon={<img
                className=" bg-extraDark  rounded-lg" src="/assets/brightid_logo_white.png"
              />}>
              <div className="flex flex-col space-y-3">
                <div className="w-36 bg-gray-300 h-6 rounded-md " />
              </div>
            </MenuItem>
          </Menu>
        })
        intersection->Belt.Array.concat(loading)->React.array
      | ([], _, false) =>
        <p className="text-white"> {"Couldn't Load Bot Servers"->React.string} </p>
      | (_, [], false) =>
        <p className="text-white"> {"Couldn't load User Servers"->React.string} </p>
      | (_, _, false) =>
        switch guilds->Belt.Array.length {
        | 0 => <p className="text-white"> {"No Guilds"->React.string} </p>
        | _ =>
          guilds
          ->Belt.Array.mapWithIndex((i, guild: Types.oauthGuild) => {
            <Menu iconShape="square" key={(i + 1)->Belt.Int.toString}>
              <MenuItem
                className="bg-extraDark"
                icon={<img
                  className=" bg-extraDark rounded-lg border-1 border-white" src={guild->icon}
                />}>
                <Remix.Link
                  className="font-semibold text-xl" to={`/guilds/${guild.id}`} prefetch={#intent}>
                  {guild.name->React.string}
                </Remix.Link>
              </MenuItem>
            </Menu>
          })
          ->React.array
        }
      }
    }
  }

  <ProSidebar
    className="bg-dark scrollbar-hide" breakPoint="md" onToggle={handleToggleSidebar} toggled>
    <SidebarHeader
      className="p-2 gap-3 flex justify-around items-center top-0 sticky bg-dark z-10 scrollbar-hide">
      <ConnectButton />
      {discordLogoutButton}
    </SidebarHeader>
    <SidebarContent className="scrollbar-hide">
      <Menu iconShape="square" key={0->Belt.Int.toString} />
      {sidebarElements}
    </SidebarContent>
    <SidebarFooter className="bg-extraDark bottom-0 sticky bg-dark scrollbar-hide">
      <Remix.Link to={""}>
        <MenuItem>
          <img src={"/assets/brightid_reversed.svg"} />
        </MenuItem>
      </Remix.Link>
    </SidebarFooter>
  </ProSidebar>
}
