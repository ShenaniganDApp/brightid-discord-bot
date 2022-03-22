let handlers = Belt.Map.String.fromArray([
  //   ("!verify", verifyHandler),
  //   ("!me", meHandler),
  //   ("!guilds", guildsHandler),
  //   ("!invite", inviteHandler),
  ("!role", Handlers_Role.role),
  ("!brightid", Handlers_BrightId.brightId),
])
