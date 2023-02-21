@react.component
let make = (~label) => {
  <Remix.Form action={`/auth/discord`} method={#post}>
    <button
      className="w-full p-6 border-2 border-discord text-discord bg-transparent font-bold rounded-xl text-2xl hover:bg-discord hover:text-white">
      {label->React.string}
    </button>
  </Remix.Form>
}
