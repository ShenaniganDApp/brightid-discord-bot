type params = {guildId: string}
type loaderData = {maybeUser: option<RemixAuth.User.t>, isAdmin: bool}

let loader: Remix.loaderFunction<loaderData> = async ({request, params}) => {
  open DiscordServer
  open Promise

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")

  let maybeUser = switch await RemixAuth.Authenticator.isAuthenticated(
    AuthServer.authenticator,
    request,
  ) {
  | data => data->Js.Nullable.toOption
  | exception JsError(e) => None
  }

  switch maybeUser {
  | None => {maybeUser, isAdmin: false}
  | Some(user) =>
    let maybeDiscordGuild = switch await fetchDiscordGuildFromId(~guildId) {
    | data => data->Js.Nullable.toOption
    | exception JsError(_) => None
    }
    let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId
    let guildMember = switch await fetchGuildMemberFromId(~guildId, ~userId) {
    | data => data->Js.Nullable.toOption
    | exception JsError(_) => None
    }
    let memberRoles = switch guildMember {
    | None => []
    | Some(guildMember) => guildMember.roles
    }
    let guildRoles = switch await fetchGuildRoles(~guildId) {
    | data => data
    | exception JsError(_) => []
    }
    let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
    let isOwner = switch maybeDiscordGuild {
    | None => false
    | Some(guild) => guild.owner_id === userId
    }
    {
      maybeUser,
      isAdmin: isAdmin || isOwner,
    }
  }
}

let action: Remix.actionFunction<'a> = async ({request, params}) => {
  open Webapi.Fetch
  open Guilds_AdminSubmit
  open Shared.Decode

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")

  let _ = switch await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request) {
  | data => Some(data)
  | exception JsError(_) => None
  }

  let data = await Request.formData(request)

  let {sponsorshipAddress} = Form.make(data)

  open WebUtils_Gist
  let config = makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )
  let content = await ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)
  let prevEntry = switch content->Js.Dict.get(guildId) {
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
  guild: option<Types.guild>,
  brightIdGuild: option<Shared.BrightId.Gist.brightIdGuild>,
  loading: bool,
  submitting: bool,
  oauthGuild: option<Types.oauthGuild>,
}

let state = {
  guild: None,
  brightIdGuild: None,
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
  | SetGuild(guild) => {
      ...state,
      guild,
    }
  | SetBrightIdGuild(brightIdGuild) => {
      ...state,
      brightIdGuild,
    }
  | SetLoading(loading) => {...state, loading}
  | SetSubmitting(submitting) => {...state, submitting}
  | SetOAuthGuild(oauthGuild) => {...state, oauthGuild}
  }

let default = () => {
  open Remix
  let {guildId} = useParams()
  let {isAdmin, maybeUser} = useLoaderData()
  let context = useOutletContext()
  let account = Wagmi.useAccount()

  let fetcher = useFetcher()

  let (state, dispatch) = React.useReducer(reducer, state)

  let getGuildName = switch state.guild {
  | Some(guild) => guild.name
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
      switch account["data"]->Js.Nullable.toOption {
      | None => Js.log(account)
      | Some(data) =>
        let options = CreateFetcherSubmitOptions.make(~method="post", ())
        fetcher->Fetcher.submitWithOptions(
          {"sponsorshipAddress": data["address"]->Js.Nullable.toOption},
          ~options,
        )
      }
    },
  })

  React.useEffect1(() => {
    switch fetcher->Fetcher._type {
    | "init" =>
      fetcher->Fetcher.load(~href=`/guilds/${guildId}/Guilds_FetchGuild`)
      SetLoading(true)->dispatch
    | "actionSubmission" => SetSubmitting(true)->dispatch
    | "actionReload" =>
      switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
      | None => SetSubmitting(false)->dispatch
      | Some(data) =>
        Js.log(data)
        SetSubmitting(false)->dispatch
      }
    | "done" =>
      switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
      | None => SetLoading(false)->dispatch

      | Some(data) =>
        data["guild"]->SetGuild->dispatch
        data["brightIdGuild"]->SetBrightIdGuild->dispatch
        SetLoading(false)->dispatch
      }
    | _ => ()
    }

    None
  }, [fetcher])

  React.useEffect1(() => {
    let contextGuilds: array<Types.oauthGuild> = context["guilds"]
    switch contextGuilds->Belt.Array.getIndexBy(guild => guild.id === guildId) {
    | None => ()
    | Some(index) => contextGuilds->Belt.Array.get(index)->SetOAuthGuild->dispatch
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

  let guildHeader = switch state.oauthGuild {
  | None => <p className="text-3xl text-white font-poppins p-4"> {"Loading..."->React.string} </p>

  | Some(guild) =>
    <div className="flex gap-6 w-full justify-start items-center p-4">
      <img
        className="rounded-full h-24"
        src={guild.icon
        ->Belt.Option.map(icon => `https://cdn.discordapp.com/icons/${guild.id}/${icon}.png`)
        ->Belt.Option.getWithDefault("")}
      />
      <p className="text-4xl font-bold text-white"> {guild.name->React.string} </p>
      {isAdmin ? <AdminButton guildId={guildId} /> : <> </>}
    </div>
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

  <div className="">
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
              <p className="text-6xl text-slate-400 font-extrabold">
                {"Server Stats Coming Soon"->React.string}
              </p>
            </section>
            <SponsorshipsPopup isAdmin sign={handleSign} />
          </div>
        </>
      }}
    </div>
  </div>
}
