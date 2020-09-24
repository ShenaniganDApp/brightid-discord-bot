const Discord = require('discord.js');
const dotenv = require('dotenv');
const { environment } = require('./environment');
const client = new Discord.Client();
const QRCode = require('qrcode');
const detectHandler = require('./parser/detectHandler');
const { RequestHandlerError, WhitelistedChannelError } = require('./error-utils');
const { error, log } = require('./utils');
const parseWhitelistedChannels = require('./parser/whitelistedChannels');

dotenv.config();
client.on('ready', () => {
	console.log(`Logged in as ${client.user.tag}!`);
});

client.on('message', (message) => {
	if (message.author.bot) {
		return;
	}
	try {
		const whitelistedChannels = parseWhitelistedChannels();

		const messageWhitelisted = whitelistedChannels.reduce(
			(whitelisted, channel) => channel === message.channel.name || channel === '*' || whitelisted,
			false
		);

		if (!messageWhitelisted && whitelistedChannels) {
			return;
    }
    
    const handler = detectHandler(message.content);
    console.log('handler: ', handler);
		handler(message);
		log(`Served command ${message.content} successfully for ${message.author.username}`);
	} catch (err) {
		if (err instanceof RequestHandlerError) {
			message.reply('Could not find the requested command. Please use !ac help for more info.');
		} else if (err instanceof WhitelistedChannelError) {
			error('FATAL: No whitelisted channels set in the environment variables.');
		}
	}
});
QRCode.toDataURL('I am a pony!', function (err, url) {
  console.log(url)
})

client.login(process.env.DISCORD_API_TOKEN);
