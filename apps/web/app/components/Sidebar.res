let routeNames = ["Sponsorships"]
@react.component
let make = (~collapsed: bool, ~toggled: bool, ~handleToggleSidebar: bool => unit) => {
  open ReactProSidebar
  <ProSidebar
    className="bg-dark"
    breakpoint="sm"
    onToggle={handleToggleSidebar}
    collapsed={collapsed}
    toggled={toggled}>
    <SidebarHeader> <img src={"/assets/brightid_logo.png"} /> </SidebarHeader>
    <SidebarContent>
      <Menu iconShape="square">
        <MenuItem icon={<img src={"/assets/brightid_logo_white.png"} />}>
          {React.string("Sponsorships")}
        </MenuItem>
      </Menu>
    </SidebarContent>
    <SidebarFooter>
      <div
        className="p-12 text-uppercase font-bold, font-size-14 overflow-hidden whitespace-nowrap">
        {React.string("sidebarFooter")}
      </div>
    </SidebarFooter>
  </ProSidebar>
}
