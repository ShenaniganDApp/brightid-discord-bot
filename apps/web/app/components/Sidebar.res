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
let make = (~toggled, ~handleToggleSidebar, ~user, ~guilds: option<array<Types.guild>>) => {
  open ReactProSidebar

  let sidebarElements = {
    switch user {
    | None => <DiscordButton label="Login to Discord" />
    | Some(_) =>
      switch guilds {
      | None => <p> {"No Guilds"->React.string} </p>
      | Some(guilds) =>
        guilds
        ->Belt.Array.mapWithIndex((i, guild) => {
          <Menu iconShape="square" key={i->Belt.Int.toString}>
            <MenuItem icon={<img src={"/assets/brightid_logo_white.png"} />}>
              <Remix.Link to={`/guilds/${guild.id}`} prefetch={#intent}>
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
