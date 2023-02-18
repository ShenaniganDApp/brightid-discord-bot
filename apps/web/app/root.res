%%raw(`import rainbowKit from "@rainbow-me/rainbowkit/styles.css"`)
%%raw(`import proSidebar from "react-pro-sidebar/dist/css/styles.css"`)
%%raw(`
import {
  getDefaultWallets,
} from "@rainbow-me/rainbowkit";
import { createClient, configureChains } from "wagmi"
import { mainnet} from 'wagmi/chains'
import { alchemyProvider } from 'wagmi/providers/alchemy'
import { publicProvider } from 'wagmi/providers/public'
import { jsonRpcProvider } from '@wagmi/core/providers/jsonRpc'

`)

module LodashMerge = {
  @module("lodash.merge") external merge: ('a, 'b) => 'a = "default"
}

@live
let meta = () =>
  {
    "charset": "utf-8",
    "title": "Bright ID Discord Command Center",
    "viewport": "width=device-width,initial-scale=1.0, maximum-scale=1.0, user-scalable=no",
  }

@live
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

let _idChain = {
  "id": 74,
  "name": "ID Chain",
  "nativeCurrency": {"name": "Eidi", "symbol": "EIDI", "decimals": 18},
  "rpcUrls": {
    "default": {
      "http": "https://idchain.one/rpc",
    },
  },
  "blockExplorers": [
    {
      "name": "Blockscout",
      "url": "https://explorer.idchain.one/",
    },
  ],
}

type loaderData = {maybeUser: option<RemixAuth.User.t>, rateLimited: bool}

@live
let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open DiscordServer
  open Promise

  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    {maybeUser: user->Nullable.toOption, rateLimited: false}->resolve
  })
  ->catch(error => {
    switch error {
    | DiscordRateLimited => {maybeUser: None, rateLimited: true}->resolve
    | _ => {maybeUser: None, rateLimited: false}->resolve
    }
  })
}

let myTheme = LodashMerge.merge(
  RainbowKit.Themes.darkTheme(),
  {"colors": {"accentColor": "#ed7a5c"}},
)

let chainConfig = %raw(`configureChains(
    [mainnet, _idChain],
    [
      alchemyProvider({
        apiKey: "Klcw92W_rTgV55TL0zq972TFXTI1FieU",
        stallTimeout: 5_000
      }),
      jsonRpcProvider({
        rpc: (chain)  => ({ http: chain.rpcUrls.default.http })
      }),

    ]

  )`)

let _defaultWallets = %raw(`getDefaultWallets({
    appName: "Bright ID Discord Command Center",
    chains: chainConfig.chains,
  })`)

let wagmiClient = %raw(`createClient({
    autoConnect: true,
    connectors: _defaultWallets.connectors,
    provider: chainConfig.provider,
  })`)

type state = {
  userGuilds: array<Types.oauthGuild>,
  botGuilds: array<Types.oauthGuild>,
  after: option<string>,
  loadingGuilds: bool,
  wagmiClient: option<Wagmi.client>,
  chains: option<array<Wagmi.chain>>,
}

let state = {
  userGuilds: [],
  botGuilds: [],
  after: Some("0"),
  loadingGuilds: true,
  wagmiClient: Some(wagmiClient),
  chains: Some(chainConfig["chains"]),
}

type actions =
  | AddBotGuilds(array<Types.oauthGuild>)
  | UserGuilds(array<Types.oauthGuild>)
  | SetAfter(option<string>)
  | SetLoadingGuilds(bool)
  | SetWagmiClient(option<Wagmi.client>)
  | SetChains(option<array<Wagmi.chain>>)

let reducer = (state, action) =>
  switch action {
  | AddBotGuilds(newBotGuilds) => {
      ...state,
      botGuilds: state.botGuilds->Array.concat(newBotGuilds),
    }
  | UserGuilds(userGuilds) => {...state, userGuilds}
  | SetAfter(after) => {...state, after}
  | SetLoadingGuilds(loadingGuilds) => {...state, loadingGuilds}
  | SetWagmiClient(wagmiClient) => {...state, wagmiClient}
  | SetChains(chains) => {...state, chains}
  }

