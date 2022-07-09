module User = {
  type t
  type profile
  @get external getAccessToken: t => string = "accessToken"
  @get external getProfile: t => profile = "profile"
  @get external getId: profile => string = "id"
}

module DiscordStrategy = {
  type t
  module CreateDiscordStategyOptions = {
    type t
    @obj
    external make: (
      ~clientID: string,
      ~clientSecret: string,
      ~callbackURL: string,
      // Provide all the scopes you want as an array
      ~scope: array<string>,
      unit,
    ) => t = ""
  }

  // module CreateVerifyFunctionOptions = {
  //   type t
  //   @obj
  //   external make: (
  //     ~accessToken: string,
  //     ~refreshToken: string,
  //     ~extraParams: 'a,
  //     ~profile: 'b,
  //     unit,
  //   ) => t = ""
  // }
  type verifyFunctionParams<'a, 'b> = {
    accessToken: string,
    refreshToken: string,
    extraParams: 'a,
    profile: 'b,
  }

  @module("remix-auth-socials") @new
  external make: (
    CreateDiscordStategyOptions.t,
    verifyFunctionParams<'a, 'b> => Js.Promise.t<'a>,
  ) => t = "DiscordStrategy"
}

// module SocialsProvider = {
//   type t = [#Discord]

// }

module CreateAuthenticateOptions = {
  type t

  @obj external make: (~successRedirect: string=?, ~failureRedirect: string=?, unit) => t = ""
}

module Authenticator = {
  type t
  @module("remix-auth") @new external make: Remix.SessionStorage.t => t = "Authenticator"
  @send external use: (t, DiscordStrategy.t) => unit = "use"
  @send
  external authenticate: (t, string, Webapi.Fetch.Request.t) => Js.Promise.t<User.t> =
    "authenticate"

  @send
  external authenticateWithOptions: (
    t,
    string,
    Webapi.Fetch.Request.t,
    ~options: CreateAuthenticateOptions.t=?,
    unit,
  ) => Js.Promise.t<User.t> = "authenticate"
  @send
  external isAuthenticated: (t, Webapi.Fetch.Request.t) => Js.Promise.t<Js.Nullable.t<User.t>> =
    "isAuthenticated"
  @send
  external isAuthenticatedWithOptions: (
    t,
    Webapi.Fetch.Request.t,
    ~options: CreateAuthenticateOptions.t,
  ) => Js.Promise.t<Js.Nullable.t<User.t>> = "isAuthenticated"
}
