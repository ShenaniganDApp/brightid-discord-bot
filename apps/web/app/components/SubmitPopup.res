@react.component
let make = (~hasChangesToSave, ~reset) => {
  let visibilty = hasChangesToSave ? "visible" : "invisible"
  <div className={`p-4 w-full bottom-0 absolute bg-extraDark rounded-xl shadow-2xl ${visibilty}`}>
    <div className="flex flex-row justify-between items-center">
      <p> {`Careful - You have unsaved changes!`->React.string} </p>
      <div className="flex flex-row items-center gap-4">
        <div className="text-xl" onClick=reset> {`Reset`->React.string} </div>
        <button type_="submit" className="bg-brightid p-3 rounded-xl text-xl font-semibold">
          {`Save Changes`->React.string}
        </button>
      </div>
    </div>
  </div>
}
