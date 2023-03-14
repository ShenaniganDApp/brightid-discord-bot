// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "../Env.mjs";
import * as Curry from "rescript/lib/es6/curry.js";
import * as Js_exn from "rescript/lib/es6/js_exn.js";
import * as Endpoints from "../Endpoints.mjs";
import * as Exceptions from "../Exceptions.mjs";
import * as DiscordJs from "discord.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.mjs";
import * as Decode$Shared from "@brightidbot/shared/src/Decode.mjs";
import * as CustomMessages from "../CustomMessages.mjs";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as Commands_Verify from "../commands/Commands_Verify.mjs";
import * as Brightid_sdk_v5 from "brightid_sdk_v5";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.mjs";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

function sleep(_ms) {
  return (new Promise((resolve) => setTimeout(resolve, _ms)));
}

Env.createEnv(undefined);

var config = Env.getConfig(undefined);

var envConfig;

if (config.TAG === /* Ok */0) {
  envConfig = config._0;
} else {
  throw {
        RE_EXN_ID: Env.EnvError,
        _1: config._0,
        Error: new Error()
      };
}

var RetryAsync = /* @__PURE__ */Caml_exceptions.create("Services_Sponsor.RetryAsync");

async function retry(fn, n) {
  try {
    await sleep(1000);
    await Curry._1(fn, undefined);
  }
  catch (exn){
    if (n > 0) {
      await retry(fn, n - 1 | 0);
    }
    
  }
  throw {
        RE_EXN_ID: RetryAsync,
        _1: "Failed " + fn + " retrying " + n + " times",
        Error: new Error()
      };
}

function noUnusedSponsorshipsOptions(param) {
  return {
          content: "There are no sponsorhips available in the Discord pool. Please try again later.",
          ephemeral: true
        };
}

async function unsuccessfulSponsorMessageOptions(uuid) {
  var verifyUrl = "" + Endpoints.brightIdLinkVerificationEndpoint + "/" + uuid + "";
  var row = Commands_Verify.makeBeforeSponsorActionRow("Retry Sponsor", verifyUrl);
  return {
          content: "Your sponsor request failed. \n\n This is often due to the BrightID App not being linked to Discord. Please scan the previous QR code in the BrightID mobile app then retry your sponsorship request.\n\n",
          ephemeral: true,
          components: [row]
        };
}

async function sponsorRequestSubmittedMessageOptions(param) {
  var nowInSeconds = Math.round(Date.now() / 1000);
  var fifteenMinutesAfter = 15 * 60 + nowInSeconds;
  var content = "You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:" + fifteenMinutesAfter.toString() + ":R>.\n\n";
  return {
          content: content,
          ephemeral: true
        };
}

function makeAfterSponsorActionRow(label) {
  var verifyButton = new DiscordJs.MessageButton().setCustomId("verify").setLabel(label).setStyle("PRIMARY");
  return new DiscordJs.MessageActionRow().addComponents([verifyButton]);
}

async function successfulSponsorMessageOptions(uuid) {
  var uri = "" + Endpoints.brightIdAppDeeplink + "/" + uuid + "";
  var canvas = await Commands_Verify.makeCanvasFromUri(uri);
  var attachment = await Commands_Verify.createMessageAttachmentFromCanvas(canvas);
  var row = makeAfterSponsorActionRow("Assign BrightID Verified Role");
  return {
          content: "You have succesfully been sponsored \n\n If you are verified in BrightID you are all done. Click the button below to assign your role.\n\n",
          files: [attachment],
          ephemeral: true,
          components: [row]
        };
}

var HandleSponsorError = /* @__PURE__ */Caml_exceptions.create("Services_Sponsor.HandleSponsorError");

async function checkSponsor(uuid) {
  var endpoint = "https://app.brightid.org/node/v5/sponsorships/" + uuid + "";
  var params = {
    method: "GET",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    timeout: 60000
  };
  var res = await globalThis.fetch(endpoint, params);
  var json = await res.json();
  var match = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.Sponsorships.data);
  var match$1 = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.$$Error.data);
  if (match.TAG === /* Ok */0) {
    return /* Sponsorship */{
            _0: match._0.data
          };
  }
  if (match$1.TAG === /* Ok */0) {
    throw {
          RE_EXN_ID: Exceptions.BrightIdError,
          _1: match$1._0,
          Error: new Error()
        };
  }
  throw {
        RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
        _1: match._0,
        Error: new Error()
      };
}

