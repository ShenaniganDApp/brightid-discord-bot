open Promise

@module("remix") external useOutletContext: unit => 'a = "useOutletContext"

module Canvas = {
  type t
  @module("canvas") @scope("default")
  external createCanvas: (int, int) => t = "createCanvas"
  @send external toBuffer: t => Node.Buffer.t = "toBuffer"
}

module QRCode = {
  type t
  @module("qrcode") external toCanvas: (Canvas.t, string) => Promise.t<unit> = "toCanvas"
}

let authenticator: RemixAuth.Authenticator.t = %raw(`require( "~/auth.server").auth`)

type loaderData = {user: Js.Nullable.t<RemixAuth.User.t>, verificationCount: Js.Nullable.t<float>}

let brightIdVerificationEndpoint = "https://app.brightid.org/node/v5/verifications/Discord"

let loader: Remix.loaderFunction<loaderData> = ({request}) => {
  open Webapi.Fetch

  authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    let init = RequestInit.make(~method_=Get, ())

    brightIdVerificationEndpoint
    ->Request.makeWithInit(init)
    ->fetchWithRequest
    ->then(res => res->Response.json)
    ->then(json => {
      let data =
        json->Js.Json.decodeObject->Belt.Option.getUnsafe->Js.Dict.get("data")->Belt.Option.getExn
      let verificationCount =
        data
        ->Js.Json.decodeObject
        ->Belt.Option.getUnsafe
        ->Js.Dict.get("count")
        ->Belt.Option.flatMap(Js.Json.decodeNumber)
        ->Js.Nullable.fromOption

      {user: user, verificationCount: verificationCount}->resolve
    })
  })
}

@react.component
let default = () => {
  let context = useOutletContext()
  let {user, verificationCount} = Remix.useLoaderData()
  let verificationCount = switch verificationCount->Js.Nullable.toOption {
  | None => "N/A"
  | Some(count) => count->Belt.Float.toString
  }

  let linkBrightId = switch user->Js.Nullable.toOption {
  | None => <DiscordButton label="Login to Discord" />
  | Some(_) => <>
      <div className="flex flex-row w-full justify-center gap-2">
        <p className="text-2xl md:text-3xl font-semibold text-white"> {"Link  "->React.string} </p>
        <p className=" text-2xl md:text-3xl font-semibold text-brightid stroke-black stroke-1">
          {"BrightID "->React.string}
        </p>
        <p className="text-2xl md:text-3xl font-semibold text-white">
          {" to Discord"->React.string}
        </p>
      </div>
      <div
        className="px-8 py-4 bg-white border-brightid border-4 text-dark text-2xl font-semibold rounded-xl shadow-lg">
        {"Link to Discord"->React.string}
      </div>
    </>
  }
  <div className="flex flex-col flex-1">
    <header className="flex flex-row justify-between md:justify-end m-4">
      <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} /> <InviteButton />
    </header>
    <div className="flex flex-1 w-full justify-center ">
      <div className="flex flex-1 flex-col  justify-around items-center text-center">
        <span
          className="text-4xl md:text-8xl font-poppins font-extrabold text-transparent bg-[size:1000px_100%] bg-clip-text bg-gradient-to-l from-brightid to-white animate-text-scroll">
          {"BrightID Discord Bot"->React.string}
        </span>
        <section
          className="width-full flex flex-col md:flex-row justify-around items-center w-full">
          <div
            className="flex flex-col  rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2">
            <div className="text-3xl font-bold text-white"> {"Verifications"->React.string} </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {verificationCount->React.string}
            </div>
          </div>
          <div
            className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2">
            <div className="text-3xl font-bold text-white"> {"Sponsorships"->React.string} </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {verificationCount->React.string}
            </div>
          </div>
        </section>
        <section className="flex justify-center items-center flex-col w-full gap-4">
          {linkBrightId}
        </section>
      </div>
      // <div className="bg-discordLogo h-10 w-4" />
    </div>
  </div>
}
