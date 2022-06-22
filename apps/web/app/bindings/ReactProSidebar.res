module ProSidebar = {
  @react.component @module("react-pro-sidebar")
  external make: (
    ~children: React.element,
    ~className: string=?,
    ~breakPoint: string,
    ~onToggle: bool => unit,
    ~collapsed: bool=?,
    ~toggled: bool=?,
  ) => React.element = "ProSidebar"
}

module Menu = {
  @react.component @module("react-pro-sidebar")
  external make: (~children: React.element=?, ~iconShape: string) => React.element = "Menu"
}
module MenuItem = {
  @react.component @module("react-pro-sidebar")
  external make: (~children: React.element=?, ~icon: React.element=?) => React.element = "MenuItem"
}
module SidebarHeader = {
  @react.component @module("react-pro-sidebar")
  external make: (~children: React.element=?, ~className: string=?) => React.element =
    "SidebarHeader"
}
module SidebarContent = {
  @react.component @module("react-pro-sidebar")
  external make: (~children: React.element) => React.element = "SidebarContent"
}
module SidebarFooter = {
  @react.component @module("react-pro-sidebar")
  external make: (~children: React.element=?, ~className: string=?) => React.element =
    "SidebarFooter"
}
