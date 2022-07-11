module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}

@react.component
let make = (~toggled, ~handleToggleSidebar, ~user) => {
  open ReactProSidebar

  let fetcher = Remix.useFetcher()

  let icon = ({id, icon}: Types.oauthGuild) => {
    switch icon {
    | None => "/assets/brightid_logo_white.png"
    | Some(icon) => `https://cdn.discordapp.com/icons/${id}/${icon}.png`
    }
  }
  let fetchGuilds = () => {
    if fetcher->Remix.Fetcher._type === "init" {
      fetcher->Remix.Fetcher.load(~href=`/Root_FetchGuilds`)
    }
  }

  React.useEffect1(() => {
    open Remix
    if fetcher->Fetcher._type === "init" {
      fetcher->Fetcher.load(~href=`/Root_FetchGuilds`)
    }
    None
  }, [fetcher])

  let sidebarElements = {
    switch user->Js.Nullable.toOption {
    | None => <> </>
    | Some(_) =>
      switch fetcher->Remix.Fetcher._type {
      | "done" =>
        switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
        | None => <p className="text-white"> {"No Guilds"->React.string} </p>
        | Some(data) =>
          switch data["guilds"]->Belt.Array.length {
          | 0 => <p className="text-white"> {"No Guilds"->React.string} </p>
          | _ =>
            data["guilds"]
            ->Belt.Array.mapWithIndex((i, guild: Types.oauthGuild) => {
              <Menu iconShape="square" key={i->Belt.Int.toString}>
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
      | "normalLoad" =>
        Belt.Array.range(0, 4)
        ->Belt.Array.map(i => {
          <Menu iconShape="square" key={i->Belt.Int.toString}>
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
        ->React.array
      | _ =>
        <div onClick={_ => fetchGuilds()} className="text-white">
          {"Load Guilds"->React.string}
        </div>
      }
    }
  }

  <ProSidebar className="bg-dark " breakPoint="md" onToggle={handleToggleSidebar} toggled>
    <SidebarHeader className="p-4 flex justify-center items-center top-0 sticky bg-dark z-10 ">
      <ConnectButton />
    </SidebarHeader>
    <SidebarContent className="no-scrollbar"> {sidebarElements} </SidebarContent>
    <SidebarFooter className="bg-extraDark bottom-0 sticky bg-dark">
      <Remix.Link to={""}>
        <MenuItem> <img src={"/assets/brightid_reversed.svg"} /> </MenuItem>
      </Remix.Link>
    </SidebarFooter>
  </ProSidebar>
}
