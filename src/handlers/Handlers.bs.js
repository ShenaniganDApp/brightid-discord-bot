// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Handlers_Role = require("./Handlers_Role.bs.js");
var Belt_MapString = require("rescript/lib/js/belt_MapString.js");
var Handlers_BrightId = require("./Handlers_BrightId.bs.js");

var handlers = Belt_MapString.fromArray([
      [
        "!verify",
        Handlers_Verify.verify
      ],
        "!role",
        Handlers_Role.role
      ],
      [
        "!brightid",
        Handlers_BrightId.brightId
      ]
    ]);

exports.handlers = handlers;
/* handlers Not a pure module */