<div align="center">
	<br />
	<p>
		<a href="https://bot.brightid.org"><img src="https://i.imgur.com/zCL03cc.png" width="546" alt="bright id discord bot" /></a>
	</p>
	<br />
	<p>
		<a href="https://vercel.com/?utm_source=brightid&utm_campaign=oss"><img src="https://raw.githubusercontent.com/discordjs/discord.js/main/.github/powered-by-vercel.svg" alt="Vercel" /></a>
	</p>
</div>

A [Discord Bot](https://bot.brightid.org) that empowers servers with BrightID's Sybil Resistant Social Graph

## Development

```sh-session
yarn
yarn re:build
yarn web dev
```

## Building

```
yarn web build
```

## Environment setup

You will need to make a `.env` file in the web app root

```sh-session
touch ./apps/web/.env
```

### Env Fields

You can see an example in `.env.sample`

`UUID_NAMESPACE`: UUID v5 Namespace ([Generate a random one](https://www.uuidtools.com/v5))

`DISCORD_API_TOKEN`: Discord Bot Token ([Go to Discord Developer Portal](https://discord.com/developers/applications))

`DISCORD_CLIENT_SECRET`: Discord Client Secret ([Go to Discord Developer Portal](https://discord.com/developers/applications))

`DISCORD_CLIENT_ID`: Discord Client ID ([Go to Discord Developer Portal](https://discord.com/developers/applications))

`GIST_ID`: ID of the github gist to use as a database

`GITHUB_ACCESS_TOKEN`: Github Token that has the `gist` attribute

`ALCHEMY_ID`: Alchemy Ethereum API KEY
