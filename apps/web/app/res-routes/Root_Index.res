module QRCodeSvg = {
  @react.component @module("qrcode.react")
  external make: (~value: string) => React.element = "QRCodeSVG"
}
module StatusToolTip = {
  @react.component
  let make = (~statusMessage, ~color) => {
    <div className={`${color} w-full text-center py-1`}>
      <p className="text-xl font-semibold text-white"> {statusMessage->React.string} </p>
    </div>
  }
}

@get external innerWidth: Dom.window => int = "innerWidth"
// let getWindowDimensions = () => {
//   let innerWidth = window()->innerWidth
//   let innerHeight = window->React.Dom.innerHeight

//   {innerWidth, innerHeight}
// }

// let useWindowDimensions = () => {
//   let (windowDimensions, setWindowDimensions) = React.useState(_ => getWindowDimensions())

//   React.useEffect0(() => {
//     let handleResize = () => {
//       setWindowDimensions(getWindowDimensions())
//     }

//     window.addEventListener("resize", handleResize)
//     Some(() => window.removeEventListener("resize", handleResize))
//   }, [])

//   windowDimensions
// }

module BrightIdToolTip = {
  @react.component
  let make = (~fetcher) => {
    switch fetcher->Remix.Fetcher._type {
    | "done" =>
      switch fetcher->Remix.Fetcher.data->Nullable.toOption {
      | None => <> </>
      | Some(data) =>
        switch data["user"]->Nullable.toOption {
        | None => <> </>
        | Some(_) =>
          switch data["verifyStatus"] {
          | Types.Unique =>
            <StatusToolTip color="bg-green-600" statusMessage="Verified with BrightID" />
          | Types.NotVerified =>
            <StatusToolTip color="bg-red-600" statusMessage="You are not Verified" />
          | Types.NotSponsored =>
            <StatusToolTip color="bg-red-600" statusMessage="You are not Sponsored" />
          | Types.NotLinked =>
            <StatusToolTip
              color="bg-red-600" statusMessage="You have not linked BrightId to Discord"
            />
          | Types.Unknown =>
            <StatusToolTip
              color="bg-red-600"
              statusMessage="Something went wrong when checking your BrightId status"
            />
          }
        }
      }
    | "normalLoad" => <> </>
    | _ => <> </>
    }
  }
}
module BrightIdVerificationActions = {
  @react.component
  let make = (~fetcher, ~maybeUser, ~maybeDeeplink) => {
    switch maybeUser {
    | None => <DiscordLoginButton label="Login to Discord" />
    | Some(_) =>
      switch fetcher->Remix.Fetcher._type {
      | "done" =>
        switch fetcher->Remix.Fetcher.data->Nullable.toOption {
        | None => <> </>
        | Some(data) =>
          switch data["verifyStatus"] {
          | Types.Unique => <> </>
          | Types.NotVerified =>
            <a href="https://meet.brightid.org/#/" target="_blank" className="text-2xl">
              <button
                className="p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white">
                {"Attend a Verification Party to get Verified"->React.string}
              </button>
            </a>
          | Types.NotSponsored =>
            <a href="https://apps.brightid.org/" target="_blank" className="text-2xl">
              <button
                className="p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white">
                {"Get Sponsored by a BrightID App"->React.string}
              </button>
            </a>
          | Types.NotLinked =>
            switch maybeDeeplink {
            | None =>
              <Remix.Form method={#get} action="/">
                <button
                  type_="submit"
                  className="p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white">
                  {"Link BrightID to Discord"->React.string}
                </button>
              </Remix.Form>
            | Some(deepLink) =>
              <div className="flex flex-col gap-3 items-center justify-around">
                <p className="text-2xl text-white">
                  {"Scan this code in the BrightID App"->React.string}
                </p>
                <QRCodeSvg value=deepLink />
                <a className="text-white" href={deepLink}>
                  {"Click here for mobile"->React.string}
                </a>
              </div>
            }
          | Types.Unknown => <> </>
          }
        }
      | "normalLoad" => <> </>
      | _ => <> </>
      }
    }
  }
}

type loaderData = {maybeUser: option<RemixAuth.User.t>, maybeDeeplink: option<string>}

let loader: Remix.loaderFunction<loaderData> = async ({request}) => {
  let maybeUser = switch await RemixAuth.Authenticator.isAuthenticated(
    AuthServer.authenticator,
    request,
  ) {
  | maybeUser => maybeUser->Nullable.toOption
  | exception JsError(_) => None
  }
  let maybeDiscordId = switch maybeUser {
  | Some(user) => user->RemixAuth.User.getProfile->RemixAuth.User.getId->Some
  | None => None
  }
  switch maybeDiscordId {
  | Some(discordId) =>
    let contextId = UUID.v5(discordId, Remix.process["env"]["UUID_NAMESPACE"])
    let deepLink = BrightId.generateDeeplink(~context=Shared.Constants.context, ~contextId, ())
    {maybeUser, maybeDeeplink: Some(deepLink)}
  | None => {maybeUser, maybeDeeplink: None}
  }
}

@react.component
let default = () => {
  let context = Remix.useOutletContext()
  let fetcher = Remix.useFetcher()
  let {maybeUser, maybeDeeplink} = Remix.useLoaderData()

  React.useEffect1(() => {
    open Remix
    if fetcher->Fetcher._type === "init" {
      fetcher->Fetcher.load(~href=`/Root_FetchBrightIDDiscord`)
    }
    None
  }, [fetcher])

  let discordLogoutButton = switch maybeUser {
  | None => <> </>
  | Some(_) => <DiscordLogoutButton label={`Log out of Discord`} />
  }

  let unusedSponsorships = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p className="text-3xl md:text-6xl font-semibold text-brightBlue">
        {data["unusedSponsorships"]->Belt.Int.toString->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse py-2 ">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse py-2">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  }

  let verificationCount = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p className="text-3xl md:text-6xl font-semibold text-brightOrange">
        {data["verificationCount"]->Belt.Int.toString->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse py-2 ">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse py-2 ">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  }

  let usedSponsorships = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p className="text-3xl md:text-6xl font-semibold  text-brightGreen">
        {(data["assignedSponsorships"] - data["unusedSponsorships"])
        ->Belt.Int.toString
        ->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse  py-2">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse  py-2">
      <div className="h-12 bg-gray-300 w-16 rounded-md " />
    </div>
  }

  <div className="flex flex-col flex-1">
    <header className="flex flex-row justify-between md:justify-end m-5">
      <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} maybeUser />
      <div className="flex flex-col-reverse md:flex-row items-center justify-center gap-4 ">
        <div> {discordLogoutButton} </div>
        <RainbowKit.ConnectButton className="h-full" />
      </div>
    </header>
    <section className="flex justify-center items-center flex-col w-full gap-4 relative">
      <BrightIdToolTip fetcher />
    </section>
    <div className="flex flex-1 w-full justify-center ">
      <div className="flex flex-1 flex-col justify-around items-center h-full">
        <div className="">
          <div className="flex items-center">
            <p className="relative pr-2 text-xl md:text-3xl text-white font-poppins font-bold">
              {"BrightID  "->React.string}
            </p>
            <div className="h-0 border border-[#FFFFFF] bg-white flex-1" />
          </div>
          <p
            className="relative py-3 text-3xl md:text-7xl font-pressStart font-extrabold text-white tracking-tight">
            {"DISCORD BOT  "->React.string}
          </p>
          <div className="flex items-center">
            <div className="h-0 border border-[#FFFFFF] bg-white flex-1" />
            <p className="relative text-white text-xl md:text-3xl font-poppins font-bold pl-2">
              {"Command Center"->React.string}
            </p>
          </div>
        </div>
        {maybeUser->Belt.Option.isSome ? <> </> : <InviteButton />}
        <section className=" flex flex-col md:flex-row justify-around items-center w-full px-10 ">
          <div
            className="w-full flex-1 relative flex flex-col border border-brightBlue rounded-xl justify-center items-start bg-extraDark p-6 md:p-12">
            <img src="/assets/gift_icon.svg" className="pb-4" />
            {unusedSponsorships}
            <p className="text-white font-poppins text-xs font-semibold">
              {"Available Sponsorships"->React.string}
            </p>
          </div>
          <div
            className="w-full my-6 md:mx-10 md:my-0 flex-1 relative flex flex-col border border-brightOrange rounded-xl justify-center items-start   bg-extraDark p-6 md:p-12">
            <img src="/assets/verified_icon.svg" className="pb-4" />
            {verificationCount}
            <p className=" text-white font-poppins text-xs font-semibold">
              {"Verifications"->React.string}
            </p>
          </div>
          <div
            className="w-full flex-1 relative flex flex-col border border-brightGreen rounded-xl justify-center items-start  bg-extraDark p-6 md:p-12">
            <img src="/assets/unlock_icon.svg" className="pb-4" />
            {usedSponsorships}
            <p className=" text-white font-poppins text-xs font-semibold">
              {"Used Sponsorships"->React.string}
            </p>
            <div
              className="text-2xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white"
            />
          </div>
        </section>
        <section className="flex flex-col justify-center items-center pb-2 gap-8">
          <BrightIdVerificationActions fetcher maybeUser maybeDeeplink />
        </section>
      </div>
      // <div className="bg-discordLogo h-10 w-4" />
    </div>
  </div>
}
