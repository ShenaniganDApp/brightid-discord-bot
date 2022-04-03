let handlers = Belt.Map.String.fromArray([
  ("!verify", Handlers_Verify.verify),
  //   ("!guilds", guildsHandler),
  //   ("!invite", inviteHandler),
  ("!role", Handlers_Role.role),
  ("!brightid", Handlers_BrightId.brightId),
])
