// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "./Env.mjs";
import * as Uuid from "uuid";
import * as Curry from "rescript/lib/es6/curry.js";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as $$Promise from "@ryyppy/rescript-promise/src/Promise.mjs";
import * as Endpoints from "./Endpoints.mjs";
import * as Exceptions from "./Exceptions.mjs";
import * as Gist$Utils from "@brightidbot/utils/src/Gist.mjs";
import * as DiscordJs from "discord.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Commands_Help from "./commands/Commands_Help.mjs";
import * as Decode$Shared from "@brightidbot/shared/src/Decode.mjs";
import * as Belt_SetString from "rescript/lib/es6/belt_SetString.js";
import * as Buttons_Verify from "./buttons/Buttons_Verify.mjs";
import * as Commands_Guild from "./commands/Commands_Guild.mjs";
import * as Buttons_Sponsor from "./buttons/Buttons_Sponsor.mjs";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as Commands_Invite from "./commands/Commands_Invite.mjs";
import * as Commands_Verify from "./commands/Commands_Verify.mjs";
import * as Constants$Shared from "@brightidbot/shared/src/Constants.mjs";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.mjs";
import * as UpdateOrReadGistMjs from "./updateOrReadGist.mjs";
import * as Buttons_PremiumSponsor from "./buttons/Buttons_PremiumSponsor.mjs";
import * as Services_VerificationInfo from "./services/Services_VerificationInfo.mjs";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.mjs";

var RequestHandlerError = /* @__PURE__ */Caml_exceptions.create("Bot.RequestHandlerError");

var GuildNotInGist = /* @__PURE__ */Caml_exceptions.create("Bot.GuildNotInGist");

function updateGist(prim0, prim1) {
  return UpdateOrReadGistMjs.updateGist(prim0, prim1);
}

Env.createEnv(undefined);

var envConfig = Env.getConfig(undefined);

var envConfig$1;

if (envConfig.TAG === /* Ok */0) {
  envConfig$1 = envConfig._0;
} else {
  throw {
        RE_EXN_ID: Env.EnvError,
        _1: envConfig._0,
        Error: new Error()
      };
}

function gistConfig(param) {
  var id = envConfig$1.gistId;
  var token = envConfig$1.githubAccessToken;
  return Gist$Utils.makeGistConfig(id, "guildData.json", token);
}

var options_intents = [
  "GUILDS",
  "GUILD_MESSAGES",
  "GUILD_MEMBERS"
];

var options_partials = ["GUILD_MEMBER"];

var options = {
  intents: options_intents,
  partials: options_partials
};

var client = new DiscordJs.Client(options);

var commands = new DiscordJs.Collection();

var buttons = new DiscordJs.Collection();

function makeGistConfig(param) {
  return Gist$Utils.makeGistConfig(envConfig$1.gistId, "guildData.json", envConfig$1.githubAccessToken);
}

commands.set(Commands_Help.data.name, {
            data: Commands_Help.data,
            execute: Commands_Help.execute
          }).set(Commands_Verify.data.name, {
          data: Commands_Verify.data,
          execute: Commands_Verify.execute
        }).set(Commands_Invite.data.name, {
        data: Commands_Invite.data,
        execute: Commands_Invite.execute
      }).set(Commands_Guild.data.name, {
      data: Commands_Guild.data,
      execute: Commands_Guild.execute
    });

buttons.set(Buttons_Verify.customId, {
          customId: Buttons_Verify.customId,
          execute: Buttons_Verify.execute
        }).set(Buttons_Sponsor.customId, {
        customId: Buttons_Sponsor.customId,
        execute: Buttons_Sponsor.execute
      }).set(Buttons_PremiumSponsor.customId, {
      customId: Buttons_PremiumSponsor.customId,
      execute: Buttons_PremiumSponsor.execute
    });

