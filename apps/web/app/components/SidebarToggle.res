@react.component
let make = (~handleToggleSidebar, ~maybeUser) => {
  let visibility = maybeUser->Option.isSome ? "visible" : "invisible"
  <div
    className={`${visibility} md:hidden cursor-pointer w-12 h-12 bg-dark text-center text-white rounded-full flex justify-center items-center font-xl`}
    onClick={_ => handleToggleSidebar(true)}>
    <ReactIcons.FaBars size={30} />
  </div>
}
