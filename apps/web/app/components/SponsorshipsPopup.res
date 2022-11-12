@react.component
let make = (~isAdmin, ~sign) => {
  let visibilty = isAdmin ? "visible" : "invisible"
  <div
    className={`p-4 w-full bottom-0 md:bottom-5 absolute bg-extraDark md:rounded-xl md:m-4 shadow-2xl ${visibilty}`}>
    <div className="flex flex-row justify-between items-center gap-2">
      <p className="text-white text-xl">
        {`This server is not setup to sponsor members!`->React.string}
      </p>
      <div className="flex flex-row items-center gap-4">
        <button
          type_="submit"
          className="bg-brightid p-3 rounded-xl text-xl font-semibold text-white"
          onClick=sign>
          {`Setup Sponsorships`->React.string}
        </button>
      </div>
    </div>
  </div>
}
