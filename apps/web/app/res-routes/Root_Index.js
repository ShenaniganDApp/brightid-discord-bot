// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Uuid from "uuid";
import * as React from "react";
import * as AuthServer from "../AuthServer.js";
import * as Belt_Option from "../../../../node_modules/rescript/lib/es6/belt_Option.js";
import * as Caml_option from "../../../../node_modules/rescript/lib/es6/caml_option.js";
import * as InviteButton from "../components/InviteButton.js";
import * as Brightid_sdk from "brightid_sdk";
import * as QrcodeReact from "qrcode.react";
import * as SidebarToggle from "../components/SidebarToggle.js";
import * as React$1 from "@remix-run/react";
import * as Constants$Shared from "../../../../node_modules/@brightidbot/shared/src/Constants.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as Caml_js_exceptions from "../../../../node_modules/rescript/lib/es6/caml_js_exceptions.js";
import * as DiscordLoginButton from "../components/DiscordLoginButton.js";
import * as DiscordLogoutButton from "../components/DiscordLogoutButton.js";
import * as Rainbowkit from "@rainbow-me/rainbowkit";

var QRCodeSvg = {};

function Root_Index$StatusToolTip(props) {
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("p", {
                    children: props.statusMessage,
                    className: "text-xl font-semibold text-white"
                  }),
              className: "" + props.color + " w-full text-center py-1"
            });
}

var StatusToolTip = {
  make: Root_Index$StatusToolTip
};

function Root_Index$BrightIdToolTip(props) {
  var fetcher = props.fetcher;
  var match = fetcher.type;
  switch (match) {
    case "done" :
        var data = fetcher.data;
        if (data == null) {
          return JsxRuntime.jsx(JsxRuntime.Fragment, {});
        }
        var match$1 = data.user;
        if (match$1 == null) {
          return JsxRuntime.jsx(JsxRuntime.Fragment, {});
        }
        var match$2 = data.verifyStatus;
        switch (match$2) {
          case /* Unknown */0 :
              return JsxRuntime.jsx(Root_Index$StatusToolTip, {
                          statusMessage: "Something went wrong when checking your BrightId status",
                          color: "bg-red-600"
                        });
          case /* NotLinked */1 :
              return JsxRuntime.jsx(Root_Index$StatusToolTip, {
                          statusMessage: "You have not linked BrightId to Discord",
                          color: "bg-red-600"
                        });
          case /* NotVerified */2 :
              return JsxRuntime.jsx(Root_Index$StatusToolTip, {
                          statusMessage: "You are not Verified",
                          color: "bg-red-600"
                        });
          case /* NotSponsored */3 :
              return JsxRuntime.jsx(Root_Index$StatusToolTip, {
                          statusMessage: "You are not Sponsored",
                          color: "bg-red-600"
                        });
          case /* Unique */4 :
              return JsxRuntime.jsx(Root_Index$StatusToolTip, {
                          statusMessage: "Verified with BrightID",
                          color: "bg-green-600"
                        });
          
        }
    case "normalLoad" :
        return JsxRuntime.jsx(JsxRuntime.Fragment, {});
    default:
      return JsxRuntime.jsx(JsxRuntime.Fragment, {});
  }
}

var BrightIdToolTip = {
  make: Root_Index$BrightIdToolTip
};

function Root_Index$BrightIdVerificationActions(props) {
  if (props.maybeUser === undefined) {
    return JsxRuntime.jsx(DiscordLoginButton.make, {
                label: "Login to Discord"
              });
  }
  var maybeDeeplink = props.maybeDeeplink;
  var fetcher = props.fetcher;
  var match = fetcher.type;
  switch (match) {
    case "done" :
        var data = fetcher.data;
        if (data == null) {
          return JsxRuntime.jsx(JsxRuntime.Fragment, {});
        }
        var match$1 = data.verifyStatus;
        switch (match$1) {
          case /* NotLinked */1 :
              if (maybeDeeplink !== undefined) {
                return JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("p", {
                                    children: "Scan this code in the BrightID App",
                                    className: "text-2xl text-white"
                                  }),
                              JsxRuntime.jsx(QrcodeReact.QRCodeSVG, {
                                    value: maybeDeeplink
                                  }),
                              JsxRuntime.jsx("a", {
                                    children: "Click here for mobile",
                                    className: "text-white",
                                    href: maybeDeeplink
                                  })
                            ],
                            className: "flex flex-col gap-3 items-center justify-around"
                          });
              } else {
                return JsxRuntime.jsx(React$1.Form, {
                            children: JsxRuntime.jsx("button", {
                                  children: "Link BrightID to Discord",
                                  className: "p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white",
                                  type: "submit"
                                }),
                            method: "get",
                            action: "/"
                          });
              }
          case /* NotVerified */2 :
              return JsxRuntime.jsx("a", {
                          children: JsxRuntime.jsx("button", {
                                children: "Attend a Verification Party to get Verified",
                                className: "p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white"
                              }),
                          className: "text-2xl",
                          href: "https://meet.brightid.org/#/",
                          target: "_blank"
                        });
          case /* NotSponsored */3 :
              return JsxRuntime.jsx("a", {
                          children: JsxRuntime.jsx("button", {
                                children: "Get Sponsored by a BrightID App",
                                className: "p-3 bg-transparent border-2 border-brightid font-semibold rounded-3xl text-xl text-white"
                              }),
                          className: "text-2xl",
                          href: "https://apps.brightid.org/",
                          target: "_blank"
                        });
          case /* Unknown */0 :
          case /* Unique */4 :
              return JsxRuntime.jsx(JsxRuntime.Fragment, {});
          
        }
    case "normalLoad" :
        return JsxRuntime.jsx(JsxRuntime.Fragment, {});
    default:
      return JsxRuntime.jsx(JsxRuntime.Fragment, {});
  }
}

