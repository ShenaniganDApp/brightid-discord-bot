let handlers = Belt.Map.String.fromArray([
  ("!verify", Handlers_Verify.verify),
  ("!me", Handlers_Me.me),
  // ("!guilds", Handlers_Guild.guilds),
  ("!invite", Handlers_Invite.invite),
  // ("!role", Handlers_Role.role),
  ("!brightid", Handlers_BrightId.brightId),
])
