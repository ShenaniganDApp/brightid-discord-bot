@react.component
let make = (~label) => {
  <Remix.Form action={`/auth/discordLogout`} method={#post} reloadDocument={true}>
    <button
      className="w-full p-2 bg-red-600 font-bold rounded-xl text-large text-white text-center items-center h-[38px]">
      {label->React.string}
    </button>
  </Remix.Form>
}
