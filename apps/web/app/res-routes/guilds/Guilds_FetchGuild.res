open Shared
type loaderData = {
  maybeDiscordGuild: option<Types.guild>,
  maybeBrightIdGuild: option<BrightId.Gist.brightIdGuild>,
  isAdmin: bool,
}

type params = {guildId: string}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open DiscordServer
  open Promise

  let config = WebUtils_Gist.makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(maybeUser => {
    switch maybeUser->Js.Nullable.toOption {
    | None => {maybeDiscordGuild: None, isAdmin: false, maybeBrightIdGuild: None}->resolve
    | Some(user) =>
      open Shared.Decode
      WebUtils_Gist.ReadGist.content(
        ~config,
        ~decoder=Decode_Gist.brightIdGuilds,
      )->then(brightIdGuilds => {
        let maybeBrightIdGuild = brightIdGuilds->Js.Dict.get(guildId)
        fetchDiscordGuildFromId(~guildId)->then(
          maybeDiscordGuild => {
            let userId = user->RemixAuth.User.getProfile->RemixAuth.User.getId
            fetchGuildMemberFromId(~guildId, ~userId)->then(
              guildMember => {
                let memberRoles = switch guildMember->Js.Nullable.toOption {
                | None => []
                | Some(guildMember) => guildMember.roles
                }
                fetchGuildRoles(~guildId)->then(
                  guildRoles => {
                    let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
                    let isOwner = switch maybeDiscordGuild->Js.Nullable.toOption {
                    | None => false
                    | Some(guild) => guild.owner_id === userId
                    }
                    {
                      maybeDiscordGuild: maybeDiscordGuild->Js.Nullable.toOption,
                      isAdmin: isAdmin || isOwner,
                      maybeBrightIdGuild,
                    }->resolve
                  },
                )
              },
            )
          },
        )
      })
    }
  })
  ->catch(error => {
    switch error {
    | DiscordRateLimited =>
      {maybeDiscordGuild: None, isAdmin: false, maybeBrightIdGuild: None}->resolve
    | _ => {maybeDiscordGuild: None, isAdmin: false, maybeBrightIdGuild: None}->resolve
    }
  })
}
