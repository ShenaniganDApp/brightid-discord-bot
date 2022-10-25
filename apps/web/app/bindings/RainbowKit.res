module Themes = {
  type t
  @module("@rainbow-me/rainbowkit") external darkTheme: unit => t = "darkTheme"
}
module RainbowKitProvider = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (~chains: 'a, ~theme: 'a, ~children: React.element) => React.element =
    "RainbowKitProvider"
}

module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}
