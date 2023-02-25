@react.component
let make = (~guildId) => {
  <Remix.Link to={`/guilds/${guildId}/admin`} prefetch={#intent}>
    <button
      className="py-1 px-2  bg-transparent border-2 border-brightOrange font-semibold rounded-xl text-large text-brightOrange hover:text-white hover:bg-brightOrange">
      {`Admin Settings`->React.string}
    </button>
  </Remix.Link>
}
