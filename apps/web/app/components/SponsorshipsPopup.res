type params = {guildId: string}
@react.component
let make = () => {
  let {guildId} = Remix.useParams()

  <div
    className={`p-4 w-full bottom-0 md:bottom-5 absolute bg-extraDark md:rounded-xl md:m-4 shadow-2xl`}>
    <div className="flex flex-row justify-between items-center gap-2">
      <p className="text-white text-xl"> {`Assign Sponsorships to this server`->React.string} </p>
      <div className="flex flex-row items-center gap-4">
        <Remix.Link
          to={`/guilds/${guildId}/sponsorships/assignSponsorships`}
          className="bg-brightid p-3 rounded-xl text-xl font-semibold text-white">
          {`Setup Sponsorships`->React.string}
        </Remix.Link>
      </div>
    </div>
  </div>
}
