// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "../Env.mjs";
import * as UUID from "UUID";
import * as Canvas from "Canvas";
import * as QRCode from "QRCode";
import * as Js_dict from "../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as $$Promise from "../../../../node_modules/@ryyppy/rescript-promise/src/Promise.mjs";
import * as Endpoints from "../Endpoints.mjs";
import * as Belt_Array from "../../../../node_modules/rescript/lib/es6/belt_Array.js";
import * as DiscordJs from "discord.js";
import NodeFetch from "node-fetch";
import * as Caml_exceptions from "../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as Builders from "@discordjs/builders";
import * as UpdateOrReadGistMjs from "../updateOrReadGist.mjs";

var VerifyHandlerError = /* @__PURE__ */Caml_exceptions.create("Commands_Verify.VerifyHandlerError");

var UUID$1 = {};

var Canvas$1 = {};

var QRCode$1 = {};

var $$Response = {};

function readGist(prim) {
  return UpdateOrReadGistMjs.readGist();
}

Env.createEnv(undefined);

var config = Env.getConfig(undefined);

var uuidNAMESPACE;

if (config.TAG === /* Ok */0) {
  uuidNAMESPACE = config._0.uuidNamespace;
} else {
  throw {
        RE_EXN_ID: VerifyHandlerError,
        _1: config._0,
        Error: new Error()
      };
}

function addVerifiedRole(member, role, reason) {
  var guildMemberRoleManager = member.roles;
  var guild = member.guild;
  guildMemberRoleManager.add(role, reason);
  var partial_arg = "I recognize you! You're now a verified user in " + guild.name;
  return function (param) {
    return member.send(partial_arg, param);
  };
}

function isIdInVerifications(data, id) {
  var match = data.error;
  if (match == null) {
    var contextIds = data.contextIds;
    if (contextIds == null) {
      return Promise.reject({
                  RE_EXN_ID: VerifyHandlerError,
                  _1: "Didn't return contextIds"
                });
    } else {
      return Promise.resolve(Belt_Array.some(contextIds, (function (contextId) {
                        return id === contextId;
                      })));
    }
  }
  var msg = data.errorMessage;
  if (msg == null) {
    return Promise.reject({
                RE_EXN_ID: VerifyHandlerError,
                _1: "No error message"
              });
  } else {
    return Promise.reject({
                RE_EXN_ID: VerifyHandlerError,
                _1: msg
              });
  }
}

function fetchVerifications(param) {
  var params = {
    method: "GET",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    timeout: 60000
  };
  return NodeFetch("https://app.brightid.org/node/v5/verifications/Discord", params).then(function (res) {
                return res.json();
              }).then(function (res) {
              var data = res.data;
              if (data == null) {
                return Promise.reject({
                            RE_EXN_ID: VerifyHandlerError,
                            _1: "No data"
                          });
              } else {
                return Promise.resolve(data);
              }
            });
}

function makeEmbed(verifyUrl) {
  var fields = [
    {
      name: "1. Get Verified in the BrightID app",
      value: "Getting verified requires you make connections with other trusted users. Given the concept is new and there are not many trusted users, this is currently being done through [Verification parties](https://www.brightid.org/meet \"https://www.brightid.org/meet\") that are hosted in the BrightID server and require members join a voice/video call."
    },
    {
      name: "2. Link to a Sponsored App (like 1hive, gitcoin, etc)",
      value: "You can link to these [sponsored apps](https://apps.brightid.org/ \"https://apps.brightid.org/\") once you are verified within the app."
    },
    {
      name: "3. Type the `!verify` command in any public channel",
      value: "You can type this command in any public channel with access to the BrightID Bot, like the official BrightID server which [you can access here](https://discord.gg/gH6qAUH \"https://discord.gg/gH6qAUH\")."
    },
    {
      name: "4. Scan the DM\"d QR Code",
      value: "Open the BrightID app and scan the QR code. Mobile users can click [this link](" + verifyUrl + ")."
    },
    {
      name: "5. Type the `!me` command in any public channel",
      value: "Once you have scanned the QR code you can return to any public channel and type the `!me` command which should grant you the orange verified role."
    }
  ];
  return new DiscordJs.MessageEmbed().setColor("#fb8b60").setTitle("How To Get Verified with Bright ID").setURL("https://www.brightid.org/").setAuthor("BrightID Bot", "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png", "https://www.brightid.org/").setDescription("Here is a step-by-step guide to help you get verified with BrightID.").setThumbnail("https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png").addFields(fields).setTimestamp().setFooter("Bot made by the Shenanigan team", "https://media.discordapp.net/attachments/708186850359246859/760681364163919994/1601430947224.png");
}

