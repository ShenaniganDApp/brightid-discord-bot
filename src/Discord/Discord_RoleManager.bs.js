// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Discord_Role = require("./Discord_Role.bs.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");

var CreateRoleError = /* @__PURE__ */Caml_exceptions.create("Discord_RoleManager.CreateRoleError");

function create(roleManager, options) {
  var name = Discord_Role.validateRoleName(options.data.name);
  var color = Discord_Role.validateColor(options.data.color);
  var reason = Discord_Role.validateReason(options.reason);
  var data = {
    name: name,
    color: color
  };
  return roleManager.create({
              data: data,
              reason: reason
            });
}

exports.CreateRoleError = CreateRoleError;
exports.create = create;
/* No side effect */
