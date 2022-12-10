open Json.Decode

module Decode_BrightId = {
  module ContextId = {
    open BrightId.ContextId
    let contextId = field => {
      unique: field.required(. "unique", bool),
      app: field.required(. "app", string),
      context: field.required(. "context", string),
      contextIds: field.required(. "contextIds", array(string)),
      timestamp: field.required(. "timestamp", int),
    }

    let data = field => {
      data: contextId->object->field.required(. "data", _),
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

    let sponsorhip = field => {
      app: field.required(. "app", string),
      appHasAuthorized: field.required(. "appHasAuthorized", bool),
      spendRequested: field.required(. "spendRequested", bool),
      timestamp: field.required(. "timestamp", int),
    }

    let data = field => {
      data: sponsorhip->object->field.required(. "data", _),
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
}
module Decode_Gist = {
  open BrightId.Gist
  let brightIdGuild = object(field => {
    role: field.optional(. "role", string),
    name: field.optional(. "name", string),
    inviteLink: field.optional(. "inviteLink", string),
    roleId: field.optional(. "roleId", string),
    sponsorshipAddress: field.optional(. "sponsorshipAddress", string),
    usedSponsorships: field.optional(. "usedSponsorships", string),
    assignedSponsorships: field.optional(. "assignedSponsorships", string),
  })

  let brightIdGuilds = brightIdGuild->dict
}
