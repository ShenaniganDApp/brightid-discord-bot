type params = {guildId: string}
type loaderData = {
  maybeUser: option<RemixAuth.User.t>,
  isAdmin: bool,
  discordGuildPromise: promise<Nullable.t<Types.guild>>,
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
  external make: (
    ~resolve: promise<'a>,
    ~children: 'a => React.element,
    ~errorElement: React.element=?,
  ) => React.element = "Await"
}

let defaultLoader = {
  maybeUser: None,
  isAdmin: false,
  discordGuildPromise: Promise.resolve(Nullable.null),
}

module Lottie = {
  @react.component @module("react-lottie")
  external make: (
    ~options: {
      "animationData": JSON.t,
      "loop": bool,
      "autoplay": bool,
      "rendererSettings": {"preserveAspectRatio": string},
    },
    ~style: 'a=?,
    ~className: string=?,
  ) => React.element = "default"
}

let assignSPYellow = %raw(`require("~/lotties/assignSPYellow.json")`)
let assignSPRed = %raw(`require("~/lotties/assignSPRed.json")`)
let assignSPBlue = %raw(`require("~/lotties/assignSPBlue.json")`)
module AssignSponsorships = {
  let makeLottieOptions = animationData =>
    {
      "loop": true,
      "autoplay": true,
      "animationData": animationData,
      "rendererSettings": {
        "preserveAspectRatio": "xMidYMid slice",
      },
    }

  @react.component
  let make = (~maybeAddress) => {
    let transition = Remix.useTransition()
    <div className="flex flex-1 width-full height-full justify-center items-center">
      {switch maybeAddress {
      | None => <RainbowKit.ConnectButton />
      | Some(_) =>
        transition->Remix.Transition.state === "submitting"
          ? <div>
              <Lottie options={makeLottieOptions(assignSPYellow)} style={{"width": "25vw"}} />
              <p className="text-white font-bold text-24">
                {React.string(`Assigning Sponsorships to Server`)}
              </p>
            </div>
          : <Remix.Form className="flex flex-col width-full height-full">
              <div className="flex justify-around p-10">
                <label className="text-white font-bold text-32"> {"ID SP"->React.string} </label>
                <p className="text-white font-bold text-24"> {React.string(`${"1000"}`)} </p>
                <label className="text-white font-bold text-32">
                  {"Mainnet SP"->React.string}
                </label>
                <p className="text-white font-bold text-24"> {React.string(`${"1000"}`)} </p>
              </div>
              <input
                className="appearance-none text-white bg-transparent text-3xl text-center p-5"
                type_="number"
                name="sponsorships"
                defaultValue="1"
              />
              <button className="text-white p-5" type_="submit"> {React.string("Assign")} </button>
            </Remix.Form>
      }}
    </div>
  }
}

let loader: Remix.loaderFunction<loaderData> = async ({request, params}) => {
  open DiscordServer

  let guildId = params->Dict.get("guildId")->Option.getWithDefault("")

  let maybeUser = switch await RemixAuth.Authenticator.isAuthenticated(
    AuthServer.authenticator,
    request,
  ) {
  | data => data->Nullable.toOption
  | exception JsError(_) => None
  }

  switch maybeUser {
  | None => defer(defaultLoader)
  | Some(user) =>
    try {
      let discordGuildPromise = fetchDiscordGuildFromId(~guildId)

      let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId

      let (guildMember, guildRoles) = await Promise.all2((
        fetchGuildMemberFromId(~guildId, ~userId),
        fetchGuildRoles(~guildId),
      ))

      let memberRoles = switch guildMember->Nullable.toOption {
      | None => []
      | Some(guildMember) => guildMember.roles
      }
      let guildRoles = switch guildRoles {
      | data => data
      | exception JsError(_) => []
      }
      let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
      // let isOwner = switch discordGuild->Nullable.toOption {
      // | None => false
      // | Some(guild) => guild.owner_id === userId
      // }
      defer({
        maybeUser,
        isAdmin,
        discordGuildPromise,
      })
    } catch {
    | Exn.Error(e) =>
      Console.error(e)
      defer(defaultLoader)
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

let default = () => {
  open Remix
  let {isAdmin, maybeUser, discordGuildPromise} = useLoaderData()

  let context = useOutletContext()
  let matches = useMatches()
  let {address: maybeAddress} = Wagmi.useAccount()

  let id = matches[matches->Array.length - 1]->Option.map(match => match.id)

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

  let guildHeader =
    <React.Suspense
      fallback={<p className="text-3xl text-white font-poppins p-4">
        {"Loading..."->React.string}
      </p>}>
      <Await resolve={discordGuildPromise}>
        {maybeDiscordGuild =>
          maybeDiscordGuild
          ->Nullable.toOption
          ->Option.mapWithDefault(<> </>, discordGuild => {
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
            </div>
          })}
      </Await>
    </React.Suspense>

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
        <SidebarToggle handleIsSidebarVisible={context["handleIsSidebarVisible"]} maybeUser />
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
          <div className="flex flex-1 flex-col  justify-around items-center relative">
            <section
              className="relative w-full lg:w-[90%] flex flex-col lg:flex-row justify-around items-center border-y-2 lg:border-4 border-extraDark lg:rounded-xl max-w-4xl ">
              <div
                className="flex flex-row flex-start lg:flex-col flex-1 h-full w-full border-b-2 lg:border-r-2 border-dark ">
                <div
                  className="flex flex-col flex-start flex-1 border-r-2 lg:border-b-2 border-extraDark p-5 bg-dark">
                  <img src="/assets/verified_icon.svg" className="pb-4 h-14 w-14" />
                  <p className="text-5xl text-brightOrange py-2"> {"0"->React.string} </p>
                  <p className="text-sm text-white"> {"Verified Users"->React.string} </p>
                </div>
                <div
                  className="flex flex-col flex-start flex-1 border-r-2 lg:border-b-2 border-extraDark p-5 bg-dark">
                  <img src="/assets/gift_icon.svg" className="pb-4 h-14 w-14" />
                  <p className="text-5xl text-brightBlue py-2"> {"0"->React.string} </p>
                  <p className="text-sm text-white"> {"Available Sponsorships"->React.string} </p>
                </div>
                <div
                  className="flex flex-col flex-start border-r-2 border-extraDark flex-1 p-5 bg-dark">
                  <img src="/assets/unlock_icon.svg" className="pb-4 h-14 w-14" />
                  <p className="text-5xl text-brightGreen py-2"> {"0"->React.string} </p>
                  <p className="text-sm text-white"> {"Used Sponsorships"->React.string} </p>
                </div>
              </div>
              <div className="flex-2">
                <AssignSponsorships maybeAddress />
              </div>
              <Remix.Outlet />
            </section>
            // {showPopup ? <SponsorshipsPopup /> : <> </>}
          </div>
        </>
      }}
    </div>
  </div>
}
