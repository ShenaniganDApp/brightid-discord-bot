module ContextId = {
  type t = {
    unique: bool,
    app: string,
    context: string,
    contextIds: array<string>,
    timestamp: int,
  }
  type data = {data: t}
}

module App = {
  type t = {
    id: string,
    name: string,
    context: string,
    verification: string,
    logo: string,
    url: string,
    assignedSponsorships: float,
    unusedSponsorships: float,
    testing: bool,
    soulbound: bool,
    soulboundMessage: string,
  }
  type data = {data: t}
}

module Error = {
  type t = {
    error: bool,
    errorNum: int,
    errorMessage: string,
    code: int,
  }
}

module Gist = {
  type brightIdGuild = {
    role: option<string>,
    name: option<string>,
    inviteLink: option<string>,
    roleId: option<string>,
    sponsorshipAddress: option<string>,
    usedSponsorships: option<string>,
    assignedSponsorships: option<string>,
    premiumSponsorshipsUsed: option<string>,
    premiumExpirationTimestamp: option<float>,
  }

  type brightIdGuilds = Js.Dict.t<brightIdGuild>
}

module Sponsorships = {
  type availableSponsorships = int
  type sponsor = {hash: string}

  type t = {
    app: string,
    appHasAuthorized: bool,
    spendRequested: bool,
    timestamp: float,
  }
  type data = {data: t}
}

module Operations = {
  type result = {
    message: string,
    errorNum: int,
  }
  type t = {
    state: string,
    result: option<result>,
  }
  type data = {data: t}
}

@module("brightid_sdk_v5")
external sponsor: (~key: string, ~context: string, ~contextId: string) => Js.Promise.t<Js.Json.t> =
  "sponsor"

@module("brightid_sdk_v5")
external availableSponsorships: (~context: string) => Js.Promise.t<Js.Json.t> =
  "availableSponsorships"

//@Todo:  rename this to contract name (IdSponsorships)
module SPContract = {
  type t
  external make: Ethers.Contract.t => t = "%identity"

  @send
  external contextBalance: (
    t,
    ~address: string,
    ~formattedContext: string,
  ) => Js.Promise.t<Ethers.BigNumber.t> = "contextBalance"
}
