module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}
type route = {
  name: string,
  path: string,
  icon: string,
}

let routes = [{name: "Sponsorships", path: "sponsorships", icon: "/assets/brightid_logo_white.png"}]
//  <img src={"/assets/brightid_logo.png"}/>
@react.component
let make = (~toggled: bool, ~handleToggleSidebar: bool => unit) => {
  open ReactProSidebar

  let sidebarElements = {
    routes->Belt.Array.mapWithIndex((i, r) => {
      <Menu iconShape="square" key={i->Belt.Int.toString}>
        <MenuItem icon={<img src={r.icon} />}>
          <Remix.Link to={r.path} prefetch={#intent}> {r.name->React.string} </Remix.Link>
        </MenuItem>
      </Menu>
    })
  }

  <ProSidebar className="bg-dark " breakPoint="md" onToggle={handleToggleSidebar} toggled>
    <SidebarHeader className="flex justify-center items-center">
      <Remix.Link to={""}>
        <MenuItem> <img src={"/assets/brightid_logo.png"} /> </MenuItem>
      </Remix.Link>
    </SidebarHeader>
    <SidebarContent> {React.array(sidebarElements)} </SidebarContent>
    <SidebarFooter className="p-4 flex justify-center items-center">
      <ConnectButton />
    </SidebarFooter>
  </ProSidebar>
}