async function updateGistOnGuildCreate(guild, roleId, content) {
  var guildId = guild.id;
  var entry_role = "Verified";
  var entry_name = guild.name;
  var entry_roleId = roleId;
  var entry = {
    role: entry_role,
    name: entry_name,
    inviteLink: undefined,
    roleId: entry_roleId,
    sponsorshipAddress: undefined,
    sponsorshipAddressEth: undefined,
    usedSponsorships: undefined,
    assignedSponsorships: undefined,
    premiumSponsorshipsUsed: undefined,
    premiumExpirationTimestamp: undefined
  };
  return await Gist$Utils.UpdateGist.addEntry(content, guildId, entry, makeGistConfig(undefined));
}

async function fetchContextIds(retryOpt, param) {
  var retry = retryOpt !== undefined ? retryOpt : 5;
  var endpoint = "" + Endpoints.brightIdVerificationEndpoint + "/" + Constants$Shared.context + "";
  var params = {
    method: "GET",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    timestamp: 60000
  };
  var res = await globalThis.fetch(endpoint, params);
  var json = await res.json();
  var match = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.Verifications.data);
  var match$1 = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.$$Error.data);
  if (match.TAG === /* Ok */0) {
    return Belt_SetString.fromArray(match._0.data.contextIds);
  }
  if (match$1.TAG === /* Ok */0) {
    var retry$1 = retry - 1 | 0;
    if (retry$1 !== 0) {
      return await fetchContextIds(retry$1, undefined);
    }
    throw {
          RE_EXN_ID: Exceptions.BrightIdError,
          _1: match$1._0,
          Error: new Error()
        };
  }
  var retry$2 = retry - 1 | 0;
  if (retry$2 !== 0) {
    return await fetchContextIds(retry$2, undefined);
  }
  throw {
        RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
        _1: match._0,
        Error: new Error()
      };
}

async function assignRoleOnCreate(guild, role) {
  var maybeMembers;
  var exit = 0;
  var members;
  try {
    members = await guild.members.fetch();
    exit = 1;
  }
  catch (exn){
    maybeMembers = undefined;
  }
  if (exit === 1) {
    maybeMembers = Caml_option.some(members);
  }
  var contextIds = await fetchContextIds(undefined, undefined);
  var makeAddRolePromises = function (members) {
    return members.filter(function (__x) {
                    return Belt_SetString.has(contextIds, Uuid.v5(__x.id, envConfig$1.uuidNamespace));
                  }).mapValues(function (__x) {
                  return __x.roles.add(role, undefined);
                }).values();
  };
  var addRolePromises = Belt_Option.map(maybeMembers, makeAddRolePromises);
  if (addRolePromises === undefined) {
    return 0;
  }
  var results;
  try {
    results = await Promise.all(addRolePromises);
  }
  catch (e){
    throw e;
  }
  return results.length;
}

async function onGuildCreate(guild) {
  var roleManager = guild.roles;
  var guildId = guild.id;
  var guildName = guild.name;
  var id = envConfig$1.gistId;
  var token = envConfig$1.githubAccessToken;
  var config = Gist$Utils.makeGistConfig(id, "guildData.json", token);
  var role = await roleManager.create({
        name: "Verified",
        color: "ORANGE",
        reason: "Create a role to mark verified users with BrightID"
      });
  var exit = 0;
  var role$1;
  try {
    role$1 = role;
    exit = 1;
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    console.error("" + guildName + " : " + guildId + ": ", e);
    return ;
  }
  if (exit === 1) {
    var content = await Gist$Utils.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds);
    var exit$1 = 0;
    var val;
    try {
      val = await updateGistOnGuildCreate(guild, role$1.id, content);
      exit$1 = 2;
    }
    catch (raw_e$1){
      var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
      console.error("" + guildName + " : " + guildId + ": ", e$1);
      return ;
    }
    if (exit$1 === 2) {
      console.log("" + guildName + " : " + guildId + ": Successfully added to the database");
      var exit$2 = 0;
      var verifiedMembersCount;
      try {
        verifiedMembersCount = await assignRoleOnCreate(guild, role$1);
        exit$2 = 3;
      }
      catch (raw_e$2){
        var e$2 = Caml_js_exceptions.internalToOCamlException(raw_e$2);
        console.error("" + guildName + " : " + guildId + ": ", e$2);
        return ;
      }
      if (exit$2 === 3) {
        console.log("" + guildName + " : " + guildId + ": Successfully assigned role to " + String(verifiedMembersCount) + " current members");
        return ;
      }
      
    }
    
  }
  
}

