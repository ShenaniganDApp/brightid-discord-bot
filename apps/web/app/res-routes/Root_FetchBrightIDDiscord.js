// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Uuid from "uuid";
import * as Js_dict from "../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as Js_json from "../../../../node_modules/rescript/lib/es6/js_json.js";
import * as AuthServer from "../AuthServer.js";
import * as Belt_Option from "../../../../node_modules/rescript/lib/es6/belt_Option.js";
import * as Brightid_sdk from "brightid_sdk";
import * as Webapi__Fetch from "../../../../node_modules/rescript-webapi/src/Webapi/Webapi__Fetch.js";
import * as Js_null_undefined from "../../../../node_modules/rescript/lib/es6/js_null_undefined.js";

var context = "Discord";

var brightIdVerificationEndpoint = "https://app.brightid.org/node/v5/verifications/Discord";

function loader(param) {
  var request = param.request;
  var uuidNamespace = process.env.UUID_NAMESPACE;
  var init = Webapi__Fetch.RequestInit.make(/* Get */0, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)(undefined);
  return fetch(new Request(brightIdVerificationEndpoint, init)).then(function (res) {
                return res.json();
              }).then(function (json) {
              var data = Belt_Option.getExn(Js_dict.get(Js_json.decodeObject(json), "data"));
              var verificationCount = Js_null_undefined.fromOption(Belt_Option.flatMap(Js_dict.get(Js_json.decodeObject(data), "count"), Js_json.decodeNumber));
              return AuthServer.authenticator.isAuthenticated(request).then(function (user) {
                          if (user == null) {
                            return Promise.resolve({
                                        user: null,
                                        verificationCount: verificationCount,
                                        verifyStatus: /* NotVerified */2
                                      });
                          }
                          var userId = user.profile.id;
                          var contextId = Uuid.v5(userId, uuidNamespace);
                          return Brightid_sdk.verifyContextId(context, contextId, undefined).then(function (json) {
                                      var unique = Belt_Option.flatMap(Js_dict.get(Js_json.decodeObject(json), "unique"), Js_json.decodeBoolean);
                                      var verifyStatus;
                                      if (unique !== undefined) {
                                        verifyStatus = /* Unique */4;
                                      } else {
                                        var data = Belt_Option.getExn(Js_dict.get(Js_json.decodeObject(json), "data"));
                                        var errorNum = Belt_Option.flatMap(Js_dict.get(Js_json.decodeObject(data), "errorNum"), Js_json.decodeNumber);
                                        verifyStatus = errorNum !== undefined ? (
                                            errorNum !== 2 ? (
                                                errorNum !== 3 ? (
                                                    errorNum !== 4 ? /* Unknown */0 : /* NotSponsored */3
                                                  ) : /* NotVerified */2
                                              ) : /* NotLinked */1
                                          ) : /* Unknown */0;
                                      }
                                      return Promise.resolve({
                                                  user: user,
                                                  verificationCount: verificationCount,
                                                  verifyStatus: verifyStatus
                                                });
                                    });
                        });
            });
}

export {
  context ,
  brightIdVerificationEndpoint ,
  loader ,
  
}
/* uuid Not a pure module */
