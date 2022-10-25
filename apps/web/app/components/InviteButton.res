@react.component
let make = () => {
  <a
    href="https://discord.com/oauth2/authorize?client_id=759128312030691328&permissions=2416045120&scope=applications.commands%20bot"
    target="_blank">
    <button
      className="p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white">
      {`Invite to Discord`->React.string}
    </button>
  </a>
}