async function onInteraction(interaction) {
  var guildId = interaction.guild.id;
  var guildName = interaction.guild.name;
  var isCommand = interaction.isCommand();
  var isButton = interaction.isButton();
  var user = interaction.user;
  if (isCommand) {
    if (isButton) {
      console.error("Bot.res: Unknown interaction");
      return ;
    }
    var commandName = interaction.commandName;
    var command = commands.get(commandName);
    if (command == null) {
      console.error("Bot.res: Command not found");
      return ;
    }
    var val;
    try {
      val = await Curry._1(command.execute, interaction);
    }
    catch (raw_e){
      var e = Caml_js_exceptions.internalToOCamlException(raw_e);
      if (e.RE_EXN_ID === Exceptions.BrightIdError) {
        console.error("" + guildName + " : " + guildId + ": ", e._1.errorMessage);
      } else if (e.RE_EXN_ID === Exceptions.VerifyCommandError) {
        console.error("" + guildName + " : " + guildId + ": ", e._1);
      } else if (e.RE_EXN_ID === Exceptions.InviteCommandError) {
        console.error("" + guildName + " : " + guildId + ": ", e._1);
      } else if (e.RE_EXN_ID === $$Promise.JsError) {
        console.error("" + guildName + " : " + guildId + ": ", e._1);
      } else {
        console.error("" + guildName + " : " + guildId + ": ", e);
      }
      return ;
    }
    console.log("" + guildName + " : " + guildId + ": Successfully served the command " + commandName + " for " + user.username + "");
    return ;
  }
  if (isButton) {
    var buttonCustomId = interaction.customId;
    var button = buttons.get(buttonCustomId);
    if (button == null) {
      console.error("Bot.res: Button not found");
      return ;
    }
    var val$1;
    try {
      val$1 = await Curry._1(button.execute, interaction);
    }
    catch (raw_e$1){
      var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
      if (e$1.RE_EXN_ID === Exceptions.BrightIdError) {
        console.error("" + guildName + " : " + guildId + ": ", e$1._1.errorMessage);
      } else if (e$1.RE_EXN_ID === Exceptions.PremiumSponsorButtonError) {
        console.error("" + guildName + " : " + guildId + ": ", e$1._1);
      } else if (e$1.RE_EXN_ID === Exceptions.SponsorButtonError) {
        console.error("" + guildName + " : " + guildId + ": ", e$1._1);
      } else if (e$1.RE_EXN_ID === Exceptions.ButtonVerifyHandlerError) {
        console.error("" + guildName + " : " + guildId + ": ", e$1._1);
      } else if (e$1.RE_EXN_ID === $$Promise.JsError) {
        console.error("" + guildName + " : " + guildId + ": ", e$1._1);
      } else {
        console.error("" + guildName + " : " + guildId + ": ", e$1);
      }
      return ;
    }
    console.log("" + guildName + " : " + guildId + ": Successfully served button press \"" + buttonCustomId + "\" for " + user.username + "");
    return ;
  }
  console.error("Bot.res: Unknown interaction");
}

