@react.component
let make = (~guildId) => {
  <Remix.Link to={`/guilds/${guildId}/admin`} prefetch={#intent}>
    <button
      className="p-4 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-large text-white">
      {`Admin Settings`->React.string}
    </button>
  </Remix.Link>
}
