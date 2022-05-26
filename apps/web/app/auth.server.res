// open Promise
// module RemixAuth = {
//   module DiscordStrategy = {
//     type t
//     module CreateDiscordStategyOptions = {
//       type t
//       @obj
//       external make: (
//         ~clientID: string,
//         ~clientSecret: string,
//         ~callbackURL: string,
//         // Provide all the scopes you want as an array
//         ~scope: array<string>,
//         unit,
//       ) => t = ""
//     }
//     @module("remix-auth") @new
//     external make: (CreateDiscordStategyOptions.t, unit => Js.Promise.t<unit>) => 'a =
//       "DiscordStrategy"
//   }
//   module Authenticator = {
//     type t
//     @module("remix-auth") @new external make: Remix.SessionStorage.t => t = "Authenticator"
//     @send external use: (t, DiscordStrategy.t) => unit = "use"
//   }
// }

// let sessionStorage: Remix.SessionStorage.t = %raw(`require("./session.server.js").sessionStorage`)

// let auth = sessionStorage->RemixAuth.Authenticator.make
// let discordStrategy =
//   RemixAuth.DiscordStrategy.CreateDiscordStategyOptions.make(
//     ~clientID="946229600575438878",
//     ~clientSecret="",
//     ~callbackURL="http://localhost:3000/auth/discord/callback",
//     ~scope=["identify", "email", "guilds"],
//     (),
//   )->RemixAuth.DiscordStrategy.make(() => {Promise.resolve()})

// auth->RemixAuth.Authenticator.use(discordStrategy)

