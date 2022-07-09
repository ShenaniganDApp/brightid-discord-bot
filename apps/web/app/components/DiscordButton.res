@react.component
let make = (~label) => {
  <Remix.Form action={`/auth/discord`} method={#post}>
    <button className="w-full p-6 bg-discord font-bold rounded-xl text-2xl text-white">
      {label->React.string}
    </button>
  </Remix.Form>
}
