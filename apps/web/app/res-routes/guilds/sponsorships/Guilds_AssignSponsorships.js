// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "../../../../../../node_modules/rescript/lib/es6/curry.js";
import * as React from "react";
import * as Wagmi from "wagmi";
import * as Core__Option from "../../../../../../node_modules/@rescript/core/src/Core__Option.js";
import ReactLottie from "react-lottie";
import * as Caml_exceptions from "../../../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as React$1 from "@remix-run/react";
import * as Constants$Shared from "../../../../node_modules/@brightidbot/shared/src/Constants.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as Rainbowkit from "@rainbow-me/rainbowkit";

var NoAccountAddress = /* @__PURE__ */Caml_exceptions.create("Guilds_AssignSponsorships.NoAccountAddress");

function Guilds_AssignSponsorships$Modal(props) {
  var match = React.useState(function () {
        return true;
      });
  if (!match[0]) {
    return JsxRuntime.jsx(JsxRuntime.Fragment, {});
  }
  var setShowModal = match[1];
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx("div", {
                            children: props.children,
                            className: "relative w-auto my-6 max-w-3xl "
                          }),
                      className: "justify-center items-center flex overflow-x-hidden overflow-y-auto fixed inset-0 z-50 outline-none focus:outline-none flex-1"
                    }),
                JsxRuntime.jsx("div", {
                      className: "opacity-25 fixed inset-0 z-40 bg-black",
                      onClick: (function (param) {
                          Curry._1(setShowModal, (function (param) {
                                  return false;
                                }));
                        })
                    })
              ]
            });
}

var Modal = {
  make: Guilds_AssignSponsorships$Modal
};

var Lottie = {};

var assignSPYellow = (require("~/lotties/assignSPYellow.json"));

var assignSPRed = (require("~/lotties/assignSPRed.json"));

var assignSPBlue = (require("~/lotties/assignSPBlue.json"));

var abi = (require("~/../../packages/shared/src/abi/SP.json"));

function Guilds_AssignSponsorships$default(props) {
  React$1.useParams();
  var transition = React$1.useTransition();
  var match = Wagmi.useAccount(undefined);
  var maybeAddress = match.address;
  var address = Core__Option.getWithDefault(maybeAddress, "");
  var mainnetSP = Wagmi.useBalance({
        address: address,
        token: Constants$Shared.contractAddressETH,
        chainId: 1
      });
  var idSP = Wagmi.useBalance({
        address: address,
        token: Constants$Shared.contractAddressID,
        chainId: 74
      });
  var match$1 = mainnetSP.status;
  var formattedMainnetSP = match$1 === "error" ? "Error" : (
      match$1 === "loading" ? "Loading" : (
          match$1 === "success" ? Core__Option.getWithDefault(Core__Option.map(mainnetSP.data, (function (data) {
                        return data.formatted;
                      })), "0") : "unknown"
        )
    );
  var match$2 = idSP.status;
  var formattedIDSP = match$2 === "error" ? "Error" : (
      match$2 === "loading" ? "Loading" : (
          match$2 === "success" ? Core__Option.getWithDefault(Core__Option.map(idSP.data, (function (data) {
                        return data.formatted;
                      })), "0") : "unknown"
        )
    );
  var makeDefaultOptions = function (animationData) {
    return {
            loop: true,
            autoplay: true,
            animationData: animationData,
            rendererSettings: {
              preserveAspectRatio: "xMidYMid slice"
            }
          };
  };
  return JsxRuntime.jsx("div", {
              children: maybeAddress !== undefined ? (
                  transition.state === "submitting" ? JsxRuntime.jsxs("div", {
                          children: [
                            JsxRuntime.jsx(ReactLottie, {
                                  options: makeDefaultOptions(assignSPYellow),
                                  style: {
                                    width: "25vw"
                                  }
                                }),
                            JsxRuntime.jsx("p", {
                                  children: "Assigning Sponsorships to Server",
                                  className: "text-white font-bold text-24"
                                })
                          ]
                        }) : JsxRuntime.jsxs(React$1.Form, {
                          className: "flex flex-col width-full height-full",
                          children: [
                            JsxRuntime.jsxs("div", {
                                  children: [
                                    JsxRuntime.jsx("label", {
                                          children: "ID SP",
                                          className: "text-white font-bold text-32"
                                        }),
                                    JsxRuntime.jsx("p", {
                                          children: "" + formattedIDSP + "",
                                          className: "text-white font-bold text-24"
                                        }),
                                    JsxRuntime.jsx("label", {
                                          children: "Mainnet SP",
                                          className: "text-white font-bold text-32"
                                        }),
                                    JsxRuntime.jsx("p", {
                                          children: "" + formattedMainnetSP + "",
                                          className: "text-white font-bold text-24"
                                        })
                                  ],
                                  className: "flex justify-around p-10"
                                }),
                            JsxRuntime.jsx("input", {
                                  defaultValue: "1",
                                  className: "appearance-none text-white bg-transparent text-3xl text-center p-5",
                                  name: "sponsorships",
                                  type: "number"
                                }),
                            JsxRuntime.jsx("button", {
                                  children: "Assign",
                                  className: "text-white p-5",
                                  type: "submit"
                                })
                          ]
                        })
                ) : JsxRuntime.jsx(Rainbowkit.ConnectButton, {}),
              className: "flex flex-1 width-full height-full justify-center items-center"
            });
}

var contractAddressID = Constants$Shared.contractAddressID;

var contractAddressETH = Constants$Shared.contractAddressETH;

var $$default = Guilds_AssignSponsorships$default;

export {
  NoAccountAddress ,
  Modal ,
  Lottie ,
  contractAddressID ,
  contractAddressETH ,
  assignSPYellow ,
  assignSPRed ,
  assignSPBlue ,
  abi ,
  $$default ,
  $$default as default,
}
/* assignSPYellow Not a pure module */