var BrightIdVerificationActions = {
  make: Root_Index$BrightIdVerificationActions
};

async function loader(param) {
  var maybeUser;
  var exit = 0;
  var maybeUser$1;
  try {
    maybeUser$1 = await AuthServer.authenticator.isAuthenticated(param.request);
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID === "JsError") {
      maybeUser = undefined;
    } else {
      throw exn;
    }
  }
  if (exit === 1) {
    maybeUser = (maybeUser$1 == null) ? undefined : Caml_option.some(maybeUser$1);
  }
  var maybeDiscordId = maybeUser !== undefined ? Caml_option.valFromOption(maybeUser).profile.id : undefined;
  if (maybeDiscordId === undefined) {
    return {
            maybeUser: maybeUser,
            maybeDeeplink: undefined
          };
  }
  var contextId = Uuid.v5(maybeDiscordId, process.env.UUID_NAMESPACE);
  var deepLink = Brightid_sdk.generateDeeplink(Constants$Shared.context, contextId, undefined);
  return {
          maybeUser: maybeUser,
          maybeDeeplink: deepLink
        };
}

function Root_Index$default(props) {
  var context = React$1.useOutletContext();
  var fetcher = React$1.useFetcher();
  var match = React$1.useLoaderData();
  var maybeUser = match.maybeUser;
  React.useEffect((function () {
          if (fetcher.type === "init") {
            fetcher.load("/Root_FetchBrightIDDiscord");
          }
          
        }), [fetcher]);
  var match$1 = fetcher.type;
  var unusedSponsorships;
  switch (match$1) {
    case "done" :
        var data = fetcher.data;
        unusedSponsorships = (data == null) ? JsxRuntime.jsx("p", {
                children: "N/A",
                className: "text-white"
              }) : JsxRuntime.jsx("p", {
                children: String(data.unusedSponsorships),
                className: "text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white"
              });
        break;
    case "normalLoad" :
        unusedSponsorships = JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("div", {
                    className: "h-8 bg-gray-300 w-8 rounded-md "
                  }),
              className: " animate-pulse  "
            });
        break;
    default:
      unusedSponsorships = JsxRuntime.jsx("div", {
            children: JsxRuntime.jsx("div", {
                  className: "h-8 bg-gray-300 w-8 rounded-md "
                }),
            className: " animate-pulse  "
          });
  }
  var match$2 = fetcher.type;
  var usedSponsorships;
  switch (match$2) {
    case "done" :
        var data$1 = fetcher.data;
        usedSponsorships = (data$1 == null) ? JsxRuntime.jsx("p", {
                children: "N/A",
                className: "text-white"
              }) : JsxRuntime.jsx("p", {
                children: String(data$1.unusedSponsorships - data$1.assignedSponsorships | 0),
                className: "text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white"
              });
        break;
    case "normalLoad" :
        usedSponsorships = JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("div", {
                    className: "h-8 bg-gray-300 w-8 rounded-md "
                  }),
              className: " animate-pulse  "
            });
        break;
    default:
      usedSponsorships = JsxRuntime.jsx("div", {
            children: JsxRuntime.jsx("div", {
                  className: "h-8 bg-gray-300 w-8 rounded-md "
                }),
            className: " animate-pulse  "
          });
  }
  var match$3 = fetcher.type;
  var verificationCount;
  switch (match$3) {
    case "done" :
        var data$2 = fetcher.data;
        verificationCount = (data$2 == null) ? JsxRuntime.jsx("p", {
                children: "N/A",
                className: "text-white"
              }) : JsxRuntime.jsx("p", {
                children: String(data$2.verificationCount),
                className: "text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white"
              });
        break;
    case "normalLoad" :
        verificationCount = JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("div", {
                    className: "h-8 bg-gray-300 w-8 rounded-md "
                  }),
              className: " animate-pulse  "
            });
        break;
    default:
      verificationCount = JsxRuntime.jsx("div", {
            children: JsxRuntime.jsx("div", {
                  className: "h-8 bg-gray-300 w-8 rounded-md "
                }),
            className: " animate-pulse  "
          });
  }
  var discordLogoutButton = maybeUser !== undefined ? JsxRuntime.jsx(DiscordLogoutButton.make, {
          label: "Log out of Discord"
        }) : JsxRuntime.jsx(JsxRuntime.Fragment, {});
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx("section", {
                      children: JsxRuntime.jsx(Root_Index$BrightIdToolTip, {
                            fetcher: fetcher
                          }),
                      className: "flex justify-center items-center flex-col w-full gap-4 relative"
                    }),
                JsxRuntime.jsxs("header", {
                      children: [
                        JsxRuntime.jsx(SidebarToggle.make, {
                              handleToggleSidebar: context.handleToggleSidebar,
                              maybeUser: maybeUser
                            }),
                        JsxRuntime.jsxs("div", {
                              children: [
                                JsxRuntime.jsx("div", {
                                      children: discordLogoutButton
                                    }),
                                JsxRuntime.jsx(Rainbowkit.ConnectButton, {
                                      className: "h-full"
                                    })
                              ],
                              className: "flex flex-col-reverse md:flex-row items-center justify-center gap-4 "
                            })
                      ],
                      className: "flex flex-row justify-between md:justify-end m-4"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsxs("div", {
                                    children: [
                                      JsxRuntime.jsx("span", {
                                            children: "Unique Discord  ",
                                            className: "px-2 text-4xl md:text-6xl lg:text-8xl lg:leading-loose font-poppins font-extrabold text-transparent bg-[size:1000px_100%] bg-clip-text bg-gradient-to-l from-brightid to-white animate-textscroll "
                                          }),
                                      JsxRuntime.jsx("p", {
                                            children: "Dashboard",
                                            className: " text-slate-300 text-4xl md:text-6xl lg:text-8xl font-poppins font-bold"
                                          })
                                    ]
                                  }),
                              Belt_Option.isSome(maybeUser) ? JsxRuntime.jsx(JsxRuntime.Fragment, {}) : JsxRuntime.jsx(InviteButton.make, {}),
                              JsxRuntime.jsxs("section", {
                                    children: [
                                      JsxRuntime.jsxs("div", {
                                            children: [
                                              JsxRuntime.jsx("div", {
                                                    children: "Available Sponsorships",
                                                    className: "text-2xl font-bold text-white p-2"
                                                  }),
                                              unusedSponsorships
                                            ],
                                            className: "flex flex-col  rounded-xl justify-around items-center text-center "
                                          }),
                                      JsxRuntime.jsxs("div", {
                                            children: [
                                              JsxRuntime.jsx("div", {
                                                    children: "Verifications",
                                                    className: "text-2xl font-bold text-white p-2"
                                                  }),
                                              verificationCount
                                            ],
                                            className: "flex flex-col rounded-xl justify-around items-center text-center px-6 py-10"
                                          }),
                                      JsxRuntime.jsxs("div", {
                                            children: [
                                              JsxRuntime.jsx("div", {
                                                    children: "Total Used Sponsors",
                                                    className: "text-2xl font-bold text-white p-2"
                                                  }),
                                              JsxRuntime.jsx("div", {
                                                    children: usedSponsorships,
                                                    className: "text-2xl font-semibold text-transparent bg-clip-text bg-gradient-to-l from-brightid to-white"
                                                  })
                                            ],
                                            className: "flex flex-col rounded-xl justify-around items-center text-center"
                                          })
                                    ],
                                    className: "width-full flex flex-col md:flex-row justify-around items-center w-full py-2"
                                  }),
                              JsxRuntime.jsx("section", {
                                    children: JsxRuntime.jsx(Root_Index$BrightIdVerificationActions, {
                                          fetcher: fetcher,
                                          maybeUser: maybeUser,
                                          maybeDeeplink: match.maybeDeeplink
                                        }),
                                    className: "flex flex-col justify-center items-center pb-2 gap-8"
                                  })
                            ],
                            className: "flex flex-1 flex-col justify-around items-center text-center h-full"
                          }),
                      className: "flex flex-1 w-full justify-center "
                    })
              ],
              className: "flex flex-col flex-1"
            });
}

var $$default = Root_Index$default;

export {
  QRCodeSvg ,
  StatusToolTip ,
  BrightIdToolTip ,
  BrightIdVerificationActions ,
  loader ,
  $$default ,
  $$default as default,
}
/* uuid Not a pure module */
