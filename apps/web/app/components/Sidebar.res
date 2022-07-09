module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}

//  <img src={"/assets/brightid_logo.png"}/>
@react.component
let make = (~toggled, ~handleToggleSidebar, ~user, ~guilds) => {
  open ReactProSidebar

  // let fetcher = Remix.useFetcher()

  let icon = ({id, icon}: Types.guild) => {
    switch icon {
    | None => "/assets/brightid_logo_white.png"
    | Some(icon) => `https://cdn.discordapp.com/icons/${id}/${icon}.png`
    }
  }

  // React.useEffect1(() => {
  // let fetchGuilds = () => {
  //   open Remix
  //   if fetcher->Fetcher._type === "init" {
  //     fetcher->Fetcher.load(~href=`/fetchGuilds`)
  //   }
  //   Js.log2("type", fetcher->Remix.Fetcher._type)
  // }
  //   None
  // }, [fetcher])

  // let sidebarElements = {
  //   switch user->Js.Nullable.toOption {
  //   | None => <> </>
  //   | Some(_) =>
  //     switch fetcher->Remix.Fetcher._type {
  //     | "done" =>
  //       switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
  //       | None => <p className="text-white"> {"No Guilds"->React.string} </p>
  //       | Some(guilds) =>
  //         switch guilds->Belt.Array.length {
  //         | 0 => <p className="text-white"> {"No Guilds"->React.string} </p>
  //         | _ =>
  //           guilds
  //           ->Belt.Array.mapWithIndex((i, guild: Types.guild) => {
  //             <Menu iconShape="square" key={i->Belt.Int.toString}>
  //               <MenuItem
  //                 icon={<img className="rounded-lg border-1 border-white" src={guild->icon} />}>
  //                 <Remix.Link
  //                   className="font-semibold text-xl" to={`/guilds/${guild.id}`} prefetch={#intent}>
  //                   {guild.name->React.string}
  //                 </Remix.Link>
  //               </MenuItem>
  //             </Menu>
  //           })
  //           ->React.array
  //         }
  //       }
  //     | _ =>
  //       <button onClick={_ => fetchGuilds()} className="text-white">
  //         {"Loading Guilds"->React.string}
  //       </button>
  //     }
  //   }
  // }

  let sidebarElements = {
    switch user->Js.Nullable.toOption {
    | None => <div> {"Login to load Guilds"->React.string} </div>
    | Some(_) =>
      switch guilds {
      | [] => <p className="text-white"> {"No Guilds"->React.string} </p>
      | _ =>
        guilds
        ->Belt.Array.mapWithIndex((i, guild: Types.guild) => {
          <Menu iconShape="square" key={i->Belt.Int.toString}>
            <MenuItem
              icon={<img
                className="rounded-lg border-1 border-white bg-transparent" src={guild->icon}
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

  <ProSidebar className="bg-dark " breakPoint="md" onToggle={handleToggleSidebar} toggled>
    <SidebarHeader className="p-4 flex justify-center items-center top-0 sticky bg-dark z-10 ">
      <ConnectButton />
    </SidebarHeader>
    <SidebarContent className="no-scrollbar"> {sidebarElements} </SidebarContent>
    <SidebarFooter className="bottom-0 sticky bg-dark">
      <Remix.Link to={""}>
        <MenuItem> <img src={"/assets/brightid_reversed.svg"} /> </MenuItem>
      </Remix.Link>
    </SidebarFooter>
  </ProSidebar>
}
