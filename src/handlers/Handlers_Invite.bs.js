// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Belt_Array = require("rescript/lib/js/belt_Array.js");
var UpdateOrReadGistJs = require("../updateOrReadGist.js");

function updateGist(prim0, prim1) {
  return UpdateOrReadGistJs.updateGist(prim0, prim1);
}

function invite(member, param, message) {
  var guild = message.guild;
  var isAdmin = member.hasPermission("ADMINISTRATOR");
  if (!isAdmin) {
    return message.reply("You do not have the admin privileges for this command");
  }
  var inviteCommandArray = message.content.split(" ");
  var inviteLink = Belt_Array.get(inviteCommandArray, 1);
  if (inviteLink !== undefined) {
    UpdateOrReadGistJs.updateGist(guild.id, {
          inviteLink: inviteLink
        });
    return message.reply("Succesfully update server invite link to " + inviteLink);
  } else {
    return message.reply("Please Format your command like `!invite <invite link>`");
  }
}

exports.updateGist = updateGist;
exports.invite = invite;
/* ../updateOrReadGist.js Not a pure module */