@live @react.component
let default = () => {
  open RainbowKit
  let {maybeUser, rateLimited} = Remix.useLoaderData()
  let (isSidebarVisible, setIsSidebarVisible) = React.useState(_ => false)

  let fetcher = Remix.useFetcher()

  let (state, dispatch) = React.useReducer(reducer, state)

  React.useEffect1(() => {
    open Remix
    switch state.after {
    | None => ()
    | Some(after) =>
      switch fetcher->Fetcher._type {
      | "init" =>
        fetcher->Fetcher.load(~href=`/Root_FetchGuilds?after=${after}`)
        SetLoadingGuilds(true)->dispatch

      | "done" =>
        switch fetcher->Remix.Fetcher.data->Nullable.toOption {
        | None =>
          SetLoadingGuilds(false)->dispatch
          None->SetAfter->dispatch
        | Some(data) =>
          switch data["userGuilds"] {
          | [] => ()
          | _ => data["userGuilds"]->UserGuilds->dispatch
          }
          switch data["botGuilds"] {
          | [] => None->SetAfter->dispatch
          | _ => data["botGuilds"]->AddBotGuilds->dispatch
          }
          if state.after === data["after"] {
            None->SetAfter->dispatch
            SetLoadingGuilds(false)->dispatch
          } else {
            data["after"]->SetAfter->dispatch
            fetcher->Fetcher.load(~href=`/Root_FetchGuilds?after=${data["after"]}`)
          }
        }
      | _ => ()
      }
    }

    None
  }, [fetcher])

  let guilds =
    state.userGuilds->Array.filter(userGuild =>
      state.botGuilds->Array.findIndex(botGuild => botGuild.id === userGuild.id) !== -1
    )

  let handleIsSidebarVisible = value => {
    setIsSidebarVisible(_prev => value)
  }

  <html>
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <Remix.Meta />
      <Remix.Links />
    </head>
    <body className="h-screen w-screen bg-dark relative overflow-x-hidden">
      <div className="blur-[100px] md:blur-[150px]">
        <div
          className="absolute w-72 h-72 rounded-full top-[20vh] left-[-20vw] md:left-[15vw]  bg-gradient-to-b from-[#EC6041]  to-[#2F69FE]"
        />
        <div
          className="absolute w-72 h-72 rounded-full top-[70vh] left-[95vw] bg-gradient-to-b from-[#EC6041]  to-[#2F69FE] overflow-hidden"
        />
      </div>
      {switch (state.wagmiClient, state.chains) {
      | (Some(client), Some(chains)) =>
        <Wagmi.WagmiConfig client={client}>
          <RainbowKitProvider chains={chains} theme={myTheme}>
            <div className="flex h-screen w-screen z-10">
              {switch maybeUser {
              | None => <> </>
              | Some(_) =>
                <Sidebar
                  isSidebarVisible handleIsSidebarVisible guilds loadingGuilds={state.loadingGuilds}
                />
              }}
              <Remix.Outlet
                context={{
                  "isSidebarVisible": isSidebarVisible,
                  "handleIsSidebarVisible": handleIsSidebarVisible,
                  "rateLimited": rateLimited,
                  "guilds": guilds,
                }}
              />
            </div>
          </RainbowKitProvider>
        </Wagmi.WagmiConfig>
      | _ => <> </>
      }}
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

%%raw(`
export function ErrorBoundary({ error }) {
  console.error(error);
  return (
    <html>
      <head>
        <title>Oh no!</title>
        <React$1.Meta />
        <React$1.Links />
      </head>
      <body>
        <p className="text-center">Something went wrong!</p>
        <p className="text-center">BrightID command center is still in Beta. Try reloading the page!</p>
        <React$1.Scripts />
      </body>
    </html>
  );
}`)
