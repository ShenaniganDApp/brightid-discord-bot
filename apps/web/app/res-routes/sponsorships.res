@react.component
let make = () => {
  let sign = Wagmi.useSignMessage({
    "message": `I am the owner of and would like to use its sponsorhips in
    X`,
  })

  let handleSign = (_: ReactEvent.Mouse.t) => sign["signMessage"]()
  <section>
    <div className="flex flex-col items-center justify-around min-h-screen text-white layout">
      <button
        className="p-4 bg-brightid rounded-xl shadow-lg text-white disabled:bg-disabled disabled:text-slate-400 disabled:cursor-not-allowed font-poppins font-bold"
        onClick={handleSign}>
        {"Link Sponsorships to Discord"->React.string}
      </button>
      <img src={"/assets/brightid_logo.png"} alt="BrightID" className="w-64" />
    </div>
  </section>
}
