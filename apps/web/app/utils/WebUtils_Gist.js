// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "../../../../node_modules/rescript/lib/es6/caml_option.js";
import * as Core__Option from "../../../../node_modules/@rescript/core/src/Core__Option.js";
import * as Core__Promise from "../../../../node_modules/@rescript/core/src/Core__Promise.js";
import * as Webapi__Fetch from "../../../../node_modules/rescript-webapi/src/Webapi/Webapi__Fetch.js";
import * as Caml_exceptions from "../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as Json$JsonCombinators from "../../../../node_modules/@glennsl/rescript-json-combinators/src/Json.js";
import * as Json_Decode$JsonCombinators from "../../../../node_modules/@glennsl/rescript-json-combinators/src/Json_Decode.js";

var envConfig = process.env;

var githubAccessToken = envConfig.githubAccessToken;

var GithubGist = {};

function content(field) {
  return {
          content: field.required("content", Json_Decode$JsonCombinators.string)
        };
}

function files(field) {
  var __x = Json_Decode$JsonCombinators.dict(Json_Decode$JsonCombinators.object(content));
  return {
          files: field.required("files", __x)
        };
}

var gist = Json_Decode$JsonCombinators.object(files);

var Decode = {
  content: content,
  files: files,
  gist: gist
};

function makeGistConfig(id, name, token) {
  return {
          id: id,
          name: name,
          token: token
        };
}

function content$1(config, decoder) {
  var name = config.name;
  var init = Webapi__Fetch.RequestInit.make(/* Get */0, {
          Authorization: "token " + config.token + ""
        }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)(undefined);
  return fetch("https://api.github.com/gists/" + config.id + "", init).then(function (res) {
                return res.json();
              }).then(function (data) {
              var gist$1 = Json$JsonCombinators.decode(data, gist);
              if (gist$1.TAG !== /* Ok */0) {
                return Promise.reject({
                            RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                            _1: gist$1._0
                          });
              }
              var json = Core__Option.getExn(gist$1._0.files[name]);
              var content = Json$JsonCombinators.decode(Json$JsonCombinators.parseExn(json.content), decoder);
              if (content.TAG === /* Ok */0) {
                return Promise.resolve(content._0);
              }
              throw {
                    RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                    _1: content._0,
                    Error: new Error()
                  };
            });
}

var ReadGist = {
  content: content$1
};

var UpdateGistError = /* @__PURE__ */Caml_exceptions.create("WebUtils_Gist.UpdateGist.UpdateGistError");

var DuplicateKey = /* @__PURE__ */Caml_exceptions.create("WebUtils_Gist.UpdateGist.DuplicateKey");

function updateEntry(content, key, entry, config) {
  var id = config.id;
  content[key] = entry;
  var content$1 = JSON.stringify(content);
  var files = {};
  files[config.name] = {
    content: content$1
  };
  var body = {
    gist_id: id,
    description: "Update gist entry with key: " + key + "",
    files: files
  };
  var init = Webapi__Fetch.RequestInit.make(/* Patch */8, {
          Authorization: "token " + config.token + "",
          Accept: "application/vnd.github+json"
        }, Caml_option.some(Core__Option.getExn(JSON.stringify(body))), undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)(undefined);
  return Core__Promise.$$catch(fetch("https://api.github.com/gists/" + id + "", init).then(function (res) {
                  var status = res.status;
                  if (status !== 200) {
                    res.json().then(function (json) {
                          console.log(status, JSON.stringify(json));
                          return Promise.resolve(undefined);
                        });
                    return Promise.resolve({
                                TAG: /* Error */1,
                                _0: "Patch_Error"
                              });
                  } else {
                    return Promise.resolve({
                                TAG: /* Ok */0,
                                _0: 200
                              });
                  }
                }), (function (e) {
                console.log("e: ", e);
                return Promise.resolve({
                            TAG: /* Error */1,
                            _0: "Unkown_Error"
                          });
              }));
}

function removeEntry(content, key, config) {
  var id = config.id;
  var entries = Object.entries(content).filter(function (param) {
        return key !== param[0];
      });
  var content$1 = JSON.stringify(Object.fromEntries(entries));
  var files = {};
  files[config.name] = {
    content: content$1
  };
  var body = {
    gist_id: id,
    description: "Remove entry with id : " + key + "",
    files: files
  };
  var init = Webapi__Fetch.RequestInit.make(/* Patch */8, {
          Authorization: "token " + config.token + "",
          Accept: "application/vnd.github+json"
        }, Caml_option.some(Core__Option.getExn(JSON.stringify(body))), undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)(undefined);
  return Core__Promise.$$catch(fetch("https://api.github.com/gists/" + id + "", init).then(function (res) {
                  var status = res.status;
                  if (status !== 200) {
                    res.json().then(function (json) {
                          console.log(status, JSON.stringify(json));
                          return Promise.resolve(undefined);
                        });
                    return Promise.resolve({
                                TAG: /* Error */1,
                                _0: "Patch_Error"
                              });
                  } else {
                    return Promise.resolve({
                                TAG: /* Ok */0,
                                _0: 200
                              });
                  }
                }), (function (e) {
                console.log("e: ", e);
                return Promise.resolve({
                            TAG: /* Error */1,
                            _0: "Unknown_Error"
                          });
              }));
}

function updateAllEntries(content, entries, config) {
  var id = config.id;
  var entries$1 = Object.fromEntries(entries);
  var keys = Object.keys(entries$1);
  keys.forEach(function (key) {
        var entry = Core__Option.getExn(entries$1[key]);
        content[key] = entry;
      });
  var content$1 = JSON.stringify(content);
  var files = {};
  files[config.name] = {
    content: content$1
  };
  var body = {
    gist_id: id,
    description: "Update gist",
    files: files
  };
  var init = Webapi__Fetch.RequestInit.make(/* Patch */8, {
          Authorization: "token " + config.token + "",
          Accept: "application/vnd.github+json"
        }, Caml_option.some(Core__Option.getExn(JSON.stringify(body))), undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)(undefined);
  return Core__Promise.$$catch(fetch("https://api.github.com/gists/" + id + "", init).then(function (res) {
                  var status = res.status;
                  if (status !== 200) {
                    res.json().then(function (json) {
                          console.log(status, JSON.stringify(json));
                          return Promise.resolve(undefined);
                        });
                    return Promise.resolve({
                                TAG: /* Error */1,
                                _0: "Patch_Error"
                              });
                  } else {
                    return Promise.resolve({
                                TAG: /* Ok */0,
                                _0: 200
                              });
                  }
                }), (function (e) {
                console.log("e: ", e);
                return Promise.resolve({
                            TAG: /* Error */1,
                            _0: "Unknown_Error"
                          });
              }));
}

var UpdateGist = {
  UpdateGistError: UpdateGistError,
  DuplicateKey: DuplicateKey,
  updateEntry: updateEntry,
  removeEntry: removeEntry,
  updateAllEntries: updateAllEntries
};

export {
  envConfig ,
  githubAccessToken ,
  GithubGist ,
  Decode ,
  makeGistConfig ,
  ReadGist ,
  UpdateGist ,
}
/* envConfig Not a pure module */
