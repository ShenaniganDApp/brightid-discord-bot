type brightIdContextId = {
  unique: bool,
  app: string,
  context: string,
  contextIds: array<string>,
  timestamp: int,
}
type brightIdContextIdRes = {data: brightIdContextId}

type brightIdError = {
  error: bool,
  errorNum: int,
  errorMessage: string,
  code: int,
}

type brightIdGuild = {
  role: string,
  name: string,
  inviteLink: option<string>,
  roleId: string,
  sponsorshipAddress: option<string>,
}

type brightIdGuilds = Js.Dict.t<brightIdGuild>
