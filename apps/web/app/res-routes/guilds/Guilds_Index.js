// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Remix from "remix";
import * as Js_dict from "../../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as $$Promise from "../../../../../node_modules/@ryyppy/rescript-promise/src/Promise.js";
import * as AuthServer from "../../AuthServer.js";
import * as AdminButton from "../../components/AdminButton.js";
import * as Belt_Option from "../../../../../node_modules/rescript/lib/es6/belt_Option.js";
import * as DiscordServer from "../../DiscordServer.js";
import * as Helpers_Guild from "../../helpers/Helpers_Guild.js";
import * as SidebarToggle from "../../components/SidebarToggle.js";
import * as ReactHotToast from "react-hot-toast";
import ReactHotToast$1 from "react-hot-toast";

function loader(param) {
  var guildId = Belt_Option.getWithDefault(Js_dict.get(param.params, "guildId"), "");
  return $$Promise.$$catch(AuthServer.authenticator.isAuthenticated(param.request).then(function (user) {
                  if (user == null) {
                    return Promise.resolve({
                                guild: null,
                                isAdmin: false
                              });
                  } else {
                    return DiscordServer.fetchGuildFromId(guildId).then(function (guild) {
                                var userId = user.profile.id;
                                return DiscordServer.fetchGuildMemberFromId(guildId, userId).then(function (guildMember) {
                                            var memberRoles = (guildMember == null) ? [] : guildMember.roles;
                                            return DiscordServer.fetchGuildRoles(guildId).then(function (guildRoles) {
                                                        var isAdmin = DiscordServer.memberIsAdmin(guildRoles, memberRoles);
                                                        var isOwner = (guild == null) ? false : guild.owner_id === userId;
                                                        return Promise.resolve({
                                                                    guild: guild,
                                                                    isAdmin: isAdmin || isOwner
                                                                  });
                                                      });
                                          });
                              });
                  }
                }), (function (error) {
                return Promise.resolve({
                            guild: null,
                            isAdmin: false
                          });
              }));
}

function $$default(param) {
  var match = Remix.useParams();
  var context = Remix.useOutletContext();
  var match$1 = Remix.useLoaderData();
  var guild = match$1.guild;
  var guildDisplay = (guild == null) ? React.createElement("div", undefined, "That Discord Server does not exist") : React.createElement("div", {
          className: "flex flex-col items-center"
        }, React.createElement("div", {
              className: "flex gap-4 w-full justify-start items-center"
            }, React.createElement("img", {
                  className: "rounded-full h-24",
                  src: Helpers_Guild.iconUri(guild)
                }), React.createElement("p", {
                  className: "text-4xl font-bold text-white"
                }, guild.name)), React.createElement("div", {
              className: "flex-row"
            }));
  if (context.rateLimited) {
    ReactHotToast$1.error("The bot is being rate limited. Please try again later");
  }
  return React.createElement("div", {
              className: "flex-1 p-4"
            }, React.createElement(ReactHotToast.Toaster, {}), React.createElement("div", {
                  className: "flex flex-col"
                }, React.createElement("header", {
                      className: "flex flex-row justify-between md:justify-end m-4"
                    }, React.createElement(SidebarToggle.make, {
                          handleToggleSidebar: context.handleToggleSidebar
                        }), match$1.isAdmin ? React.createElement(AdminButton.make, {
                            guildId: match.guildId
                          }) : React.createElement(React.Fragment, undefined)), guildDisplay));
}

export {
  loader ,
  $$default ,
  $$default as default,
}
/* react Not a pure module */
