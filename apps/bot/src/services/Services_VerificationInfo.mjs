// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "../Env.mjs";
import * as Uuid from "uuid";
import * as Decode from "../bindings/Decode.mjs";
import * as $$Promise from "@ryyppy/rescript-promise/src/Promise.mjs";
import * as Constants from "../Constants.mjs";
import * as Endpoints from "../Endpoints.mjs";
import NodeFetch from "node-fetch";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.mjs";
import * as Services_ResponseCodes from "./Services_ResponseCodes.mjs";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

var BrightIdError = /* @__PURE__ */Caml_exceptions.create("Services_VerificationInfo.BrightIdError");

var defaultVerification_contextIds = [];

var defaultVerification = {
  unique: false,
  app: "",
  context: "Discord",
  contextIds: defaultVerification_contextIds,
  timestamp: 0
};

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

function fetchVerificationInfo(retryOpt, id) {
  var retry = retryOpt !== undefined ? retryOpt : 5;
  var uuid = Uuid.v5(id, config$1.uuidNamespace);
  var endpoint = "" + Endpoints.brightIdVerificationEndpoint + "/" + Constants.context + "/" + uuid + "?timestamp=seconds";
  var params = {
    method: "GET",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    timestamp: 60000
  };
  return $$Promise.$$catch(NodeFetch(endpoint, params).then(function (prim) {
                    return prim.json();
                  }).then(function (json) {
                  var match = Json$JsonCombinators.decode(json, Decode.BrightId.data);
                  var match$1 = Json$JsonCombinators.decode(json, Decode.BrightId.error);
                  if (match.TAG === /* Ok */0) {
                    return Promise.resolve({
                                TAG: /* VerificationInfo */0,
                                _0: match._0.data
                              });
                  } else if (match$1.TAG === /* Ok */0) {
                    return Promise.reject({
                                RE_EXN_ID: BrightIdError,
                                _1: match$1._0
                              });
                  } else {
                    return Promise.reject({
                                RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                                _1: match._0
                              });
                  }
                }), (function (e) {
                var retry$1 = retry - 1 | 0;
                if (retry$1 !== 0) {
                  return fetchVerificationInfo(retry$1, id);
                }
                if (e.RE_EXN_ID === BrightIdError) {
                  return Promise.resolve({
                              TAG: /* BrightIdError */1,
                              _0: e._1
                            });
                }
                if (e.RE_EXN_ID === $$Promise.JsError) {
                  return Promise.resolve({
                              TAG: /* JsError */2,
                              _0: e._1
                            });
                }
                throw e;
              }));
}

function getBrightIdVerification(member) {
  var id = member.id;
  return fetchVerificationInfo(undefined, id);
}

var context = Constants.context;

var brightIdVerificationEndpoint = Endpoints.brightIdVerificationEndpoint;

var notFoundCode = Services_ResponseCodes.notFoundCode;

var errorCode = Services_ResponseCodes.errorCode;

var canNotBeVerified = Services_ResponseCodes.canNotBeVerified;

var verificationPollingEvery = 3000;

var requestTimeout = 60000;

export {
  BrightIdError ,
  defaultVerification ,
  UUID ,
  config$1 as config,
  context ,
  brightIdVerificationEndpoint ,
  notFoundCode ,
  errorCode ,
  canNotBeVerified ,
  verificationPollingEvery ,
  requestTimeout ,
  fetchVerificationInfo ,
  getBrightIdVerification ,
}
/*  Not a pure module */
