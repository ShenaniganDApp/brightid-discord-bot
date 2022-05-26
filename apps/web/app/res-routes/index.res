module ConnectButton = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (
    ~children: React.element=?,
    ~style: ReactDOM.Style.t=?,
    ~className: string=?,
  ) => 'b = "ConnectButton"
}

@react.component
let default = () => {
  let account = Wagmi.useAccount()

  ///WTF is up with Nullable and react state
  let address = switch account["data"]->Js.Nullable.toOption {
  | None => ""
  | Some(data) =>
    switch data["address"]->Js.Nullable.toOption {
    | None => ""
    | Some(address) => address
    }
  }

  <div className=""> <ConnectButton className="" /> </div>
}
