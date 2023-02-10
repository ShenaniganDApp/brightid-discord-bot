type oauthGuild = {
  id: string,
  name: string,
  icon: option<string>,
}

type guild = {
  id: string,
  name: string,
  icon: option<string>,
  roles: array<JSON.t>,
  owner_id: string,
}

type guildMember = {roles: array<string>}

type role = {
  id: string,
  name: string,
  permissions: float,
}

type brightIdGuildData = {
  name: option<string>,
  role: option<string>,
  inviteLink: option<string>,
  sponsorshipAddress: option<string>,
  roleId: option<string>,
}

type verifyStatus = Unknown | NotLinked | NotVerified | NotSponsored | Unique
