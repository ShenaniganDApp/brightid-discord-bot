type brightContextId = {
  unique: bool,
  app: string,
  context: string,
  contextIds: array<string>,
  timestamp: int,
}
type brightIdContextIdRes = {data: brightContextId}

type brightIdError = {
  error: bool,
  errorNum: int,
  errorMessage: string,
  code: int,
}

// @TODO this should be a record
type brightIdGuild = {
  "role": string,
  "name": string,
  "inviteLink": option<string>,
  "roleId": string,
}

type brightIdGuilds = Js.Dict.t<brightIdGuild>