async function handleSponsor(interaction, maybeHashOpt, attemptsOpt, maybeLogMessageOpt, uuid) {
  var maybeHash = maybeHashOpt !== undefined ? Caml_option.valFromOption(maybeHashOpt) : undefined;
  var attempts = attemptsOpt !== undefined ? attemptsOpt : 30;
  var maybeLogMessage = maybeLogMessageOpt !== undefined ? Caml_option.valFromOption(maybeLogMessageOpt) : undefined;
  var guildId = interaction.guild.id;
  if (attempts !== 0) {
    try {
      var json = await Brightid_sdk_v5.sponsor(envConfig.sponsorshipKey, "Discord", uuid);
      var err = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.Sponsorships.sponsor);
      if (err.TAG === /* Ok */0) {
        var hash = err._0.hash;
        var options = await sponsorRequestSubmittedMessageOptions(undefined);
        await interaction.editReply(options);
        console.log("A sponsor request has been submitted", {
              guild: guildId,
              contextId: uuid,
              hash: hash
            });
        var maybeLogMessage$1 = await CustomMessages.sponsorshipRequested(interaction, uuid, maybeHash);
        return await handleSponsor(interaction, Caml_option.some(hash), 30, Caml_option.some(maybeLogMessage$1), uuid);
      }
      throw {
            RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
            _1: err._0,
            Error: new Error()
          };
    }
    catch (raw_error){
      var error = Caml_js_exceptions.internalToOCamlException(raw_error);
      if (error.RE_EXN_ID === Js_exn.$$Error) {
        try {
          var brightIdError = Core__Option.map(Core__Option.map(JSON.stringify(error._1), (function (prim) {
                      return JSON.parse(prim);
                    })), (function (__x) {
                  return Json$JsonCombinators.decode(__x, Decode$Shared.Decode_BrightId.$$Error.data);
                }));
          if (brightIdError !== undefined) {
            if (brightIdError.TAG === /* Ok */0) {
              var exit = 0;
              switch (brightIdError._0.errorNum) {
                case 38 :
                    if (Core__Option.isSome(maybeLogMessage)) {
                      await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Error */{
                            _0: "No Sponsorships available in the BrightID Discord App"
                          }, uuid, maybeHash);
                    }
                    return /* NoUnusedSponsorships */2;
                case 39 :
                    if (maybeHash !== undefined) {
                      var match = await checkSponsor(uuid);
                      if (match._0.spendRequested) {
                        if (Core__Option.isSome(maybeLogMessage)) {
                          Core__Option.map(maybeLogMessage, (async function (logMessage) {
                                  return await CustomMessages.editSponsorhipMessage(logMessage, /* Successful */1, uuid, maybeHash);
                                }));
                        }
                        var options$1 = successfulSponsorMessageOptions(uuid);
                        await interaction.editReply(options$1);
                        return /* SponsorshipUsed */0;
                      }
                      await sleep(29000);
                      return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, Caml_option.some(maybeLogMessage), uuid);
                    }
                    exit = 1;
                    break;
                case 40 :
                case 41 :
                case 42 :
                case 43 :
                case 44 :
                    exit = 1;
                    break;
                case 45 :
                    if (maybeHash !== undefined) {
                      var match$1 = await checkSponsor(uuid);
                      if (match$1._0.spendRequested) {
                        if (Core__Option.isSome(maybeLogMessage)) {
                          await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Successful */1, uuid, maybeHash);
                        }
                        var options$2 = successfulSponsorMessageOptions(uuid);
                        await interaction.editReply(options$2);
                        return /* SponsorshipUsed */0;
                      }
                      await sleep(29000);
                      return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, Caml_option.some(maybeLogMessage), uuid);
                    }
                    exit = 1;
                    break;
                case 46 :
                    if (maybeHash !== undefined) {
                      if (Core__Option.isSome(maybeLogMessage)) {
                        await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Successful */1, uuid, maybeHash);
                      }
                      var options$3 = await successfulSponsorMessageOptions(uuid);
                      await interaction.editReply(options$3);
                      return /* SponsorshipUsed */0;
                    }
                    exit = 1;
                    break;
                case 47 :
                    if (maybeHash !== undefined) {
                      var match$2 = await checkSponsor(uuid);
                      if (match$2._0.spendRequested) {
                        if (Core__Option.isSome(maybeLogMessage)) {
                          await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Successful */1, uuid, maybeHash);
                        }
                        var options$4 = successfulSponsorMessageOptions(uuid);
                        await interaction.editReply(options$4);
                        return /* SponsorshipUsed */0;
                      }
                      await sleep(29000);
                      return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, Caml_option.some(maybeLogMessage), uuid);
                    }
                    exit = 1;
                    break;
                default:
                  exit = 1;
              }
              if (exit === 1) {
                if (maybeHash !== undefined) {
                  await sleep(29000);
                  return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, Caml_option.some(maybeLogMessage), uuid);
                } else {
                  return /* RetriedCommandDuring */1;
                }
              }
              
            } else {
              throw {
                    RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                    _1: brightIdError._0,
                    Error: new Error()
                  };
            }
          } else {
            throw {
                  RE_EXN_ID: HandleSponsorError,
                  _1: "Handle Sponsor Error: There was a problem JSON parsing the error from sponsor()",
                  Error: new Error()
                };
          }
        }
        catch (raw_msg){
          var msg = Caml_js_exceptions.internalToOCamlException(raw_msg);
          if (msg.RE_EXN_ID === Exceptions.BrightIdError) {
            await sleep(29000);
            return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, Caml_option.some(maybeLogMessage), uuid);
          }
          if (msg.RE_EXN_ID === Json_Decode$JsonCombinators.DecodeError) {
            var msg$1 = msg._1;
            if (msg$1.includes("503 Service Temporarily Unavailable")) {
              await sleep(3000);
              return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts, Caml_option.some(maybeLogMessage), uuid);
            }
            throw {
                  RE_EXN_ID: HandleSponsorError,
                  _1: msg$1,
                  Error: new Error()
                };
          }
          if (msg.RE_EXN_ID === Js_exn.$$Error) {
            var obj = msg._1;
            var match$3 = obj.name;
            if (match$3 === "FetchError") {
              await sleep(3000);
              return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts, Caml_option.some(maybeLogMessage), uuid);
            }
            var msg$2 = obj.message;
            if (msg$2 !== undefined) {
              if (Core__Option.isSome(maybeLogMessage)) {
                await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Error */{
                      _0: msg$2
                    }, uuid, maybeHash);
              }
              throw {
                    RE_EXN_ID: HandleSponsorError,
                    _1: msg$2,
                    Error: new Error()
                  };
            }
            console.error(obj);
            if (Core__Option.isSome(maybeLogMessage)) {
              await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Error */{
                    _0: "Something went wrong"
                  }, uuid, maybeHash);
            }
            throw {
                  RE_EXN_ID: HandleSponsorError,
                  _1: "Handle Sponsor: Unknown Error",
                  Error: new Error()
                };
          }
          throw msg;
        }
      } else {
        throw error;
      }
    }
  } else {
    if (Core__Option.isSome(maybeLogMessage)) {
      await CustomMessages.editSponsorhipMessage(Core__Option.getExn(maybeLogMessage), /* Failed */2, uuid, maybeHash);
    }
    return /* TimedOut */3;
  }
}

var brightIdVerificationEndpoint = Endpoints.brightIdVerificationEndpoint;

var brightIdAppDeeplink = Endpoints.brightIdAppDeeplink;

var brightIdLinkVerificationEndpoint = Endpoints.brightIdLinkVerificationEndpoint;

var makeCanvasFromUri = Commands_Verify.makeCanvasFromUri;

var createMessageAttachmentFromCanvas = Commands_Verify.createMessageAttachmentFromCanvas;

var makeBeforeSponsorActionRow = Commands_Verify.makeBeforeSponsorActionRow;

export {
  brightIdVerificationEndpoint ,
  brightIdAppDeeplink ,
  brightIdLinkVerificationEndpoint ,
  makeCanvasFromUri ,
  createMessageAttachmentFromCanvas ,
  makeBeforeSponsorActionRow ,
  sleep ,
  envConfig ,
  RetryAsync ,
  retry ,
  noUnusedSponsorshipsOptions ,
  unsuccessfulSponsorMessageOptions ,
  sponsorRequestSubmittedMessageOptions ,
  makeAfterSponsorActionRow ,
  successfulSponsorMessageOptions ,
  HandleSponsorError ,
  checkSponsor ,
  handleSponsor ,
}
/*  Not a pure module */
