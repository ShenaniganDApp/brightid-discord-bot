open! Json.Decode

module Decode_BrightId = {
  module ContextId = {
    open BrightId.ContextId
    let contextId = field => {
      unique: field.required(. "unique", bool),
      app: field.required(. "app", string),
      context: field.required(. "context", string),
      contextIds: field.required(. "contextIds", array(string)),
      timestamp: field.optional(. "timestamp", float),
      sig: field.optional(. "sig", string),
      publicKey: field.optional(. "publicKey", string),
    }

    let data = field => {
      data: contextId->object->field.required(. "data", _),
    }

    let data = data->object
  }

  module Verifications = {
    open BrightId.Verifications
    let verification = field => {
      contextIds: field.required(. "contextIds", array(string)),
      count: field.required(. "count", int),
    }

    let data = field => {
      data: verification->object->field.required(. "data", _),
    }

    let data = data->object
  }

  module Error = {
    open BrightId.Error
    let data = field => {
      error: field.required(. "error", bool),
      errorNum: field.required(. "errorNum", int),
      errorMessage: field.required(. "errorMessage", string),
      code: field.required(. "code", int),
    }

    let data = data->object
  }

  module Sponsorships = {
    open BrightId.Sponsorships
    let availableSponsorships = int

    let sponsor = field => {
      hash: field.required(. "hash", string),
    }
    let sponsor = sponsor->object

    let sponsorship = field => {
      app: field.required(. "app", string),
      appHasAuthorized: field.required(. "appHasAuthorized", bool),
      spendRequested: field.required(. "spendRequested", bool),
      timestamp: field.required(. "timestamp", Json.Decode.float),
    }

    let data = field => {
      data: sponsorship->object->field.required(. "data", _),
    }
    let data = data->object
  }

  module Operations = {
    open BrightId.Operations
    let result = field => {
      message: field.required(. "message", string),
      errorNum: field.required(. "errorNum", int),
    }

    let result = result->object

    let operation = field => {
      state: field.required(. "state", string),
      result: field.optional(. "result", result),
    }
    let data = field => {
      data: operation->object->field.required(. "data", _),
    }

    let data = data->object
  }

  module App = {
    open BrightId.App
    let app = field => {
      id: field.required(. "id", string),
      name: field.required(. "name", string),
      context: field.required(. "context", string),
      verification: field.required(. "verification", string),
      logo: field.required(. "logo", string),
      url: field.required(. "url", string),
      assignedSponsorships: field.required(. "assignedSponsorships", float),
      unusedSponsorships: field.required(. "unusedSponsorships", float),
      testing: field.required(. "testing", bool),
      soulbound: field.required(. "soulbound", bool),
      soulboundMessage: field.required(. "soulboundMessage", string),
    }
    let data = field => {
      data: app->object->field.required(. "data", _),
    }

    let data = data->object
  }
}
module Decode_Gist = {
  open BrightId.Gist
  let assignedSponsorship = field => {
    address: field.required(. "address", string),
    amount: field.required(. "amount", string),
    timestamp: field.required(. "timestamp", float),
    chainId: field.required(. "chainId", int),
  }

  let assignedSponsorships = assignedSponsorship->object->array
  let brightIdGuild = object(field => {
    role: field.optional(. "role", string),
    name: field.optional(. "name", string),
    inviteLink: field.optional(. "inviteLink", string),
    roleId: field.optional(. "roleId", string),
    sponsorshipAddress: field.optional(. "sponsorshipAddress", string),
    sponsorshipAddressEth: field.optional(. "sponsorshipAddressEth", string),
    usedSponsorships: field.optional(. "usedSponsorships", string),
    assignedSponsorships: field.optional(. "assignedSponsorships", assignedSponsorships),
    premiumSponsorshipsUsed: field.optional(. "premiumSponsorshipsUsed", string),
    premiumExpirationTimestamp: field.optional(. "premiumExpirationTimestamp", float),
  })

  let brightIdGuilds = brightIdGuild->dict
}
