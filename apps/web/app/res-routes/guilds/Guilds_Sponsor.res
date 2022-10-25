type searchParams
@module("remix") external useSearchParams: unit => array<searchParams> = "useSearchParams"

@return(nullable) @send external getSearchParam: (searchParams, string) => option<string> = "get"

@react.component
let default = () => {
  let context = Remix.useOutletContext()
  let [searchParams] = useSearchParams()
  let sign = Wagmi.useSignMessage({
    "message": `I am the owner of and would like to use its sponsorhips in
    X`,
  })

  let sponsorshipModal = switch searchParams->getSearchParam("setup_sponsorships") {
  | None => <> </>
  | Some(_) => <SponsorshipsModal />
  }

  <div className="p-4 h-full w-full">
    <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
    {"Layout"->React.string}
    <div>
      <Remix.Outlet />
    </div>
    {sponsorshipModal}

    // <div className="flex flex-col items-center justify-around  text-white h-full ">
    //   <button
    //     className="p-4 bg-brightid rounded-xl shadow-lg text-white disabled:bg-disabled disabled:text-slate-400 disabled:cursor-not-allowed font-poppins font-bold"
    //     onClick={handleSign}>
    //     {"Link Sponsorships to Discord"->React.string}
    //   </button>
    //   <img src={"/assets/brightid_logo.png"} alt="BrightID" className="w-64" />
    // </div>
  </div>
}
