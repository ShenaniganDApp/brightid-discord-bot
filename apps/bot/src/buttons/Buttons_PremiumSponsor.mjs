// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "../Env.mjs";
import * as Uuid from "uuid";
import * as Js_exn from "rescript/lib/es6/js_exn.js";
import * as Ethers from "ethers";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as $$Promise from "@ryyppy/rescript-promise/src/Promise.mjs";
import * as Endpoints from "../Endpoints.mjs";
import * as Exceptions from "../Exceptions.mjs";
import * as Gist$Utils from "@brightidbot/utils/src/Gist.mjs";
import * as DiscordJs from "discord.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Decode$Shared from "@brightidbot/shared/src/Decode.mjs";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as Commands_Verify from "../commands/Commands_Verify.mjs";
import * as Brightid_sdk_v5 from "brightid_sdk_v5";
import * as Constants$Shared from "@brightidbot/shared/src/Constants.mjs";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.mjs";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

function sleep(ms) {
  return (new Promise((resolve) => setTimeout(resolve, ms)));
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

function noUnusedSponsorshipsOptions(param) {
  return {
          content: "There are no sponsorhips available in the Discord pool. Please try again later.",
          ephemeral: true
        };
}

async function unsuccessfulSponsorMessageOptions(uuid) {
  var verifyUrl = "" + Endpoints.brightIdLinkVerificationEndpoint + "/" + uuid + "";
  var uri = "" + Endpoints.brightIdAppDeeplink + "/" + uuid + "";
  var canvas = await Commands_Verify.makeCanvasFromUri(uri);
  var attachment = await Commands_Verify.createMessageAttachmentFromCanvas(canvas);
  var row = Commands_Verify.makeBeforeSponsorActionRow("Retry Sponsor", verifyUrl);
  return {
          content: "Your sponsor request failed. \n\n This is often due to the BrightID App not being linked to Discord. Please scan this QR code in the BrightID mobile app then retry your sponsorship request.\n\n",
          files: [attachment],
          ephemeral: true,
          components: [row]
        };
}

async function sponsorRequestSubmittedMessageOptions(uuid) {
  var uri = "" + Endpoints.brightIdAppDeeplink + "/" + uuid + "";
  var canvas = await Commands_Verify.makeCanvasFromUri(uri);
  var attachment = await Commands_Verify.createMessageAttachmentFromCanvas(canvas);
  var nowInSeconds = Math.round(Date.now() / 1000);
  var fifteenMinutesAfter = 15 * 60 + nowInSeconds;
  var content = "You sponsor request has been submitted! \n\n Make sure you have scanned this QR code in the BrightID mobile app to confirm your sponsor and link Discord to BrightID. \n This process will timeout <t:" + String(fifteenMinutesAfter) + ":R>.\n\n";
  return {
          content: content,
          files: [attachment],
          ephemeral: true
        };
}

async function noWriteToGistMessage(interaction) {
  var options = {
    content: "It seems like I can't write to my database at the moment. Please try again or contact the BrightID support.",
    ephemeral: true
  };
  return await interaction.followUp(options);
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

async function checkSponsor(uuid) {
  var endpoint = "https://app.brightid.org/node/v6/sponsorships/" + uuid + "";
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

var HandleSponsorError = /* @__PURE__ */Caml_exceptions.create("Buttons_PremiumSponsor.HandleSponsorError");

async function handleSponsor(interaction, maybeHashOpt, attemptsOpt, uuid) {
  var maybeHash = maybeHashOpt !== undefined ? Caml_option.valFromOption(maybeHashOpt) : undefined;
  var attempts = attemptsOpt !== undefined ? attemptsOpt : 30;
  var guildId = interaction.guild.id;
  if (attempts === 0) {
    return /* TimedOut */3;
  }
  var json;
  try {
    json = await Brightid_sdk_v5.sponsor(envConfig.sponsorshipKey, "Discord", uuid);
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === Js_exn.$$Error) {
      var json$1 = JSON.stringify(error._1);
      var json$2;
      if (json$1 !== undefined) {
        json$2 = JSON.parse(json$1);
      } else {
        throw {
              RE_EXN_ID: HandleSponsorError,
              _1: "Handle Sponsor Error: There was a problem JSON parsing the error from sponsor()",
              Error: new Error()
            };
      }
      var err = Json$JsonCombinators.decode(json$2, Decode$Shared.Decode_BrightId.$$Error.data);
      if (err.TAG === /* Ok */0) {
        var match = err._0;
        var errorMessage = match.errorMessage;
        switch (match.errorNum) {
          case 38 :
              return /* NoUnusedSponsorships */2;
          case 39 :
              if (maybeHash === undefined) {
                return /* RetriedCommandDuring */1;
              }
              var exit = 0;
              var val;
              try {
                val = await checkSponsor(uuid);
                exit = 2;
              }
              catch (raw_obj){
                var obj = Caml_js_exceptions.internalToOCamlException(raw_obj);
                if (obj.RE_EXN_ID === Exceptions.BrightIdError) {
                  await sleep(29000);
                  return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
                }
                if (obj.RE_EXN_ID === $$Promise.JsError) {
                  var obj$1 = obj._1;
                  var msg = obj$1.message;
                  if (msg !== undefined) {
                    throw {
                          RE_EXN_ID: HandleSponsorError,
                          _1: msg,
                          Error: new Error()
                        };
                  }
                  console.error(obj$1);
                  throw {
                        RE_EXN_ID: HandleSponsorError,
                        _1: "Handle Sponsor: Unknown Error",
                        Error: new Error()
                      };
                }
                throw obj;
              }
              if (exit === 2) {
                if (val._0.spendRequested) {
                  var options = successfulSponsorMessageOptions(uuid);
                  await interaction.editReply(options);
                  return /* SponsorshipUsed */0;
                }
                await sleep(29000);
                return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
              }
              break;
          case 40 :
          case 41 :
          case 42 :
          case 43 :
          case 44 :
              throw {
                    RE_EXN_ID: HandleSponsorError,
                    _1: errorMessage,
                    Error: new Error()
                  };
          case 45 :
              if (maybeHash === undefined) {
                return /* RetriedCommandDuring */1;
              }
              var exit$1 = 0;
              var val$1;
              try {
                val$1 = await checkSponsor(uuid);
                exit$1 = 2;
              }
              catch (raw_obj$1){
                var obj$2 = Caml_js_exceptions.internalToOCamlException(raw_obj$1);
                if (obj$2.RE_EXN_ID === Exceptions.BrightIdError) {
                  await sleep(29000);
                  return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
                }
                if (obj$2.RE_EXN_ID === $$Promise.JsError) {
                  var obj$3 = obj$2._1;
                  var msg$1 = obj$3.message;
                  if (msg$1 !== undefined) {
                    throw {
                          RE_EXN_ID: HandleSponsorError,
                          _1: msg$1,
                          Error: new Error()
                        };
                  }
                  console.error(obj$3);
                  throw {
                        RE_EXN_ID: HandleSponsorError,
                        _1: "Handle Sponsor: Unknown Error",
                        Error: new Error()
                      };
                }
                throw obj$2;
              }
              if (exit$1 === 2) {
                if (val$1._0.spendRequested) {
                  var options$1 = successfulSponsorMessageOptions(uuid);
                  await interaction.editReply(options$1);
                  return /* SponsorshipUsed */0;
                }
                await sleep(29000);
                return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
              }
              break;
          case 46 :
              if (maybeHash === undefined) {
                return /* RetriedCommandDuring */1;
              }
              var options$2 = await successfulSponsorMessageOptions(uuid);
              await interaction.editReply(options$2);
              return /* SponsorshipUsed */0;
          case 47 :
              if (maybeHash === undefined) {
                return /* RetriedCommandDuring */1;
              }
              var exit$2 = 0;
              var val$2;
              try {
                val$2 = await checkSponsor(uuid);
                exit$2 = 2;
              }
              catch (raw_obj$2){
                var obj$4 = Caml_js_exceptions.internalToOCamlException(raw_obj$2);
                if (obj$4.RE_EXN_ID === Exceptions.BrightIdError) {
                  await sleep(29000);
                  return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
                }
                if (obj$4.RE_EXN_ID === $$Promise.JsError) {
                  var obj$5 = obj$4._1;
                  var msg$2 = obj$5.message;
                  if (msg$2 !== undefined) {
                    throw {
                          RE_EXN_ID: HandleSponsorError,
                          _1: msg$2,
                          Error: new Error()
                        };
                  }
                  console.error(obj$5);
                  throw {
                        RE_EXN_ID: HandleSponsorError,
                        _1: "Handle Sponsor: Unknown Error",
                        Error: new Error()
                      };
                }
                throw obj$4;
              }
              if (exit$2 === 2) {
                if (val$2._0.spendRequested) {
                  var options$3 = successfulSponsorMessageOptions(uuid);
                  await interaction.editReply(options$3);
                  return /* SponsorshipUsed */0;
                }
                await sleep(29000);
                return await handleSponsor(interaction, Caml_option.some(maybeHash), attempts - 1 | 0, uuid);
              }
              break;
          default:
            throw {
                  RE_EXN_ID: HandleSponsorError,
                  _1: errorMessage,
                  Error: new Error()
                };
        }
      } else {
        throw {
              RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
              _1: err._0,
              Error: new Error()
            };
      }
    } else {
      throw error;
    }
  }
  var err$1 = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.Sponsorships.sponsor);
  if (err$1.TAG === /* Ok */0) {
    var hash = err$1._0.hash;
    var options$4 = await sponsorRequestSubmittedMessageOptions(uuid);
    await interaction.editReply(options$4);
    console.log("A sponsor request has been submitted", {
          guild: guildId,
          contextId: uuid,
          hash: hash
        });
    return await handleSponsor(interaction, Caml_option.some(hash), 30, uuid);
  }
  throw {
        RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
        _1: err$1._0,
        Error: new Error()
      };
}

function gistConfig(param) {
  return Gist$Utils.makeGistConfig(envConfig.gistId, "guildData.json", envConfig.githubAccessToken);
}

async function execute(interaction) {
  var guild = interaction.guild;
  var guildId = guild.id;
  var member = interaction.member;
  var memberId = member.id;
  var uuid = Uuid.v5(memberId, envConfig.uuidNamespace);
  var exit = 0;
  var val;
  try {
    val = await interaction.deferReply({
          ephemeral: true
        });
    exit = 1;
  }
  catch (e){
    throw e;
  }
  if (exit === 1) {
    var exit$1 = 0;
    var guilds;
    try {
      guilds = await Gist$Utils.ReadGist.content(gistConfig(undefined), Decode$Shared.Decode_Gist.brightIdGuilds);
      exit$1 = 2;
    }
    catch (e$1){
      await Commands_Verify.unknownErrorMessage(interaction);
      throw e$1;
    }
    if (exit$1 === 2) {
      var guildData = Js_dict.get(guilds, guildId);
      if (guildData !== undefined) {
        var exit$2 = 0;
        var val$1;
        try {
          val$1 = await handleSponsor(interaction, undefined, undefined, uuid);
          exit$2 = 3;
        }
        catch (raw_errorMessage){
          var errorMessage = Caml_js_exceptions.internalToOCamlException(raw_errorMessage);
          if (errorMessage.RE_EXN_ID === HandleSponsorError) {
            var guildName = guild.name;
            console.error("User: " + uuid + " from server " + guildName + " ran into an unexpected error: ", errorMessage._1);
            await Commands_Verify.unknownErrorMessage(interaction);
          } else if (errorMessage.RE_EXN_ID === $$Promise.JsError) {
            var guildName$1 = guild.name;
            console.error("User: " + uuid + " from server " + guildName$1 + " ran into an unexpected error: ", errorMessage._1);
            await Commands_Verify.unknownErrorMessage(interaction);
          } else {
            throw errorMessage;
          }
        }
        if (exit$2 === 3) {
          switch (val$1) {
            case /* SponsorshipUsed */0 :
                var premiumSponsorshipsUsed = Belt_Option.getWithDefault(guildData.premiumSponsorshipsUsed, Ethers.constants.Zero.toString());
                var premiumSponsorshipsUsed$1 = Ethers.BigNumber.from(premiumSponsorshipsUsed).add("1").toString();
                var updatePremiumSponsorshipsUsed = await Gist$Utils.UpdateGist.updateEntry(guilds, guildId, {
                      role: guildData.role,
                      name: guildData.name,
                      inviteLink: guildData.inviteLink,
                      roleId: guildData.roleId,
                      sponsorshipAddress: guildData.sponsorshipAddress,
                      usedSponsorships: guildData.usedSponsorships,
                      assignedSponsorships: guildData.assignedSponsorships,
                      premiumSponsorshipsUsed: premiumSponsorshipsUsed$1,
                      premiumExpirationTimestamp: guildData.premiumExpirationTimestamp
                    }, gistConfig(undefined));
                if (updatePremiumSponsorshipsUsed.TAG === /* Ok */0) {
                  var options = await successfulSponsorMessageOptions(uuid);
                  await interaction.followUp(options);
                } else {
                  console.error("Buttons Sponsor: Error updating premium used sponsorships", updatePremiumSponsorshipsUsed._0);
                  await noWriteToGistMessage(interaction);
                }
                break;
            case /* RetriedCommandDuring */1 :
                var options$1 = {
                  content: "Your request is still processing. Maybe you haven't scanned the QR code yet?\n\n If you have already scanned the code, please wait a few minutes for BrightID nodes to sync your sponsorship request",
                  ephemeral: true
                };
                await interaction.followUp(options$1);
                break;
            case /* NoUnusedSponsorships */2 :
                await interaction.followUp({
                      content: "There are no sponsorhips available in the Discord pool. Please try again later.",
                      ephemeral: true
                    });
                break;
            case /* TimedOut */3 :
                var options$2 = await unsuccessfulSponsorMessageOptions(uuid);
                await interaction.editReply(options$2);
                break;
            
          }
        }
        return ;
      }
      await noWriteToGistMessage(interaction);
      throw {
            RE_EXN_ID: Exceptions.PremiumSponsorButtonError,
            _1: "Buttons_PremiumSponsor: Guild with guildId: " + guildId + " not found in gist",
            Error: new Error()
          };
    }
    
  }
  
}

var brightIdVerificationEndpoint = Endpoints.brightIdVerificationEndpoint;

var brightIdAppDeeplink = Endpoints.brightIdAppDeeplink;

var brightIdLinkVerificationEndpoint = Endpoints.brightIdLinkVerificationEndpoint;

var context = Constants$Shared.context;

var makeCanvasFromUri = Commands_Verify.makeCanvasFromUri;

var createMessageAttachmentFromCanvas = Commands_Verify.createMessageAttachmentFromCanvas;

var makeBeforeSponsorActionRow = Commands_Verify.makeBeforeSponsorActionRow;

var unknownErrorMessage = Commands_Verify.unknownErrorMessage;

var customId = "before-premium-sponsor";

export {
  brightIdVerificationEndpoint ,
  brightIdAppDeeplink ,
  brightIdLinkVerificationEndpoint ,
  context ,
  makeCanvasFromUri ,
  createMessageAttachmentFromCanvas ,
  makeBeforeSponsorActionRow ,
  unknownErrorMessage ,
  sleep ,
  envConfig ,
  noUnusedSponsorshipsOptions ,
  unsuccessfulSponsorMessageOptions ,
  sponsorRequestSubmittedMessageOptions ,
  noWriteToGistMessage ,
  makeAfterSponsorActionRow ,
  successfulSponsorMessageOptions ,
  checkSponsor ,
  HandleSponsorError ,
  handleSponsor ,
  gistConfig ,
  execute ,
  customId ,
}
/*  Not a pure module */
