@react.component
let make = (~handleToggleSidebar) => {
  <div
    className="md:hidden cursor-pointer w-12 h-12 bg-dark text-center text-white rounded-full flex justify-center items-center font-xl"
    onClick={_ => handleToggleSidebar(true)}>
    <ReactIcons.FaBars size={30} />
  </div>
}
