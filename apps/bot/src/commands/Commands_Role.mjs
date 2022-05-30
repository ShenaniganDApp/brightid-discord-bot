// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from "../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as $$Promise from "../../../../node_modules/@ryyppy/rescript-promise/src/Promise.mjs";
import * as DiscordJs from "discord.js";
import * as Caml_exceptions from "../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as Builders from "@discordjs/builders";
import * as UpdateOrReadGistMjs from "../updateOrReadGist.mjs";

var RoleHandlerError = /* @__PURE__ */Caml_exceptions.create("Commands_Role.RoleHandlerError");

function updateGist(prim0, prim1) {
  return UpdateOrReadGistMjs.updateGist(prim0, prim1);
}

function readGist(prim) {
  return UpdateOrReadGistMjs.readGist();
}

var newRoleRe = /(?<=^\S+)\s/;

function getRolebyRoleName(guildRoleManager, roleName) {
  var guildRole = guildRoleManager.cache.find(function (role) {
        return role.name === roleName;
      });
  if (!(guildRole == null)) {
    return guildRole;
  }
  throw {
        RE_EXN_ID: RoleHandlerError,
        _1: "Could not find a role with the name " + roleName,
        Error: new Error()
      };
}

function execute(interaction) {
  var guild = interaction.guild;
  var member = interaction.member;
  var guildRoleManager = guild.roles;
  var commandOptions = interaction.options;
  return interaction.deferReply({
                ephemeral: true
              }).then(function (param) {
              var isAdmin = member.permissions.has(DiscordJs.Permissions.FLAGS.ADMINISTRATOR);
              var tmp;
              if (isAdmin) {
                var role = commandOptions.getString("role");
                if (role == null) {
                  interaction.editReply({
                        content: "Woah! It seems the developer screwed up somewhere. Go complain!"
                      });
                  tmp = Promise.reject({
                        RE_EXN_ID: RoleHandlerError,
                        _1: "Commands_Role: The string input by the user came back null"
                      });
                } else {
                  tmp = UpdateOrReadGistMjs.readGist().then(function (guilds) {
                        var guildId = guild.id;
                        var guildData = Js_dict.get(guilds, guildId);
                        if (guildData !== undefined) {
                          var previousRole = guildData.role;
                          var guildRole = getRolebyRoleName(guildRoleManager, previousRole);
                          return guildRole.edit({
                                          name: role
                                        }, "Update BrightId role name").then(function (param) {
                                        return UpdateOrReadGistMjs.updateGist(guildId, {
                                                    role: role
                                                  });
                                      }).then(function (param) {
                                      interaction.editReply({
                                            content: "Succesfully updated `" + previousRole + "` role to `" + role + "`"
                                          });
                                      return Promise.resolve(undefined);
                                    });
                        }
                        interaction.editReply({
                              content: "I couldn't get the data about this Discord server from BrightID"
                            });
                        return Promise.reject({
                                    RE_EXN_ID: RoleHandlerError,
                                    _1: "Commands_Role: Guild does not exist with the guildID: " + guildId
                                  });
                      });
                }
              } else {
                interaction.editReply({
                      content: "Only administrators can change the role"
                    });
                tmp = Promise.reject({
                      RE_EXN_ID: RoleHandlerError,
                      _1: "Commands_Role: User does not hav Administrator permissions"
                    });
              }
              return $$Promise.$$catch(tmp, (function (e) {
                            if (e.RE_EXN_ID === RoleHandlerError) {
                              console.error(e._1);
                            } else if (e.RE_EXN_ID === $$Promise.JsError) {
                              var msg = e._1.message;
                              if (msg !== undefined) {
                                console.error(msg);
                              } else {
                                console.error("Must be some non-error value");
                              }
                            } else {
                              console.error("Some unknown error");
                            }
                            return Promise.resolve(undefined);
                          }));
            });
}

var data = new Builders.SlashCommandBuilder().setName("role").setDescription("Set the name of the BrightID verified role for this server").addStringOption(function (option) {
      return option.setName("name").setDescription("Enter the new name of the role").setRequired(true);
    });

export {
  RoleHandlerError ,
  updateGist ,
  readGist ,
  newRoleRe ,
  getRolebyRoleName ,
  execute ,
  data ,
  
}
/* data Not a pure module */
