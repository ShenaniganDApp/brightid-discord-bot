type params = {guildId: string}
type loaderData = {
  maybeUser: option<RemixAuth.User.t>,
  isAdmin: bool,
  maybeDiscordGuild: promise<option<Types.guild>>,
}

type routeMatch<'a, 'b> = {
  id: string,
  pathname: string,
  params: Dict.t<string>,
  data: 'a,
  handle: option<'b>,
}
@module("@remix-run/react") external useMatches: unit => array<routeMatch<'a, 'b>> = "useMatches"
@module("@remix-run/node") external defer: loaderData => loaderData = "defer"
@module("@remix-run/react") external useAsyncValue: unit => 'a = "useAsyncValue"

module Await = {
  type t
  @react.component @module("@remix-run/react")
  external make: (~children: 'a => React.element, ~resolve: 'b) => React.element = "Await"
}

let loader: Remix.loaderFunction<loaderData> = async ({request, params}) => {
  open DiscordServer

  let guildId = params->Dict.get("guildId")->Option.getWithDefault("")

  let maybeUser = switch await RemixAuth.Authenticator.isAuthenticated(
    AuthServer.authenticator,
    request,
  ) {
  | data => data->Nullable.toOption
  | exception JsError(e) => None
  }

  switch maybeUser {
  | None => {maybeUser, isAdmin: false, maybeDiscordGuild: Promise.resolve(None)}
  | Some(user) =>
    try {
      let discordGuild = await fetchDiscordGuildFromId(~guildId)

      let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId
      let guildMember = await fetchGuildMemberFromId(~guildId, ~userId)

      let memberRoles = switch guildMember->Nullable.toOption {
      | None => []
      | Some(guildMember) => guildMember.roles
      }
      let guildRoles = switch await fetchGuildRoles(~guildId) {
      | data => data
      | exception JsError(_) => []
      }
      let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
      let isOwner = switch discordGuild->Nullable.toOption {
      | None => false
      | Some(guild) => guild.owner_id === userId
      }
      defer({
        maybeUser,
        isAdmin: isAdmin || isOwner,
        maybeDiscordGuild: discordGuild->Nullable.toOption->Promise.resolve,
      })
    } catch {
    | Exn.Error(e) =>
      Console.error(e)
      {maybeUser, isAdmin: false, maybeDiscordGuild: Promise.resolve(None)}
    }
  }
}

let action: Remix.actionFunction<'a> = async ({request, params}) => {
  open Webapi.Fetch
  open Guilds_AdminSubmit
  open WebUtils_Gist
  open Shared.Decode

  let guildId = params->Dict.get("guildId")->Option.getWithDefault("")

  let _ = switch await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request) {
  | data => Some(data)
  | exception JsError(_) => None
  }

  let data = await Request.formData(request)

  let {sponsorshipAddress} = Form.make(data)

  let config = makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )
  let content = await ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)
  let prevEntry = switch content->Dict.get(guildId) {
  | Some(entry) => entry
  | None => GuildDoesNotExist(guildId)->raise
  }
  let entry = {
    ...prevEntry,
    sponsorshipAddress,
  }

  switch await UpdateGist.updateEntry(~content, ~key=guildId, ~config, ~entry) {
  | data => Ok(data)
  | exception JsError(e) => JsError(e)->Error
  }
}

type state = {
  maybeDiscordGuild: option<Types.guild>,
  maybeBrightIdGuild: option<Shared.BrightId.Gist.brightIdGuild>,
  loading: bool,
  submitting: bool,
  oauthGuild: option<Types.oauthGuild>,
}

let state = {
  maybeDiscordGuild: None,
  maybeBrightIdGuild: None,
  loading: true,
  submitting: false,
  oauthGuild: None,
}

type actions =
  | SetGuild(option<Types.guild>)
  | SetBrightIdGuild(option<Shared.BrightId.Gist.brightIdGuild>)
  | SetLoading(bool)
  | SetSubmitting(bool)
  | SetOAuthGuild(option<Types.oauthGuild>)

let reducer = (state, action) =>
  switch action {
  | SetGuild(maybeDiscordGuild) => {
      ...state,
      maybeDiscordGuild,
    }
  | SetBrightIdGuild(maybeBrightIdGuild) => {
      ...state,
      maybeBrightIdGuild,
    }
  | SetLoading(loading) => {...state, loading}
  | SetSubmitting(submitting) => {...state, submitting}
  | SetOAuthGuild(oauthGuild) => {...state, oauthGuild}
  }

