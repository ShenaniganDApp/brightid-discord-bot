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

@react.component
let default = () => {
  let context = Remix.useOutletContext()
  let fetcher = Remix.useFetcher()

  React.useEffect1(() => {
    open Remix
    if fetcher->Fetcher._type === "init" {
      fetcher->Fetcher.load(~href=`/Root_FetchBrightIDDiscord`)
    }
    None
  }, [fetcher])

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

  let linkBrightId = switch fetcher->Remix.Fetcher._type {
  | "done" =>
    switch fetcher->Remix.Fetcher.data->Js.Nullable.toOption {
    | None => <DiscordLoginButton label="Login to Discord" />
    | Some(data) =>
      switch data["user"]->Js.Nullable.toOption {
      | None => <DiscordLoginButton label="Login to Discord" />
      | Some(_) =>
        switch data["verifyStatus"] {
        | Types.Unique =>
          <p className="text-2xl md:text-3xl font-semibold text-white">
            {"Congrats on being Verified with BrightID"->React.string}
          </p>
        | Types.NotVerified =>
          <p className="text-2xl md:text-3xl font-semibold text-white">
            {"You are not Verified"->React.string}
          </p>
        | Types.NotSponsored =>
          <p className="text-2xl md:text-3xl font-semibold text-white">
            {"You are not Sponsored"->React.string}
          </p>
        | Types.NotLinked =>
          <>
            <div className="flex flex-row w-full justify-center gap-2">
              <p className="text-2xl md:text-3xl font-semibold text-white">
                {"Link  "->React.string}
              </p>
              <p
                className=" text-2xl md:text-3xl font-semibold text-brightid stroke-black stroke-1">
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
        | Types.Unknown =>
          <p className="text-2xl md:text-3xl font-semibold text-white">
            {"Something went wrong checking your BrightId status"->React.string}
          </p>
        }
      }
    }
  | "normalLoad" =>
    <div className=" animate-pulse  ">
      <div className="h-24 bg-gray-300 w-52 rounded-md " />
    </div>
  | _ =>
    <div className=" animate-pulse  ">
      <div className="h-24 bg-gray-300 w-52 rounded-md " />
    </div>
  }

  <div className="flex flex-col flex-1">
    <header className="flex flex-row justify-between md:justify-end m-4">
      <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
      <InviteButton />
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
            {verificationCount}
          </div>
          <div
            className="flex flex-col rounded-xl justify-around items-center text-center h-32 w-60 md:h-48 m-2">
            <div className="text-3xl font-bold text-white"> {"Sponsorships"->React.string} </div>
            <div
              className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white">
              {"0"->React.string}
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
