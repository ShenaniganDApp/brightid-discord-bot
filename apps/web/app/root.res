%%raw(`import rainbowKit from '@rainbow-me/rainbowkit/styles.css'`)
%%raw(`import proSidebar from 'react-pro-sidebar/dist/css/styles.css'`)
%%raw(`
import {
  apiProvider,
  configureChains,
  getDefaultWallets,
  darkTheme,
} from '@rainbow-me/rainbowkit';
import { chain, createClient } from 'wagmi'`)

module WagmiProvider = {
  @react.component @module("wagmi")
  external make: (~client: 'a, ~children: React.element) => React.element = "WagmiProvider"
}

module RainbowKitProvider = {
  @react.component @module("@rainbow-me/rainbowkit")
  external make: (~chains: 'a, ~children: React.element) => React.element = "RainbowKitProvider"
}

let meta = () =>
  {
    "title": "Bright ID Unique Bot",
  }

let links = () => {
  [
    {
      "rel": "stylesheet",
      "href": %raw(`require("./styles/app.css")`),
    },
    {
      "rel": "stylesheet",
      "href": %raw(`rainbowKit`),
    },
    {
      "rel": "stylesheet",
      "href": %raw(`proSidebar`),
    },
  ]
}

let idChain = {
  "id": 74,
  "name": "ID Chain",
  "nativeCurrency": {"name": "Eidi", "symbol": "EIDI", "decimals": 18},
  "rpcUrls": {
    "default": "https://idchain.one/rpc",
  },
  "blockExplorers": [
    {
      "name": "Blockscout",
      "url": "https://explorer.idchain.one/",
    },
  ],
}

let chainConfig = %raw(`configureChains(
  [idChain],
  [apiProvider.jsonRpc((chain) => ({ rpcUrl: chain.rpcUrls.default }))]
)`)

let defaultWallets = %raw(`getDefaultWallets({
  appName: 'Bright ID Unique Bot',
  chains:chainConfig.chains,
})`)

let wagmiClient = %raw(`createClient({
  autoConnect: true,
  connectors: defaultWallets.connectors,
  provider:chainConfig.provider,
  })`)

let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

type loaderData = {user: option<RemixAuth.User.t>, guilds: option<array<Types.guild>>}

let loader: Remix.loaderFunction = ({request}) => {
  open Promise
  open Webapi.Fetch

  let fetchGuilds = (user: RemixAuth.User.t) => {
    let headers = HeadersInit.make({
      "Authorization": `Bearer ${user->RemixAuth.User.getAccessToken}`,
    })
    let init = RequestInit.make(~method_=Get, ~headers, ())
    "https://discord.com/api/users/@me/guilds"->Request.makeWithInit(init)->fetchWithRequest
  }

  authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {user: None, guilds: None}->resolve
    | Some(user) =>
      user
      ->fetchGuilds
      ->then(res => res->Response.json)
      ->then(json => {
        let guilds =
          json
          ->Js.Json.decodeArray
          ->Belt.Option.map(guilds => {
            guilds->Js.Array2.map(guild => {
              let guild = guild->Js.Json.decodeObject->Belt.Option.getUnsafe

              (
                {
                  id: guild
                  ->Js.Dict.get("id")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getExn,
                  name: guild
                  ->Js.Dict.get("name")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getExn,
                  // icon: guild
                  // ->Js.Dict.get("icon")
                  // ->Belt.Option.flatMap(Js.Nullable.toOption)
                  // ->Belt.Option.flatMap(Js.Json.decodeNumber)
                  // ->Belt.Option.getExn,
                  permissions: guild
                  ->Js.Dict.get("permissions")
                  ->Belt.Option.flatMap(Js.Json.decodeNumber)
                  ->Belt.Option.getExn,
                }: Types.guild
              )
            })
          })
          ->Belt.Option.getUnsafe
        {user: Some(user), guilds: Some(guilds)}->resolve
      })
    }
  })
}

@react.component
let default = () => {
  let {user, guilds} = Remix.useLoaderData()
  let (toggled, setToggled) = React.useState(_ => false)

  let handleToggleSidebar = value => {
    setToggled(_prev => value)
  }

  <html>
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <Remix.Meta />
      <Remix.Links />
    </head>
    <body>
      <WagmiProvider client={wagmiClient}>
        <RainbowKitProvider chains={chainConfig["chains"]}>
          <main className="flex h-screen bg-gradient-to-tl from-brightid to-transparent">
            <Sidebar toggled handleToggleSidebar user guilds />
            <Remix.Outlet context={{"handleToggleSidebar": handleToggleSidebar}} />
          </main>
        </RainbowKitProvider>
      </WagmiProvider>
      <Remix.ScrollRestoration />
      <Remix.Scripts />
      {if Remix.process["env"]["NODE_ENV"] === "development" {
        <Remix.LiveReload />
      } else {
        React.null
      }}
    </body>
  </html>
}
