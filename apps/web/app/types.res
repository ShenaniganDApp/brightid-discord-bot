type oauthGuild = {
  id: string,
  name: string,
  icon: option<string>,
}

type guild = {
  id: string,
  name: string,
  icon: option<string>,
  roles: array<Js.Json.t>,
  owner_id: string,
}

type guildMember = {roles: array<string>}

type role = {
  id: string,
  name: string,
  permissions: float,
}

type brightIdGuildData = {
  name: Js.Nullable.t<string>,
  role: Js.Nullable.t<string>,
  inviteLink: Js.Nullable.t<string>,
  sponsorshipAddress: Js.Nullable.t<string>,
}

type verifyStatus = Unknown | NotLinked | NotVerified | NotSponsored | Unique