async function onGuildDelete(guild) {
  var guildId = guild.id;
  var guildName = guild.name;
  var exit = 0;
  var guilds;
  try {
    guilds = await Gist$Utils.ReadGist.content(gistConfig(undefined), Decode$Shared.Decode_Gist.brightIdGuilds);
    exit = 1;
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e.RE_EXN_ID === $$Promise.JsError) {
      console.error("" + guildName + " : " + guildId + ": ", e._1);
      return ;
    }
    throw e;
  }
  if (exit === 1) {
    var match = Js_dict.get(guilds, guildId);
    if (match !== undefined) {
      var exit$1 = 0;
      var val;
      try {
        val = await Gist$Utils.UpdateGist.removeEntry(guilds, guildId, gistConfig(undefined));
        exit$1 = 2;
      }
      catch (raw_e$1){
        var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
        if (e$1.RE_EXN_ID === $$Promise.JsError) {
          console.error("" + guildName + " : " + guildId + ": ", e$1._1);
          return ;
        }
        throw e$1;
      }
      if (exit$1 === 2) {
        console.log("" + guildName + " : " + guildId + ": Successfully removed guild data");
        return ;
      }
      
    } else {
      console.error("" + guildName + " : " + guildId + ": Could not find guild data to delete");
      return ;
    }
  }
  
}

async function onGuildMemberAdd(guildMember) {
  var guildName = guildMember.guild.name;
  var guildId = guildMember.guild.id;
  var exit = 0;
  var val;
  try {
    val = await Services_VerificationInfo.getBrightIdVerification(guildMember);
    exit = 1;
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e.RE_EXN_ID === Exceptions.BrightIdError) {
      console.error("" + guildName + " : " + guildId + ": ", e._1.errorMessage);
    } else if (e.RE_EXN_ID === $$Promise.JsError) {
      console.error("" + guildName + " : " + guildId + ": ", e._1);
    } else {
      console.error("" + guildName + " : " + guildId + ": ", e);
    }
  }
  if (exit === 1) {
    if (val._0.unique) {
      var exit$1 = 0;
      var guilds;
      try {
        guilds = await Gist$Utils.ReadGist.content(gistConfig(undefined), Decode$Shared.Decode_Gist.brightIdGuilds);
        exit$1 = 2;
      }
      catch (raw_e$1){
        var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
        console.error("" + guildName + " : " + guildId + ": ", e$1);
      }
      if (exit$1 === 2) {
        var guild = guildMember.guild;
        var guildId$1 = guild.id;
        var brightIdGuild = Js_dict.get(guilds, guildId$1);
        if (brightIdGuild !== undefined) {
          var roleId = brightIdGuild.roleId;
          if (roleId !== undefined) {
            var role = guild.roles.cache.get(roleId);
            if (role == null) {
              console.error("" + guildName + " : " + guildId$1 + ": ", "Role does not exist");
            } else {
              var guildMemberRoleManager = guildMember.roles;
              var exit$2 = 0;
              var val$1;
              try {
                val$1 = await guildMemberRoleManager.add(role, "User is already verified by BrightID");
                exit$2 = 3;
              }
              catch (raw_e$2){
                var e$2 = Caml_js_exceptions.internalToOCamlException(raw_e$2);
                console.error("" + guildName + " : " + guildId$1 + ": ", e$2);
              }
              if (exit$2 === 3) {
                var uuid = Uuid.v5(guildMember.id, envConfig$1.uuidNamespace);
                console.log("" + guildName + " : " + guildId$1 + " verified the user with contextId: " + uuid + "");
              }
              
            }
          } else {
            console.error("" + guildName + " : " + guildId$1 + ": ", "Guild does not have a saved roleId");
          }
        } else {
          console.error("" + guildName + " : " + guildId$1 + ": ", "Guild does not exist in Gist");
        }
      }
      
    } else {
      console.error("" + guildName + " : " + guildId + ": ", "User " + guildMember.displayName + " is not unique");
    }
  }
  
}

