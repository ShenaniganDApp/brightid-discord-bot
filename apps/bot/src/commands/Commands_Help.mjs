// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Builders from "@discordjs/builders";

var helpMessage = "```\n__**Available BrightId Unique Bot commands:**__\n\n- `/verify` → Sends a BrightID QR code for users to connect with their BrightId\n\n- `/guilds` → View a list of discord servers that use this bot. Lots of cool servers use BrightId for token airdrops 😉\n\n\nServer Admin only:\n- `/role` → Use this command to change the name of the \"Verified\" role\n\n- `/invite` → Use this command to add an invite for this discord to the guilds\n\n```";

var data = new Builders.SlashCommandBuilder().setName("help").setDescription("Explain the BrightId bot commands");

function execute(interaction) {
  interaction.reply(helpMessage, {
        ephemeral: true
      });
  return Promise.resolve(undefined);
}

export {
  helpMessage ,
  data ,
  execute ,
  
}
/* data Not a pure module */
