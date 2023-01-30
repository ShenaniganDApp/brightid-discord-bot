%%raw(`import styles from "@reach/dialog/styles.css";`)

module Dialog = {
  @react.component @module("@reach/dialog")
  external make: (
    ~children: React.element,
    ~isOpen: bool=?,
    ~onDismiss: unit => unit=?,
  ) => React.element = "default"
}

let links = () => {
  [
    {
      "rel": "stylesheet",
      "href": %raw(`styles`),
    },
  ]
}

@react.component
let default = () => {
  let context = Remix.useOutletContext()
  let sign = Wagmi.useSignMessage({
    "message": `I am the owner of and would like to use its sponsorhips in
    X`,
  })
  <Dialog isOpen={true}>
    <div className="p-4 h-full w-full"> {React.string("Helli")} </div>
  </Dialog>

  // <div className="flex flex-col items-center justify-around  text-white h-full ">
  //   <button
  //     className="p-4 bg-brightid rounded-xl shadow-lg text-white disabled:bg-disabled disabled:text-slate-400 disabled:cursor-not-allowed font-poppins font-bold"
  //     onClick={handleSign}>
  //     {"Link Sponsorships to Discord"->React.string}
  //   </button>
  //   <img src={"/assets/brightid_logo.png"} alt="BrightID" className="w-64" />
  // </div>
}