async function onRoleUpdate(role) {
  var guildId = role.guild.id;
  var guildName = role.guild.name;
  var exit = 0;
  var content;
  try {
    content = await Gist$Utils.ReadGist.content(gistConfig(undefined), Decode$Shared.Decode_Gist.brightIdGuilds);
    exit = 1;
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    console.error("" + guildName + " : " + guildId + ": ", e);
    return ;
  }
  if (exit === 1) {
    var brightIdGuild = Js_dict.get(content, guildId);
    if (brightIdGuild !== undefined) {
      var roleId = brightIdGuild.roleId;
      if (roleId !== undefined) {
        var isVerifiedRole = role.id === roleId;
        if (!isVerifiedRole) {
          return ;
        }
        var roleName = role.name;
        var entry_role = roleName;
        var entry_name = brightIdGuild.name;
        var entry_inviteLink = brightIdGuild.inviteLink;
        var entry_roleId = brightIdGuild.roleId;
        var entry_sponsorshipAddress = brightIdGuild.sponsorshipAddress;
        var entry_sponsorshipAddressEth = brightIdGuild.sponsorshipAddressEth;
        var entry_usedSponsorships = brightIdGuild.usedSponsorships;
        var entry_assignedSponsorships = brightIdGuild.assignedSponsorships;
        var entry_premiumSponsorshipsUsed = brightIdGuild.premiumSponsorshipsUsed;
        var entry_premiumExpirationTimestamp = brightIdGuild.premiumExpirationTimestamp;
        var entry = {
          role: entry_role,
          name: entry_name,
          inviteLink: entry_inviteLink,
          roleId: entry_roleId,
          sponsorshipAddress: entry_sponsorshipAddress,
          sponsorshipAddressEth: entry_sponsorshipAddressEth,
          usedSponsorships: entry_usedSponsorships,
          assignedSponsorships: entry_assignedSponsorships,
          premiumSponsorshipsUsed: entry_premiumSponsorshipsUsed,
          premiumExpirationTimestamp: entry_premiumExpirationTimestamp
        };
        var exit$1 = 0;
        var val;
        try {
          val = await Gist$Utils.UpdateGist.updateEntry(content, guildId, entry, gistConfig(undefined));
          exit$1 = 2;
        }
        catch (raw_e$1){
          var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
          console.error("" + guildName + " : " + guildId + ": ", e$1);
          return ;
        }
        if (exit$1 === 2) {
          console.log("" + guildName + " : " + guildId + " updated the role name to " + roleName + "");
          return ;
        }
        
      } else {
        console.error("" + guildName + " : " + guildId + ": ", "Guild does not have a saved roleId");
        return ;
      }
    } else {
      console.error("" + guildName + " : " + guildId + ": ", "Guild does not exist in Gist");
      return ;
    }
  }
  
}