let default = () => {
  open Remix
  let {guildId} = useParams()
  let {isAdmin, maybeUser, maybeDiscordGuild} = useLoaderData()
  let discordGuild = useAsyncValue()
  let context = useOutletContext()
  let account = Wagmi.useAccount()
  let matches = useMatches()

  let id = matches[matches->Array.length - 1]->Option.map(match => match.id)

  let fetcher = useFetcher()

  let (state, dispatch) = React.useReducer(reducer, state)
  let getGuildName = switch discordGuild {
  | Some(guild: Types.guild) => guild.name
  | None => "No Guild"
  }

  let sign = Wagmi.useSignMessage({
    "message": `I consent that the SP in this address is able to be used by members of ${getGuildName} Discord Server`,
    "onError": e =>
      switch e["name"] {
      | "ConnectorNotFoundError" =>
        ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error("No wallet found", ())
      | _ => ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(e["message"], ())
      },
    "onSuccess": _ => {
      let options = CreateFetcherSubmitOptions.make(~method="post", ())
      fetcher->Fetcher.submitWithOptions({"sponsorshipAddress": account.address}, ~options)
    },
  })

  React.useEffect1(() => {
    switch fetcher->Fetcher._type {
    | "init" =>
      fetcher->Fetcher.load(~href=`/guilds/${guildId}/Guilds_FetchGuild`)
      SetLoading(true)->dispatch
    | "actionSubmission" => SetSubmitting(true)->dispatch
    | "actionReload" =>
      switch fetcher->Remix.Fetcher.data->Nullable.toOption {
      | None => SetSubmitting(false)->dispatch
      | Some(_) => SetSubmitting(false)->dispatch
      }
    | "done" =>
      switch fetcher->Remix.Fetcher.data->Nullable.toOption {
      | None => SetLoading(false)->dispatch

      | Some(data) =>
        data["maybeDiscordGuild"]->SetGuild->dispatch
        data["maybeBrightIdGuild"]->SetBrightIdGuild->dispatch
        SetLoading(false)->dispatch
      }
    | _ => ()
    }

    None
  }, [fetcher])

  React.useEffect1(() => {
    let contextGuilds: array<Types.oauthGuild> = context["guilds"]
    switch contextGuilds->Array.findIndexOpt(guild => guild.id === guildId) {
    | None => ()
    | Some(index) => contextGuilds->Array.get(index)->SetOAuthGuild->dispatch
    }
    None
  }, [context])

  // let guildDisplay = switch state.guild {
  // | None => <div> {"That Discord Server does not exist"->React.string} </div>
  // | Some(guild) =>
  //   <div className="flex flex-col items-center">
  //     <div className="flex gap-4 w-full justify-start items-center">
  //       <img className="rounded-full h-24" src={guild->Helpers_Guild.iconUri} />
  //       <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
  //     </div>
  //     <div className="flex-row" />
  //   </div>
  // }

  let handleSign = (_: ReactEvent.Mouse.t) => sign["signMessage"]()

  let guildHeader = {
    <React.Suspense
      fallback={<p className="text-3xl text-white font-poppins p-4">
        {"Loading..."->React.string}
      </p>}>
      <Await resolve={maybeDiscordGuild}>
        {(discordGuild: Types.guild) =>
          <div className="flex gap-6 w-full justify-start items-center p-4">
            <img
              className="rounded-full h-24"
              src={discordGuild.icon
              ->Option.map(icon =>
                `https://cdn.discordapp.com/icons/${discordGuild.id}/${icon}.png`
              )
              ->Option.getWithDefault("")}
            />
            <p className="text-4xl font-bold text-white"> {discordGuild.name->React.string} </p>
            {isAdmin ? <AdminButton guildId={discordGuild.id} /> : <> </>}
          </div>}

        // | None => <p className="text-3xl text-white font-poppins p-4"> {"Loading..."->React.string} </p>

        // | Some(guild) =>
      </Await>
    </React.Suspense>
  }

  React.useEffect0(() => {
    switch context["rateLimited"] {
    | false => ()
    | true =>
      ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(
        "The bot is being rate limited. Please try again later",
        (),
      )
    }

    None
  })

  let showPopup =
    id
    ->Option.getWithDefault("")
    ->String.split("/")
    ->Array.reverse
    ->Array.get(0)
    ->Option.getWithDefault("") === "$guildId"

  <div className="flex-1">
    <ReactHotToast.Toaster />
    <div className="flex flex-col h-screen">
      <header className="flex flex-row justify-between md:justify-end items-center m-4">
        <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} maybeUser />
        <div className="flex flex-col md:flex-row gap-2 items-center justify-center">
          <RainbowKit.ConnectButton className="h-full" />
        </div>
      </header>
      {switch maybeUser {
      | None =>
        <div className="flex flex-col items-center justify-center h-full gap-4">
          <p className="text-3xl text-white font-poppins">
            {"Please login to continue"->React.string}
          </p>
          <DiscordLoginButton label="Login To Discord" />
        </div>

      | Some(_) =>
        <>
          {guildHeader}
          <div className="flex flex-1 flex-col  justify-around items-center text-center relative">
            <section
              className="width-full flex flex-col md:flex-row justify-around items-center w-full">
              // <div
              //   className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
              //   <div className="text-3xl font-bold text-white">
              //     {"Verified Server Members"->React.string}
              //   </div>
              //   <div
              //     className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              //     {"1000"->React.string}
              //   </div>
              // </div>
              // <div
              //   className="flex flex-col  rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
              //   <div className="text-3xl font-bold text-white"> {"Users Sponsored"->React.string} </div>
              //   <div
              //     className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              //     {"125"->React.string}
              //   </div>
              // </div>
              // <div
              //   className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2 border-2 border-white border-solid bg-extraDark">
              //   <div className="text-3xl font-bold text-white">
              //     {" Avaliable Sponsors"->React.string}
              //   </div>
              //   <div
              //     className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              //     {"0"->React.string}
              //   </div>
              // </div>
              // <p className="text-6xl text-slate-400 font-extrabold">
              //   {"Server Stats Coming Soon"->React.string}
              // </p>
              <Remix.Outlet />
            </section>
            {showPopup ? <SponsorshipsPopup /> : <> </>}
          </div>
        </>
      }}
    </div>
  </div>
}
