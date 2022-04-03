let handlers = Belt.Map.String.fromArray([
  ("!verify", Handlers_Verify.verify),
  ("!me", Handlers_Me.me),
  //   ("!guilds", guildsHandler),
  //   ("!invite", inviteHandler),
  ("!role", Handlers_Role.role),
  ("!brightid", Handlers_BrightId.brightId),
])
