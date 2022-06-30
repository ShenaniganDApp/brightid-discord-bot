exception IndexError(string)

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

type guild = {
  id: string,
  name: string,
  // icon: Js.Nullable.t<string>, Need to handle null case
  permissions: float,
}

type loaderData = {user: option<RemixAuth.User.t>, guilds: option<array<guild>>}

@react.component
let default = () => {
  let context = useOutletContext()
  <div className="flex p-4 h-full w-full justify-center ">
    <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
    <div className="flex flex-1 flex-col  justify-around items-center">
      <p className="text-3xl md:text-5xl font-poppins font-extrabold">
        {"BrightID Discord Bot"->React.string}
      </p>
      <section className="flex justify-center items-center flex-col w-full gap-4">
        <div className="flex flex-row w-full justify-center gap-2">
          <p className="text-2xl md:text-3xl font-semibold"> {"Link  "->React.string} </p>
          <p className=" text-2xl md:text-3xl font-semibold text-brightid stroke-black stroke-1">
            {"BrightID "->React.string}
          </p>
          <p className="text-2xl md:text-3xl font-semibold"> {" to Discord"->React.string} </p>
        </div>
        <div
          className="px-8 py-4 bg-white border-brightid border-4 text-dark text-2xl font-semibold rounded-xl shadow-lg">
          {"Link to Discord"->React.string}
        </div>
      </section>
    </div>
    <div className="bg-discordLogo h-10 w-4" />
  </div>
}
