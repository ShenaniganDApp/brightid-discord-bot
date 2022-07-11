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

type verifyStatus = Unknown | NotLinked | NotVerified | NotSponsored | Unique
