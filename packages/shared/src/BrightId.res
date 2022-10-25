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
  role: option<string>,
  name: option<string>,
  inviteLink: option<string>,
  roleId: option<string>,
  sponsorshipAddress: option<string>,
  usedSponsorships: option<int>,
  assignedSponsorships: option<int>,
}

type brightIdGuilds = Js.Dict.t<brightIdGuild>

@module("brightid_sdk")
external sponsor: (
  ~sponsorkey: string,
  ~contextId: string,
  ~id: string,
) => Js.Promise.t<Js.Json.t> = "sponsor"
