# BrightID Discord Bot

:robot: BrightID Bot to verify users in Discord.

<a href="https://bot.brightid.org">Click here to Invite BrightID Bot to your server</a>

## Quick end-user guide

Interacting with the bot is simple; it offers 2 commands

- "!verify": Sends a QR Code to link the BrightID app to Discord

- "!me": Adds the "Verified" role to verified users

### To use BrightID Bot:

1. Type !verify
2. Scan the code (or click the link) BrightID Bot shows you
3. Use an [app that has sponsorships](https://apps.brightid.org).
4. Type !me

## Developer quick start

`yarn` followed by `yarn dev` will launch the bot locally, with hot reloading included.

There are a few other scripts provided:

- `start`: Starts up the bot without hot reloading; used for the heroku deployment described below.
- `lint`: Lints the project with ESLint.
- `test`: Runs all the tests! (If you contribute some code, please do write tests for it ⌨️!)

### Configuration

For the bot to run properly, it needs these variables, laid out in the `.env.sample` file:

There have been staging variables supplied for you already to help you get started an safely test new code.

- [Join the testing server](https://discord.gg/KA7qVfVW)

- `DISCORD_API_TOKEN`: A discord API token. [See this guide on how to obtain one](https://github.com/reactiflux/discord-irc/wiki/Creating-a-discord-bot-&-getting-a-token).
- `UUID_NAMESPACE`: Generate a new one [here](https://www.uuidgenerator.net/version4)

- `GIST_ID`: The ID of the gist being used to store guild data. The staging gist is [here](https://gist.github.com/brightidbotdev/617e860aeb4a21ae2118947e6fbedccdX)

- `GITHUB_ACCESS_TOKEN`: A personal access token with write acesss to the Gist provided in `GIST_ID`

- `WHITELISTED_CHANNELS`: The whitelisted channels for the bot to read messages from, in the form of comma separated words, as in `bot,general,channel`. If you want the bot to listen to all channels, set this variable to `*`.

### Deployment

You'll need a service to host this bot 💆‍♀️ but do not despair! There's an easy, already configured way of doing this by deploying it to heroku! Just go through these steps:

- Create a new Heroku app and link it to GitHub
- Search for the repo and connect it
- Enable "automatic deploys" for the app
- BONUS: If you want to be able to run this bot 24/7, you can add link your billing info to Heroku, and will give you a 1000 hours for free, enough for a bot instance.

### Contributing

Don't be shy to contribute even the smallest tweak. 🐲 There are still some dragons to be aware of, but we'll be here to help you get started!
