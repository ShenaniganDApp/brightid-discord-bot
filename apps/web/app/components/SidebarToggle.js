// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "../../../../node_modules/rescript/lib/es6/curry.js";
import * as React from "react";
import * as Fa from "react-icons/fa";

var FaBars = {};

function SidebarToggle(Props) {
  var handleToggleSidebar = Props.handleToggleSidebar;
  return React.createElement("div", {
              className: "md:hidden cursor-pointer w-12 h-12 bg-dark text-center text-white rounded-full flex justify-center items-center font-xl",
              onClick: (function (param) {
                  return Curry._1(handleToggleSidebar, true);
                })
            }, React.createElement(Fa.FaBars, {
                  size: 30
                }));
}

var make = SidebarToggle;

export {
  FaBars ,
  make ,
  
}
/* react Not a pure module */
