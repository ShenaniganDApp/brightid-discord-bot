exception IndexError(string)

@module("remix") external useOutletContext: unit => 'a = "useOutletContext"

module BrightID = {
  @module("brightid_sdk")
  external generateDeepLink: (
    ~context: string,
    ~contextId: string,
    ~nodeUrl: string=?,
    unit,
  ) => string = "generateDeepLink"
}

module UUID = {
  type t = string
  type name = UUIDName(string)
  @module("uuid") external v5: (string, string) => t = "v5"
}

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

// let uuidNamespace = Remix.process["env"]["uuidNamespace"]

// let uuidNamespace = switch config {
// | Ok(config) => config["uuidNamespace"]
// | Error(err) => err->IndexError->raise
// }

let context = "Discord"

@react.component
let default = () => {
  let context = useOutletContext()

  // let getDeepLink = discordId => {
  //   let contextId = UUID.v5(uuidNamespace, discordId)
  //   BrightID.generateDeepLink(~context, ~contextId, ())
  // }

  // let createCanvasFromDeepLink = deepLink => {
  //   let canvas = Canvas.createCanvas(700, 250)

  //   QRCode.toCanvas(canvas, deepLink)->then(canvas => {
  //     <canvas
  //   })
  //
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
