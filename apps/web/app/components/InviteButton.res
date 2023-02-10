@react.component
let make = (~className: option<string>=?) => {
  <a
    href="https://discord.com/oauth2/authorize?client_id=759128312030691328&permissions=2416045120&scope=applications.commands%20bot"
    target="_blank"
    className={className->Option.getWithDefault("")}>
    <button
      className="p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white">
      {`Add to Discord`->React.string}
    </button>
  </a>
}
