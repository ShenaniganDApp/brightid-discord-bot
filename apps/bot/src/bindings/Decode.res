open BrightId
open Json.Decode

module BrightId = {
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

  let error = field => {
    error: field.required(. "error", bool),
    errorNum: field.required(. "errorNum", int),
    errorMessage: field.required(. "errorMessage", string),
    code: field.required(. "code", int),
  }

  let error = error->object
}

module Gist = {
  let brightIdGuild = object(field =>
    {
      "role": field.optional(. "role", string),
      "name": field.optional(. "name", string),
      "inviteLink": field.optional(. "inviteLink", string),
      "roleId": field.optional(. "roleId", string),
    }
  )

  let brightIdGuilds = brightIdGuild->dict
}
