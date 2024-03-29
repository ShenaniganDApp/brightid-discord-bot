// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "../../../../../../node_modules/rescript/lib/es6/curry.js";
import * as React from "react";
import * as Wagmi from "wagmi";
import * as Js_dict from "../../../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as AuthServer from "../../../AuthServer.js";
import * as Belt_Array from "../../../../../../node_modules/rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "../../../../../../node_modules/rescript/lib/es6/belt_Option.js";
import * as Caml_option from "../../../../../../node_modules/rescript/lib/es6/caml_option.js";
import * as SubmitPopup from "../../../components/SubmitPopup.js";
import * as Decode$Shared from "../../../../node_modules/@brightidbot/shared/src/Decode.js";
import * as DiscordServer from "../../../DiscordServer.js";
import * as WebUtils_Gist from "../../../utils/WebUtils_Gist.js";
import * as $$Node from "@remix-run/node";
import * as Caml_exceptions from "../../../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as ReactHotToast from "react-hot-toast";
import ReactHotToast$1 from "react-hot-toast";
import * as React$1 from "@remix-run/react";
import * as JsxRuntime from "react/jsx-runtime";
import * as DiscordLoginButton from "../../../components/DiscordLoginButton.js";

var NoBrightIdData = /* @__PURE__ */Caml_exceptions.create("Guilds_Admin.NoBrightIdData");

function loader(param) {
  var config = WebUtils_Gist.makeGistConfig(process.env.GIST_ID, "guildData.json", process.env.GITHUB_ACCESS_TOKEN);
  var guildId = Belt_Option.getWithDefault(Js_dict.get(param.params, "guildId"), "");
  return AuthServer.authenticator.isAuthenticated(param.request).then(function (maybeUser) {
              if (maybeUser == null) {
                $$Node.redirect("/guilds/" + guildId + "");
                return Promise.resolve({
                            maybeUser: undefined,
                            maybeBrightIdGuild: undefined,
                            maybeDiscordGuild: undefined,
                            isAdmin: false
                          });
              } else {
                return WebUtils_Gist.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds).then(function (guilds) {
                            var maybeBrightIdGuild = Js_dict.get(guilds, guildId);
                            return DiscordServer.fetchDiscordGuildFromId(guildId).then(function (maybeDiscordGuild) {
                                        var maybeDiscordGuild$1 = (maybeDiscordGuild == null) ? undefined : Caml_option.some(maybeDiscordGuild);
                                        var userId = maybeUser.profile.id;
                                        return DiscordServer.fetchGuildMemberFromId(guildId, userId).then(function (guildMember) {
                                                    var memberRoles = (guildMember == null) ? [] : guildMember.roles;
                                                    return DiscordServer.fetchGuildRoles(guildId).then(function (guildRoles) {
                                                                var isAdmin = DiscordServer.memberIsAdmin(guildRoles, memberRoles);
                                                                var isOwner = (maybeDiscordGuild == null) ? false : maybeDiscordGuild.owner_id === userId;
                                                                return Promise.resolve({
                                                                            maybeUser: Caml_option.some(maybeUser),
                                                                            maybeBrightIdGuild: maybeBrightIdGuild,
                                                                            maybeDiscordGuild: maybeDiscordGuild$1,
                                                                            isAdmin: isAdmin || isOwner
                                                                          });
                                                              });
                                                  });
                                      });
                          });
              }
            });
}

function truncateAddress(address) {
  return address.slice(0, 6) + "..." + address.slice(-5, address.length);
}

var state = {
  role: undefined,
  inviteLink: undefined,
  sponsorshipAddress: undefined
};

function reducer(state, action) {
  switch (action.TAG | 0) {
    case /* RoleChanged */0 :
        return {
                role: action._0,
                inviteLink: state.inviteLink,
                sponsorshipAddress: state.sponsorshipAddress
              };
    case /* InviteLinkChanged */1 :
        return {
                role: state.role,
                inviteLink: action._0,
                sponsorshipAddress: state.sponsorshipAddress
              };
    case /* SponsorshipAddressChanged */2 :
        return {
                role: state.role,
                inviteLink: state.inviteLink,
                sponsorshipAddress: action._0
              };
    
  }
}

