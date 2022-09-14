@react.component
let make = (~guildId) => {
  <Remix.Link to={`/guilds/${guildId}/admin`} prefetch={#intent}>
    <button className="p-4 bg-brightid font-semibold rounded-3xl text-xl text-white">
      {`Admin Commands ➡️`->React.string}
    </button>
  </Remix.Link>
}
