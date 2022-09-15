// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

function contextId(field) {
  return {
          unique: field.required("unique", Json_Decode$JsonCombinators.bool),
          app: field.required("app", Json_Decode$JsonCombinators.string),
          context: field.required("context", Json_Decode$JsonCombinators.string),
          contextIds: field.required("contextIds", Json_Decode$JsonCombinators.array(Json_Decode$JsonCombinators.string)),
          timestamp: field.required("timestamp", Json_Decode$JsonCombinators.$$int)
        };
}

function data(field) {
  var __x = Json_Decode$JsonCombinators.object(contextId);
  return {
          data: field.required("data", __x)
        };
}

var data$1 = Json_Decode$JsonCombinators.object(data);

function error(field) {
  return {
          error: field.required("error", Json_Decode$JsonCombinators.bool),
          errorNum: field.required("errorNum", Json_Decode$JsonCombinators.$$int),
          errorMessage: field.required("errorMessage", Json_Decode$JsonCombinators.string),
          code: field.required("code", Json_Decode$JsonCombinators.$$int)
        };
}

var error$1 = Json_Decode$JsonCombinators.object(error);

var BrightId = {
  contextId: contextId,
  data: data$1,
  error: error$1
};

var brightIdGuild = Json_Decode$JsonCombinators.object(function (field) {
      return {
              role: field.optional("role", Json_Decode$JsonCombinators.string),
              name: field.optional("name", Json_Decode$JsonCombinators.string),
              inviteLink: field.optional("inviteLink", Json_Decode$JsonCombinators.string),
              roleId: field.optional("roleId", Json_Decode$JsonCombinators.string)
            };
    });

var brightIdGuilds = Json_Decode$JsonCombinators.dict(brightIdGuild);

var Gist = {
  brightIdGuild: brightIdGuild,
  brightIdGuilds: brightIdGuilds
};

export {
  BrightId ,
  Gist ,
}
/* data Not a pure module */
