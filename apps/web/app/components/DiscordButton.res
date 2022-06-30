@react.component
let make = (~label) => {
  <Remix.Form action={`/auth/discord`} method={#post}>
    <button className="w-full p-4 bg-red-600 font-bold"> {label->React.string} </button>
  </Remix.Form>
}
