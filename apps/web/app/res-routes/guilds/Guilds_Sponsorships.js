// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "../../../../../node_modules/rescript/lib/es6/curry.js";
import * as React from "react";
import * as Remix from "remix";
import * as Wagmi from "wagmi";
import * as SidebarToggle from "../../components/SidebarToggle.js";

function Guilds_Sponsorships$default(Props) {
  var context = Remix.useOutletContext();
  var sign = Wagmi.useSignMessage({
        message: "I am the owner of and would like to use its sponsorhips in\n    X"
      });
  var handleSign = function (param) {
    Curry._1(sign.signMessage, undefined);
  };
  return React.createElement("div", {
              className: "p-4 h-full w-full"
            }, React.createElement(SidebarToggle.make, {
                  handleToggleSidebar: context.handleToggleSidebar
                }), React.createElement("div", {
                  className: "flex flex-col items-center justify-around  text-white h-full "
                }, React.createElement("button", {
                      className: "p-4 bg-brightid rounded-xl shadow-lg text-white disabled:bg-disabled disabled:text-slate-400 disabled:cursor-not-allowed font-poppins font-bold",
                      onClick: handleSign
                    }, "Link Sponsorships to Discord"), React.createElement("img", {
                      className: "w-64",
                      alt: "BrightID",
                      src: "/assets/brightid_logo.png"
                    })));
}

var $$default = Guilds_Sponsorships$default;

export {
  $$default ,
  $$default as default,
}
/* react Not a pure module */
