type client
type chain
type connector
type account = {
  address: option<string>,
  connector: option<connector>,
  isConnecting: bool,
  isReconnecting: bool,
  isConnected: bool,
  isDisconnected: bool,
  status: [#connecting | #reconnecting | #connected | #disconnected],
}

type queryResult<'data> = {
  "data": option<'data>,
  "error": option<Exn.t>,
  "isIdle": bool,
  "isLoading": bool,
  "isFetching": bool,
  "isSuccess": bool,
  "isError": bool,
  "isFetched": bool,
  "isFetchedAfterMount": bool,
  "isRefetching": bool,
}

type balanceData = {
  "decimals": int,
  "formatted": string,
  "symbol": string,
  "value": Shared.Ethers.BigNumber.t,
}

type balance = {...queryResult<balanceData>, "status": [#idle | #error | #loading | #success]}
module WagmiConfig = {
  @react.component @module("wagmi")
  external make: (~client: client, ~children: React.element) => React.element = "WagmiConfig"
}

@module("wagmi")
external useAccount: 'a => account = "useAccount"
@module("wagmi")
external useSignMessage: 'a => {
  ...queryResult<{
    "signature": Nullable.t<string>,
  }>,
  "signMessage": unit => unit,
} = "useSignMessage"

@module("wagmi")
external useBalance: 'a => balance = "useBalance"
