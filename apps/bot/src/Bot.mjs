// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Env from "./Env.mjs";
import * as Uuid from "uuid";
import * as Curry from "rescript/lib/es6/curry.js";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as $$Promise from "@ryyppy/rescript-promise/src/Promise.mjs";
import * as Endpoints from "./Endpoints.mjs";
import * as Gist$Utils from "@brightidbot/utils/src/Gist.mjs";
import * as DiscordJs from "discord.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Commands_Help from "./commands/Commands_Help.mjs";
import * as Decode$Shared from "@brightidbot/shared/src/Decode.mjs";
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

var options = {
  intents: [
    "GUILDS",
    "GUILD_MESSAGES",
    "GUILD_MEMBERS"
  ]
};

var client = new DiscordJs.Client(options);

var commands = new DiscordJs.Collection();

var buttons = new DiscordJs.Collection();

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
    });

async function updateGistOnGuildCreate(guild, roleId) {
  var id = envConfig$1.gistId;
  var token = envConfig$1.githubAccessToken;
  var config = Gist$Utils.makeGistConfig(id, "guildData.json", token);
  var guildId = guild.id;
  var content = await Gist$Utils.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds);
  var entry_role = "Verified";
  var entry_name = guild.name;
  var entry_roleId = roleId;
  var entry = {
    role: entry_role,
    name: entry_name,
    inviteLink: undefined,
    roleId: entry_roleId,
    sponsorshipAddress: undefined,
    usedSponsorships: undefined,
    assignedSponsorships: undefined
  };
  return await Gist$Utils.UpdateGist.addEntry(content, guildId, entry, config);
}

async function onGuildCreate(guild) {
  var roleManager = guild.roles;
  var role = await roleManager.create({
        name: "Verified",
        color: "ORANGE",
        reason: "Create a role to mark verified users with BrightID"
      });
  await updateGistOnGuildCreate(guild, role.id);
}

async function onInteraction(interaction) {
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
    } else {
      await Curry._1(command.execute, interaction);
      console.log("Successfully served the command " + commandName + " for " + user.username + "");
    }
    return ;
  }
  if (isButton) {
    var buttonCustomId = interaction.customId;
    var button = buttons.get(buttonCustomId);
    if (button == null) {
      console.error("Bot.res: Button not found");
    } else {
      await Curry._1(button.execute, interaction);
      console.log("Successfully served button press \"" + buttonCustomId + "\" for " + user.username + "");
    }
    return ;
  }
  console.error("Bot.res: Unknown interaction");
}

async function onGuildDelete(guild) {
  var config = Gist$Utils.makeGistConfig(envConfig$1.gistId, "guildData.json", envConfig$1.githubAccessToken);
  var guildId = guild.id;
  var tmp;
  var exit = 0;
  var data;
  try {
    data = await Gist$Utils.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds);
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID === $$Promise.JsError) {
      tmp = undefined;
    } else {
      throw exn;
    }
  }
  if (exit === 1) {
    tmp = Caml_option.some(data);
  }
  var content = Belt_Option.getExn(tmp);
  var brightIdGuild = Js_dict.get(content, guildId);
  if (brightIdGuild === undefined) {
    return Caml_option.some((console.log("No role to delete for guild " + guildId + ""), undefined));
  }
  try {
    await Gist$Utils.UpdateGist.removeEntry(content, guildId, config);
    return Caml_option.some(undefined);
  }
  catch (raw_exn$1){
    var exn$1 = Caml_js_exceptions.internalToOCamlException(raw_exn$1);
    if (exn$1.RE_EXN_ID === $$Promise.JsError) {
      return ;
    }
    throw exn$1;
  }
}

function onGuildMemberAdd(guildMember) {
  var uuid = Uuid.v5(guildMember.id, envConfig$1.uuidNamespace);
  var endpoint = "" + Endpoints.brightIdVerificationEndpoint + "/" + Constants$Shared.context + "/" + uuid + "?timestamp=seconds";
  var params = {
    method: "GET",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    timestamp: 60000
  };
  $$Promise.$$catch(globalThis.fetch(endpoint, params).then(function (res) {
              return res.json();
            }).then(function (json) {
            var match = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.ContextId.data);
            var match$1 = Json$JsonCombinators.decode(json, Decode$Shared.Decode_BrightId.$$Error.data);
            if (match.TAG !== /* Ok */0) {
              if (match$1.TAG === /* Ok */0) {
                return Promise.resolve((console.log(match$1._0.errorMessage), undefined));
              } else {
                return Promise.reject({
                            RE_EXN_ID: Json_Decode$JsonCombinators.DecodeError,
                            _1: match._0
                          });
              }
            }
            if (!match._0.data.unique) {
              return Promise.resolve((console.log("User " + guildMember.displayName + " is not unique"), undefined));
            }
            var __x = Gist$Utils.makeGistConfig(envConfig$1.gistId, "guildData.json", envConfig$1.githubAccessToken);
            return Gist$Utils.ReadGist.content(__x, Decode$Shared.Decode_Gist.brightIdGuilds).then(function (content) {
                        var guild = guildMember.guild;
                        var guildId = guild.id;
                        var brightIdGuild = Belt_Option.getExn(Js_dict.get(content, guildId));
                        var roleId = Belt_Option.getExn(brightIdGuild.roleId);
                        var role = Belt_Option.getExn(Caml_option.nullable_to_opt(guild.roles.cache.get(roleId)));
                        var guildMemberRoleManager = guildMember.roles;
                        guildMemberRoleManager.add(role, "User is already verified by BrightID");
                        return Promise.resolve(undefined);
                      });
          }), (function (err) {
          console.error(err);
          return Promise.resolve(undefined);
        }));
}

function onRoleUpdate(role) {
  var guildId = role.guild.id;
  var config = Gist$Utils.makeGistConfig(envConfig$1.gistId, "guildData.json", envConfig$1.githubAccessToken);
  Gist$Utils.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds).then(function (guilds) {
        var brightIdGuild = Belt_Option.getExn(Js_dict.get(guilds, guildId));
        var roleId = Belt_Option.getExn(brightIdGuild.roleId);
        var isVerifiedRole = role.id === roleId;
        if (!isVerifiedRole) {
          return Promise.resolve(undefined);
        }
        var roleName = role.name;
        var entry_role = roleName;
        var entry_name = brightIdGuild.name;
        var entry_inviteLink = brightIdGuild.inviteLink;
        var entry_roleId = brightIdGuild.roleId;
        var entry_sponsorshipAddress = brightIdGuild.sponsorshipAddress;
        var entry_usedSponsorships = brightIdGuild.usedSponsorships;
        var entry_assignedSponsorships = brightIdGuild.assignedSponsorships;
        var entry = {
          role: entry_role,
          name: entry_name,
          inviteLink: entry_inviteLink,
          roleId: entry_roleId,
          sponsorshipAddress: entry_sponsorshipAddress,
          usedSponsorships: entry_usedSponsorships,
          assignedSponsorships: entry_assignedSponsorships
        };
        return Gist$Utils.UpdateGist.updateEntry(guilds, guildId, entry, config).then(function (param) {
                    return Promise.resolve(undefined);
                  });
      });
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

client.on("guildMemberAdd", onGuildMemberAdd);

client.on("roleUpdate", (function (param, newRole) {
        onRoleUpdate(newRole);
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
  options ,
  client ,
  commands ,
  buttons ,
  updateGistOnGuildCreate ,
  onGuildCreate ,
  onInteraction ,
  onGuildDelete ,
  onGuildMemberAdd ,
  onRoleUpdate ,
}
/*  Not a pure module */
