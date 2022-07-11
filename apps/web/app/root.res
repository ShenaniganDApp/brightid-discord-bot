%%raw(`import rainbowKit from "@rainbow-me/rainbowkit/styles.css"`)
%%raw(`import proSidebar from "react-pro-sidebar/dist/css/styles.css"`)
%%raw(`
import {
  apiProvider,
  configureChains,
  getDefaultWallets,
} from "@rainbow-me/rainbowkit";
import { chain, createClient } from "wagmi"`)

module WagmiProvider = {
  @react.component @module("wagmi")
  external make: (~client: 'a, ~children: React.element) => React.element = "WagmiProvider"
}

module LodashMerge = {
  @module("lodash.merge") external merge: ('a, 'b) => 'a = "default"
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
  appName: "Bright ID Unique Bot",
  chains:chainConfig.chains,
})`)

let wagmiClient = %raw(`createClient({
  autoConnect: true,
  connectors: defaultWallets.connectors,
  provider:chainConfig.provider,
  })`)

type loaderData = {user: Js.Nullable.t<RemixAuth.User.t>, rateLimited: bool}

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open DiscordServer
  open Promise

  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    {user: user, rateLimited: false}->resolve
  })
  ->catch(error => {
    switch error {
    | DiscordRateLimited => {user: Js.Nullable.null, rateLimited: true}->resolve
    | _ => {user: Js.Nullable.null, rateLimited: false}->resolve
    }
  })
}

let myTheme = LodashMerge.merge(
  RainbowKit.Themes.darkTheme(),
  {"colors": {"accentColor": "#ed7a5c"}},
)

let unstable_shouldReload = () => false

@react.component
let default = () => {
  open RainbowKit
  let {user, rateLimited} = Remix.useLoaderData()
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
    <body className="h-screen w-screen bg-dark">
      <WagmiProvider client={wagmiClient}>
        <RainbowKitProvider chains={chainConfig["chains"]} theme={myTheme}>
          <div className="flex h-screen w-screen">
            <Sidebar toggled handleToggleSidebar user />
            <Remix.Outlet
              context={{"handleToggleSidebar": handleToggleSidebar, "rateLimited": rateLimited}}
            />
          </div>
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
