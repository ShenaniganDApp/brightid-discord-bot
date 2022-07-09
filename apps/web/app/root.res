%%raw(`import rainbowKit from '@rainbow-me/rainbowkit/styles.css'`)
%%raw(`import proSidebar from 'react-pro-sidebar/dist/css/styles.css'`)
%%raw(`
import {
  apiProvider,
  configureChains,
  getDefaultWallets,
} from '@rainbow-me/rainbowkit';
import { chain, createClient } from 'wagmi'`)

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
  appName: 'Bright ID Unique Bot',
  chains:chainConfig.chains,
})`)

let wagmiClient = %raw(`createClient({
  autoConnect: true,
  connectors: defaultWallets.connectors,
  provider:chainConfig.provider,
  })`)

// let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

// type loaderData = Js.Nullable.t<RemixAuth.User.t>
let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

let fetchBotGuilds: (
  ~after: int=?,
  ~allGuilds: array<Types.guild>=?,
  ~retry: int=?,
  unit,
) => Js.Promise.t<array<Types.guild>> = %raw(`require( "~/bot.server").fetchBotGuilds`)

let fetchUserGuilds: RemixAuth.User.t => Promise.t<
  Js.Array2.t<Types.guild>,
> = %raw(`require( "~/bot.server").fetchUserGuilds`)

type loaderData = {user: Js.Nullable.t<RemixAuth.User.t>, guilds: array<Types.guild>}

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Promise

  authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {user: user, guilds: []}->resolve
    | Some(existingUser) =>
      existingUser
      ->fetchUserGuilds
      ->then(userGuilds => {
        fetchBotGuilds()->then(botGuilds => {
          let guilds =
            userGuilds->Js.Array2.filter(userGuild =>
              botGuilds->Js.Array2.findIndex(botGuild => botGuild.id === userGuild.id) !== -1
            )
          {user: user, guilds: guilds}->resolve
        })
      })
    }
  })
}

// let loader: Remix.loaderFunction<loaderData> = ({request}) => {
//   open Promise

//   authenticator
//   ->RemixAuth.Authenticator.isAuthenticated(request)
//   ->then(user => {
//     user->resolve
//   })
// }

let myTheme = LodashMerge.merge(
  RainbowKit.Themes.darkTheme(),
  {"colors": {"accentColor": "#ed7a5c"}},
)

let unstable_shouldReload = () => false

@react.component
let default = () => {
  open RainbowKit
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
    <body className="h-screen w-screen bg-dark">
      <WagmiProvider client={wagmiClient}>
        <RainbowKitProvider chains={chainConfig["chains"]} theme={myTheme}>
          <div className="flex h-screen w-screen">
            <Sidebar toggled handleToggleSidebar user guilds />
            <Remix.Outlet context={{"handleToggleSidebar": handleToggleSidebar}} />
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
