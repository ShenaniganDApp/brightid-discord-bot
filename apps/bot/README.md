# BrightID Discord Bot

:robot: BrightID Bot to verify users in Discord.

<a href="https://bot.brightid.org">Click here to Invite BrightID Bot to your server</a>

## Quick end-user guide

Interacting with the bot is simple;

- "/verify": Sends a QR Code to link the BrightID app to Discord

### To use BrightID Bot:

1. Type /verify
2. Scan the code (or click the link) BrightID Bot shows you
3. Use an [app that has sponsorships](https://apps.brightid.org).
4. Click the button Verifying a successful Discord link

## Developer quick start

Use Node.js 22 and the repository's bundled Yarn 1.18.0. Run these commands from the repository root:

```sh
nvm install
nvm use
yarn install --frozen-lockfile
yarn bot rescript build -with-deps
yarn bot test:qr
yarn bot dev
```

The repository uses the locally installed ReScript 11.1.0 compiler from `yarn.lock`, with `rescript.json` configuration and ES module output in `.mjs` files. Its ReScript 11 build commands remain in use; upgrading to ReScript 12 requires a separate language and dependency migration.

Verification QR attachments use `qrcode`'s PNG buffer renderer and do not require native Canvas or Cairo libraries. `yarn bot test:qr` decodes the actual attachments from the verification and sponsorship flows without connecting to Discord.

Node.js 22 satisfies the [current ReScript installation prerequisites](https://rescript-lang.org/docs/manual/installation/). `.nvmrc`, the Node engine declarations, and `nixpacks.toml` select the same Node major version. Nixpacks deployments must not override `NIXPACKS_NODE_VERSION` with an older version in their service settings.

Configure the required environment variables before starting the bot. `yarn bot dev` launches the bot with hot reloading; rebuild ReScript after source changes or run `yarn bot watch:rescript` in a separate terminal.

There are a few other scripts provided:

- `start`: Starts up the bot without hot reloading; used for the heroku deployment described below.

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
