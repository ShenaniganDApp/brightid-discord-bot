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

module BrightIdToolTip = {
  @react.component
  let make = (~fetcher) => {
    switch fetcher->Remix.Fetcher._type {
    | "done" =>
      switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
      | None => <> </>
      | Some(data) =>
        switch data["user"]->Js.Nullable.toOption {
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
    | Some(user) =>
      switch fetcher->Remix.Fetcher._type {
      | "done" =>
        switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
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
                {"Attend a Verification Party to get Verified"->React.string}
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

let loader: Remix.loaderFunction<loaderData> = async ({request, params}) => {
  let maybeUser = switch await RemixAuth.Authenticator.isAuthenticated(
    AuthServer.authenticator,
    request,
  ) {
  | maybeUser => maybeUser->Js.Nullable.toOption
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

  let unusedSponsorships = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p
        className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
        {data["unusedSponsorships"]->Belt.Int.toString->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  }

  let usedSponsorships = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p
        className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
        {(data["unusedSponsorships"] - data["assignedSponsorships"])
        ->Belt.Int.toString
        ->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  }

  let verificationCount = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
    | None => <p className="text-white"> {"N/A"->React.string} </p>
    | Some(data) =>
      <p
        className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
        {data["verificationCount"]->Belt.Int.toString->React.string}
      </p>
    }
  | "normalLoad" =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse  ">
      <div className="h-8 bg-gray-300 w-8 rounded-md " />
    </div>
  }

  let discordLogoutButton = switch maybeUser {
  | None => <> </>
  | Some(_) => <DiscordLogoutButton label={`Log out of Discord`} />
  }

  <div className="flex flex-col flex-1">
    <section className="flex justify-center items-center flex-col w-full gap-4 relative">
      <BrightIdToolTip fetcher />
    </section>
    <header className="flex flex-row justify-between md:justify-end m-4">
      <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} maybeUser />
      <div className="flex flex-col-reverse md:flex-row items-center justify-center gap-4 ">
        <div> {discordLogoutButton} </div>
        <RainbowKit.ConnectButton className="h-full" />
      </div>
    </header>
    <div className="flex flex-1 w-full justify-center ">
      <div className="flex flex-1 flex-col justify-around items-center text-center h-full">
        <div>
          <span
            className="px-2 text-4xl md:text-6xl lg:text-8xl lg:leading-loose font-poppins font-extrabold text-transparent bg-[size:1000px_100%] bg-clip-text bg-gradient-to-l from-brightid to-white animate-textscroll ">
            {"Unique Discord  "->React.string}
          </span>
          <p className=" text-slate-300 text-4xl md:text-6xl lg:text-8xl font-poppins font-bold">
            {"Dashboard"->React.string}
          </p>
        </div>
        <section
          className="width-full flex flex-col md:flex-row justify-around items-center w-full py-2">
          <div className="flex flex-col  rounded-xl justify-around items-center text-center ">
            <div className="text-2xl font-bold text-white p-2">
              {"Available Sponsorships"->React.string}
            </div>
            {unusedSponsorships}
          </div>
          <div
            className="flex flex-col rounded-xl justify-around items-center text-center px-6 py-10">
            <div className="text-2xl font-bold text-white p-2">
              {"Verifications"->React.string}
            </div>
            {verificationCount}
          </div>
          <div className="flex flex-col rounded-xl justify-around items-center text-center">
            <div className="text-2xl font-bold text-white p-2">
              {"Total Used Sponsors"->React.string}
            </div>
            <div
              className="text-2xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {usedSponsorships}
            </div>
          </div>
        </section>
        <section className="flex justify-center items-center pb-3">
          <BrightIdVerificationActions fetcher maybeUser maybeDeeplink />
        </section>
      </div>
      // <div className="bg-discordLogo h-10 w-4" />
    </div>
  </div>
}