function createMessageAttachmentFromUri(uri) {
  var canvas = Canvas.default.createCanvas(700, 250);
  return QRCode.toCanvas(canvas, uri).then(function (param) {
              return Promise.resolve(new DiscordJs.MessageAttachment(canvas.toBuffer(), "qrcode.png", undefined));
            });
}

function getRolebyRoleName(guildRoleManager, roleName) {
  var guildRole = guildRoleManager.cache.find(function (role) {
        return role.name === roleName;
      });
  if (!(guildRole == null)) {
    return guildRole;
  }
  throw {
        RE_EXN_ID: VerifyHandlerError,
        _1: "Could not find a role with the name " + roleName,
        Error: new Error()
      };
}

function makeVerifyActionRow(param) {
  var button = new DiscordJs.MessageButton().setCustomId("verify").setLabel("Click here after scanning QR Code in the BrightID app").setStyle("PRIMARY");
  return new DiscordJs.MessageActionRow().addComponents(button);
}

function execute(interaction) {
  var guild = interaction.guild;
  var member = interaction.member;
  var guildRoleManager = guild.roles;
  var guildMemberRoleManager = member.roles;
  var memberId = member.id;
  var id = UUID.v5(memberId, uuidNAMESPACE);
  return interaction.deferReply({
                ephemeral: true
              }).then(function (param) {
              return $$Promise.$$catch(UpdateOrReadGistMjs.readGist().then(function (guilds) {
                              var guildId = guild.id;
                              var guildData = Js_dict.get(guilds, guildId);
                              if (guildData !== undefined) {
                                var guildRole = getRolebyRoleName(guildRoleManager, guildData.role);
                                var deepLink = Endpoints.brightIdAppDeeplink + "/" + id;
                                var verifyUrl = Endpoints.brightIdLinkVerificationEndpoint + "/" + id;
                                return fetchVerifications(undefined).then(function (data) {
                                              return isIdInVerifications(data, id);
                                            }).then(function (idExists) {
                                            if (idExists) {
                                              guildMemberRoleManager.add(guildRole, "");
                                              interaction.editReply({
                                                    content: "Hey, I recognize you! I just gave you the `" + guildRole.name + "` role. You are now BrightID verified in " + guild.name + " server!",
                                                    ephemeral: true
                                                  });
                                              return Promise.resolve(undefined);
                                            } else {
                                              return createMessageAttachmentFromUri(deepLink).then(function (attachment) {
                                                          var embed = makeEmbed(verifyUrl);
                                                          var row = makeVerifyActionRow(undefined);
                                                          interaction.editReply({
                                                                embeds: [embed],
                                                                files: [attachment],
                                                                ephemeral: true,
                                                                components: [row]
                                                              });
                                                          return Promise.resolve(undefined);
                                                        });
                                            }
                                          });
                              }
                              interaction.editReply({
                                    content: "Hi, sorry about that. I couldn't retrieve the data for this server from BrightId"
                                  });
                              return Promise.reject({
                                          RE_EXN_ID: VerifyHandlerError,
                                          _1: "Guild does not exist"
                                        });
                            }), (function (e) {
                            if (e.RE_EXN_ID === VerifyHandlerError) {
                              console.error(e._1);
                            } else if (e.RE_EXN_ID === $$Promise.JsError) {
                              var msg = e._1.message;
                              if (msg !== undefined) {
                                console.error(msg);
                              } else {
                                console.error("Verify Handler: Unknown error");
                              }
                            } else {
                              console.error("Verify Handler: Unknown error");
                            }
                            return Promise.resolve(undefined);
                          }));
            });
}

var data = new Builders.SlashCommandBuilder().setName("verify").setDescription("Sends a BrightID QR code for users to connect with their BrightId");

export {
  VerifyHandlerError ,
  UUID$1 as UUID,
  Canvas$1 as Canvas,
  QRCode$1 as QRCode,
  $$Response ,
  readGist ,
  config ,
  uuidNAMESPACE ,
  addVerifiedRole ,
  isIdInVerifications ,
  fetchVerifications ,
  makeEmbed ,
  createMessageAttachmentFromUri ,
  getRolebyRoleName ,
  makeVerifyActionRow ,
  execute ,
  data ,
  
}
/*  Not a pure module */
