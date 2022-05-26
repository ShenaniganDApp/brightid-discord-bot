%%raw(`import rainbowKit from '@rainbow-me/rainbowkit/styles.css'`)
%%raw(`import proSidebar from 'react-pro-sidebar/dist/css/styles.css'`)
%%raw(`
import {
  apiProvider,
  configureChains,
  getDefaultWallets,
  darkTheme,
} from '@rainbow-me/rainbowkit';
import { chain, createClient } from 'wagmi';`)

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

@react.component
let default = () => {
  let (collapsed, setCollapsed) = React.useState(_ => true)
  let (toggled, setToggled) = React.useState(_ => true)

  let handleCollapsedChange = checked => {
    setCollapsed(_prev => checked)
  }

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
          <main className="flex h-screen bg-gradient-to-tl from-brightid to-transparent ">
            <Sidebar collapsed toggled handleToggleSidebar /> <Remix.Outlet />
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
// let catchBoundary = () => {
//   open Webapi.Fetch

//   let caught = Remix.useCatch()

//   <Document title={`${caught->Response.status->Js.Int.toString} ${caught->Response.statusText}`}>
//     <div className="error-container">
//       <h1>
//         {`${caught->Response.status->Js.Int.toString} ${caught->Response.statusText}`->React.string}
//       </h1>
//     </div>
//   </Document>
// }

// %%raw(`export const CatchBoundary = catchBoundary`)

// let errorBoundary: Remix.errorBoundaryComponent = props => {
//   Js.log(props.error)

//   <Document title="Uh-oh!">
//     <div className="error-container">
//       <h1> {"App Error"->React.string} </h1>
//       <pre> {props.error->Js.Exn.message->Belt.Option.getWithDefault("")->React.string} </pre>
//     </div>
//   </Document>
// }
// %%raw(`export const ErrorBoundary = errorBoundary`)