function Guilds_Admin$default(props) {
  React$1.useOutletContext();
  var match = React$1.useLoaderData();
  var maybeDiscordGuild = match.maybeDiscordGuild;
  var maybeBrightIdGuild = match.maybeBrightIdGuild;
  var match$1 = React$1.useParams();
  var account = Wagmi.useAccount(undefined);
  var match$2 = React.useReducer(reducer, state);
  var dispatch = match$2[1];
  var state$1 = match$2[0];
  var roleId;
  if (maybeBrightIdGuild !== undefined) {
    var roleId$1 = maybeBrightIdGuild.roleId;
    roleId = roleId$1 !== undefined ? roleId$1 : "";
  } else {
    throw {
          RE_EXN_ID: NoBrightIdData,
          Error: new Error()
        };
  }
  var sign = maybeDiscordGuild !== undefined ? Caml_option.some(Wagmi.useSignMessage({
              message: "I consent that the SP in this address is able to be used by members of " + maybeDiscordGuild.name + " Discord Server",
              onError: (function (e) {
                  var match = e.name;
                  if (match === "ConnectorNotFoundError") {
                    ReactHotToast$1.error("No wallet found", undefined);
                    return ;
                  }
                  ReactHotToast$1.error(e.message, undefined);
                }),
              onSuccess: (function (param) {
                  Curry._1(dispatch, {
                        TAG: /* SponsorshipAddressChanged */2,
                        _0: account.address
                      });
                  ReactHotToast$1.success("Signed", undefined);
                })
            })) : undefined;
  var handleSign = function (param) {
    if (sign !== undefined) {
      return Curry._1(Caml_option.valFromOption(sign).signMessage, undefined);
    }
    
  };
  var reset = function (param) {
    Curry._1(dispatch, {
          TAG: /* RoleChanged */0,
          _0: undefined
        });
    Curry._1(dispatch, {
          TAG: /* InviteLinkChanged */1,
          _0: undefined
        });
    Curry._1(dispatch, {
          TAG: /* SponsorshipAddressChanged */2,
          _0: undefined
        });
  };
  var onRoleChanged = function (e) {
    var value = e.currentTarget.value;
    Curry._1(dispatch, {
          TAG: /* RoleChanged */0,
          _0: (value == null) ? undefined : Caml_option.some(value)
        });
  };
  var onInviteLinkChanged = function (e) {
    var value = e.currentTarget.value;
    Curry._1(dispatch, {
          TAG: /* InviteLinkChanged */1,
          _0: (value == null) ? undefined : Caml_option.some(value)
        });
  };
  var isSomeOrString = function (value) {
    if (value !== undefined) {
      return value !== "";
    } else {
      return false;
    }
  };
  var hasChangesToSave = Belt_Array.some([
        state$1.role,
        state$1.inviteLink,
        state$1.sponsorshipAddress
      ], isSomeOrString);
  if (match.maybeUser !== undefined) {
    if (match.isAdmin) {
      if (maybeDiscordGuild !== undefined) {
        return JsxRuntime.jsxs("div", {
                    children: [
                      JsxRuntime.jsx(ReactHotToast.Toaster, {}),
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsxs(React$1.Form, {
                                  className: " flex-1 text-white text-2xl font-semibold justify-center  items-center relative",
                                  children: [
                                    JsxRuntime.jsx("div", {
                                          children: maybeBrightIdGuild !== undefined ? JsxRuntime.jsxs("div", {
                                                  children: [
                                                    JsxRuntime.jsxs("label", {
                                                          children: [
                                                            "Role Name",
                                                            JsxRuntime.jsx("input", {
                                                                  className: "text-white p-2 rounded bg-dark cursor-not-allowed",
                                                                  name: "role",
                                                                  placeholder: Belt_Option.getWithDefault(maybeBrightIdGuild.role, "No Role Name"),
                                                                  readOnly: true,
                                                                  type: "text",
                                                                  value: Belt_Option.getWithDefault(state$1.role, ""),
                                                                  onChange: onRoleChanged
                                                                })
                                                          ],
                                                          className: "flex flex-col gap-2"
                                                        }),
                                                    JsxRuntime.jsxs("label", {
                                                          children: [
                                                            "Public Invite Link",
                                                            JsxRuntime.jsx("input", {
                                                                  className: "text-white p-2 bg-extraDark outline-none",
                                                                  name: "inviteLink",
                                                                  placeholder: Belt_Option.getWithDefault(maybeBrightIdGuild.inviteLink, "No Invite Link"),
                                                                  type: "text",
                                                                  value: Belt_Option.getWithDefault(state$1.inviteLink, ""),
                                                                  onChange: onInviteLinkChanged
                                                                })
                                                          ],
                                                          className: "flex flex-col gap-2"
                                                        }),
                                                    JsxRuntime.jsxs("label", {
                                                          children: [
                                                            "Sponsorship Address",
                                                            JsxRuntime.jsxs("div", {
                                                                  children: [
                                                                    JsxRuntime.jsx("input", {
                                                                          className: "text-white p-2 bg-dark",
                                                                          name: "sponsorshipAddress",
                                                                          placeholder: truncateAddress(Belt_Option.getWithDefault(maybeBrightIdGuild.sponsorshipAddress, "0x")),
                                                                          readOnly: true,
                                                                          type: "text",
                                                                          value: Belt_Option.getWithDefault(state$1.sponsorshipAddress, "")
                                                                        }),
                                                                    JsxRuntime.jsx("div", {
                                                                          children: "Sign",
                                                                          className: "p-2 border-2 border-brightid text-white font-xl rounded",
                                                                          onClick: handleSign
                                                                        })
                                                                  ],
                                                                  className: "flex flex-row gap-6 bg-transparent"
                                                                })
                                                          ],
                                                          className: "flex flex-col gap-2"
                                                        })
                                                  ],
                                                  className: "flex flex-col flex-1 justify-center items-start gap-6"
                                                }) : JsxRuntime.jsx("div", {
                                                  children: JsxRuntime.jsx("div", {
                                                        children: "This server is not using BrightID"
                                                      }),
                                                  className: "text-white text-2xl font-semibold justify-center items-center"
                                                }),
                                          className: "flex flex-1 justify-around flex-col items-center "
                                        }),
                                    JsxRuntime.jsx(SubmitPopup.make, {
                                          hasChangesToSave: hasChangesToSave,
                                          reset: reset
                                        })
                                  ],
                                  method: "post",
                                  action: "/guilds/" + match$1.guildId + "/" + roleId + "/adminSubmit"
                                }),
                            className: "flex flex-col flex-1 h-full"
                          })
                    ],
                    className: "flex-1 p-4"
                  });
      } else {
        return JsxRuntime.jsx(JsxRuntime.Fragment, {});
      }
    } else {
      return JsxRuntime.jsx("div", {
                  children: JsxRuntime.jsx("div", {
                        children: JsxRuntime.jsx("div", {
                              children: "You are not an admin in this server"
                            }),
                        className: "flex justify-center items-center text-white text-3xl font-bold"
                      }),
                  className: "flex flex-1"
                });
    }
  } else {
    return JsxRuntime.jsx(DiscordLoginButton.make, {
                label: "Login to Discord"
              });
  }
}

var $$default = Guilds_Admin$default;

export {
  NoBrightIdData ,
  loader ,
  truncateAddress ,
  state ,
  reducer ,
  $$default ,
  $$default as default,
}
/* react Not a pure module */
