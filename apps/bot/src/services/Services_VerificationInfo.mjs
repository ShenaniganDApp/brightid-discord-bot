// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "../Env.mjs";
import * as Uuid from "uuid";
import * as Endpoints from "../Endpoints.mjs";
import * as Exceptions from "../Exceptions.mjs";
import * as FetchTools from "../FetchTools.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Promise from "@rescript/core/src/Core__Promise.mjs";
import * as Decode$Shared from "@brightidbot/shared/src/Decode.mjs";
import * as Constants$Shared from "@brightidbot/shared/src/Constants.mjs";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.mjs";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

var UUID = {};

Env.createEnv(undefined);

var config = Env.getConfig(undefined);

var config$1;

if (config.TAG === /* Ok */0) {
  config$1 = config._0;
} else {
  throw {
        RE_EXN_ID: Env.EnvError,
        _1: config._0,
        Error: new Error()
      };
}

function sleep(_ms) {
  return (new Promise((resolve) => setTimeout(resolve, _ms)));
}

function fetchVerificationInfo(retryOpt, id) {
  var retry = retryOpt !== undefined ? retryOpt : 5;
  var uuid = Uuid.v5(id, config$1.uuidNamespace);
  return Core__Promise.$$catch(FetchTools.fetchWithFallback("/verifications/" + Constants$Shared.context + "/" + uuid + "", undefined, Endpoints.nodes[0], Endpoints.nodes).then(function (maybeRes) {
                    if (maybeRes !== undefined) {
                      return Caml_option.valFromOption(maybeRes).json();
                    } else {
                      return Promise.reject({
                                  RE_EXN_ID: FetchTools.NoRes
                                });
                    }
                  }).then(function (json) {
                  var match = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.ContextId.data);
                  var match$1 = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.$$Error.data);
                  if (match.TAG === /* Ok */0) {
                    return Promise.resolve(/* VerificationInfo */{
                                _0: match._0.data
                              });
                  } else if (match$1.TAG === /* Ok */0) {
                    return Promise.reject({
                                RE_EXN_ID: Exceptions.BrightIdError,
                                _1: match$1._0
                              });
                  } else {
                    return Promise.reject({
                                RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                                _1: match._0
                              });
                  }
                }), (function (e) {
                if (e.RE_EXN_ID === Exceptions.BrightIdError) {
                  throw e;
                }
                var retry$1 = retry - 1 | 0;
                if (retry$1 !== 0) {
                  return sleep(3000).then(function (param) {
                              return fetchVerificationInfo(retry$1, id);
                            });
                }
                throw e;
              }));
}

function getBrightIdVerification(member) {
  var id = member.id;
  return fetchVerificationInfo(undefined, id);
}

var context = Constants$Shared.context;

var brightIdVerificationEndpoint = Endpoints.brightIdVerificationEndpoint;

var nodes = Endpoints.nodes;

var requestTimeout = 60000;

export {
  UUID ,
  config$1 as config,
  sleep ,
  context ,
  brightIdVerificationEndpoint ,
  nodes ,
  requestTimeout ,
  fetchVerificationInfo ,
  getBrightIdVerification ,
}
/*  Not a pure module */