async function onGuildMemberUpdate(param, newMember) {
  var guild = newMember.guild;
  var guildName = guild.name;
  var guildId = guild.id;
  var exit = 0;
  var guilds;
  try {
    guilds = await Gist$Utils.ReadGist.content(gistConfig(undefined), Decode$Shared.Decode_Gist.brightIdGuilds);
    exit = 1;
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    console.error("" + guildName + " : " + guildId + ": ", e);
  }
  if (exit === 1) {
    var match = Js_dict.get(guilds, guildId);
    if (match !== undefined) {
      var roleId = match.roleId;
      if (roleId !== undefined) {
        var exit$1 = 0;
        var member;
        try {
          member = await guild.members.fetch(newMember.id);
          exit$1 = 2;
        }
        catch (raw_e$1){
          var e$1 = Caml_js_exceptions.internalToOCamlException(raw_e$1);
          console.error("" + guildName + " : " + guildId + ": ", e$1);
        }
        if (exit$1 === 2) {
          var exit$2 = 0;
          var val;
          try {
            val = await Services_VerificationInfo.getBrightIdVerification(member);
            exit$2 = 3;
          }
          catch (raw_e$2){
            var e$2 = Caml_js_exceptions.internalToOCamlException(raw_e$2);
            if (e$2.RE_EXN_ID === Exceptions.BrightIdError) {
              var role = guild.roles.cache.get(roleId);
              var guildMemberRoleManager = newMember.roles;
              if (!(role == null)) {
                var exit$3 = 0;
                var val$1;
                try {
                  val$1 = await guildMemberRoleManager.remove(role, "User is not verified by BrightID");
                  exit$3 = 4;
                }
                catch (raw_e$3){
                  var e$3 = Caml_js_exceptions.internalToOCamlException(raw_e$3);
                  console.error("" + guildName + " : " + guildId + ": ", e$3);
                }
                if (exit$3 === 4) {
                  var uuid = Uuid.v5(member.id, envConfig$1.uuidNamespace);
                  console.log("" + guildName + " : " + guildId + " removed the role with contextId: " + uuid + " because the user is not verified, but was assigned the role");
                }
                
              }
              
            } else if (e$2.RE_EXN_ID === $$Promise.JsError) {
              console.error("" + guildName + " : " + guildId + ": ", e$2._1);
            } else {
              console.error("" + guildName + " : " + guildId + ": ", e$2);
            }
          }
          if (exit$2 === 3) {
            var unique = val._0.unique;
            var guildMemberRoleManager$1 = member.roles;
            var roles = guildMemberRoleManager$1.cache;
            var role$1 = guild.roles.cache.get(roleId);
            var match$1 = roles.has(roleId);
            if (!(role$1 == null)) {
              if (match$1) {
                if (!unique) {
                  var exit$4 = 0;
                  var val$2;
                  try {
                    val$2 = await guildMemberRoleManager$1.remove(role$1, "User is not verified by BrightID");
                    exit$4 = 4;
                  }
                  catch (raw_e$4){
                    var e$4 = Caml_js_exceptions.internalToOCamlException(raw_e$4);
                    console.error("" + guildName + " : " + guildId + ": ", e$4);
                  }
                  if (exit$4 === 4) {
                    var uuid$1 = Uuid.v5(newMember.id, envConfig$1.uuidNamespace);
                    console.log("" + guildName + " : " + guildId + " removed the role with contextId: " + uuid$1 + " because the user is not verified but was manually assigned the role");
                  }
                  
                }
                
              } else if (unique) {
                var guildMemberRoleManager$2 = member.roles;
                var exit$5 = 0;
                var val$3;
                try {
                  val$3 = await guildMemberRoleManager$2.add(role$1, "User is verified by BrightID");
                  exit$5 = 4;
                }
                catch (raw_e$5){
                  var e$5 = Caml_js_exceptions.internalToOCamlException(raw_e$5);
                  console.error("" + guildName + " : " + guildId + ": ", e$5);
                }
                if (exit$5 === 4) {
                  var uuid$2 = Uuid.v5(newMember.id, envConfig$1.uuidNamespace);
                  console.log("" + guildName + " : " + guildId + " added the role with contextId: " + uuid$2 + " because the user is verified, but was not assigned the role");
                }
                
              }
              
            }
            
          }
          
        }
        
      }
      
    }
    
  }
  
}

client.on("ready", (function (param) {
        console.log("Logged In");
      }));

client.on("guildCreate", (function (guild) {
        onGuildCreate(guild);
      }));

client.on("interactionCreate", (function (interaction) {
        onInteraction(interaction);
      }));

client.on("guildDelete", (function (guild) {
        onGuildDelete(guild);
      }));

client.on("guildMemberAdd", (function (member) {
        onGuildMemberAdd(member);
      }));

client.on("roleUpdate", (function (param, newRole) {
        onRoleUpdate(newRole);
      }));

client.on("guildMemberUpdate", (function (oldMember, newMember) {
        onGuildMemberUpdate(oldMember, newMember);
      }));

client.login(envConfig$1.discordApiToken);

var brightIdVerificationEndpoint = Endpoints.brightIdVerificationEndpoint;

var context = Constants$Shared.context;

export {
  brightIdVerificationEndpoint ,
  context ,
  RequestHandlerError ,
  GuildNotInGist ,
  updateGist ,
  envConfig$1 as envConfig,
  gistConfig ,
  options ,
  client ,
  commands ,
  buttons ,
  makeGistConfig ,
  updateGistOnGuildCreate ,
  fetchContextIds ,
  assignRoleOnCreate ,
  onGuildCreate ,
  onInteraction ,
  onGuildDelete ,
  onGuildMemberAdd ,
  onRoleUpdate ,
  onGuildMemberUpdate ,
}
/*  Not a pure module */
