const QRCode = require('qrcode');
const sponsorUser = require('../services/sponsorUser');
const endpoints = require('../endpoints');

// Component will render if user does not exist or is not sponsored
module.exports = function verify(message) {
	const error = null;
	const deepLink = `${endpoints.BRIGHT_ID_APP_DEEPLINK}/${message.author.id}`;

	let cancelled = false;

	const sponsor = async () => {
		try {
			// If the user exists, means it's not sponsored yet
			const { error } = await sponsorUser(message.author.id);

			if (error && !cancelled) {
				setError(`Error sponsoring account: ${error}`);
				message.author.send(`Error sponsoring account: ${error}`);
			}
		} catch (err) {
			console.error('Error when sponsoring account: ', err);
			message.author.send(`Error sponsoring account: ${error}`);
		}
		cancelled = true;
	};

	sponsor();

	console.log('Connect with BrightID');

	message.author.id
		? error
			? console.log('error')
			: message.author.send(
					'Something went wrong while executing the command. Please try again in a few minutes.'
			  )
		: message.author.send('qrcode');

		  // )
};

// module.exports = function verify(message) {
//     message.reply(helpContent)
//   }
// const fetch = require('node-fetch')
// const { environment } = require('../environment')
// const {
//   decodeData,
//   encodeData,
//   marshallFileUpdate,
//   marshallUser,
// } = require('../handler-utils')
// const { error, log } = require('../utils')

// const GITHUB_API_URL = 'https://api.github.com'

// module.exports = function signup(message) {
//   try {

//     fetch(`${GITHUB_API_URL}/repos/${environment('GITHUB_FILE_PATH')}`, {
//       method: 'GET',
//       headers: {
//         Authorization: `Bearer ${environment('GITHUB_API_TOKEN')}`,
//       },
//     })
//       .then(res => res.json())
//       .then(body => {
//         const encodedContent = body.content
//         const fileSha = body.sha
//         log(
//           `fetched file with sha ${fileSha} for user ${message.author.username}`,
//         )
//         // Decode the content from the Github API response, as
//         // it's returned as a base64 string.
//         const decodedContent = decodeData(encodedContent) // Manipulated the decoded content:
//         // First, check if the user already exists.
//         // If it does, stop the process inmediately.
//         const userExists = decodedContent[1].identities.find(
//           identity =>
//             identity.username.toLowerCase() === username.toLowerCase(),
//         )

//         if (userExists) {
//           message.reply('You have already registered.')
//           log(
//             `Detected ${message.author.username} already exists with username ${username}`,
//           )
//           return
//         }
//         // If the user is not registered, we can now proceed to mutate
//         // the file by appending the user to the end of the array.
//         const userIdentity = marshallUser({ username, platforms })
//         decodedContent[1].identities.push(userIdentity)
//         // We encode the updated content to base64.
//         const updatedContent = encodeData(decodedContent)
//         // We prepare the body to be sent to the API.
//         const marshalledBody = marshallFileUpdate({
//           message: 'Update project.json',
//           content: updatedContent,
//           sha: fileSha,
//         })
//         // And we update the project.json file directly.
//         fetch(`${GITHUB_API_URL}/repos/${environment('GITHUB_FILE_PATH')}`, {
//           method: 'PUT',
//           headers: {
//             Authorization: `Bearer ${environment('GITHUB_API_TOKEN')}`,
//           },
//           body: marshalledBody,
//         }).then(() => {
//           log('Updated file on GitHub successfully.')
//           message.reply('Update was successful!')
//         })
//       })
//       .catch(err => {
//         error(err)
//         message.reply(
//           'Something went wrong while executing the command. Please try again in a few minutes.',
//         )
//       })
//   } catch (err) {
//     log(err)
//     message.reply(
//       'Command parsing failed. Please use the !ac help command to see how to use the requested command properly.',
//     )
//   }
// }
