@react.component
let make = (~className: option<string>=?) => {
  <a
    href="https://discord.com/oauth2/authorize?client_id=759128312030691328&permissions=2416045120&scope=applications.commands%20bot"
    target="_blank"
    className={className->Option.getWithDefault("")}>
    <button
      className="py-1 px-2 bg-transparent border border-brightOrange font-semibold rounded-xl text-lg text-brightOrange hover:text-white hover:bg-brightOrange">
      {`Add to Discord`->React.string}
    </button>
  </a>
}
