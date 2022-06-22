@module("remix") external useOutletContext: unit => 'a = "useOutletContext"

@react.component
let default = () => {
  let context = useOutletContext()
  let sign = Wagmi.useSignMessage({
    "message": `I am the owner of and would like to use its sponsorhips in
    X`,
  })

  let handleSign = (_: ReactEvent.Mouse.t) => sign["signMessage"]()

  <div className="p-4 h-full w-full">
    <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
    <div className="flex flex-col items-center justify-around  text-white h-full ">
      <button
        className="p-4 bg-brightid rounded-xl shadow-lg text-white disabled:bg-disabled disabled:text-slate-400 disabled:cursor-not-allowed font-poppins font-bold"
        onClick={handleSign}>
        {"Link Sponsorships to Discord"->React.string}
      </button>
      <img src={"/assets/brightid_logo.png"} alt="BrightID" className="w-64" />
    </div>
  </div>
}
