type loaderData = {
  guild: option<Types.guild>,
  brightIdGuild: option<Shared.BrightId.brightIdGuild>,
  isAdmin: bool,
}

type params = {guildId: string}

let loader: Remix.loaderFunction<loaderData> = ({request, params}) => {
  open DiscordServer
  open Promise
  open Shared

  let config = WebUtils_Gist.makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
    switch user->Js.Nullable.toOption {
    | None => {guild: None, isAdmin: false, brightIdGuild: None}->resolve
    | Some(user) =>
      WebUtils_Gist.ReadGist.content(
        ~config,
        ~decoder=Decode.Gist.brightIdGuilds,
      )->then(brightIdGuilds => {
        let brightIdGuild = brightIdGuilds->Js.Dict.get(guildId)
        fetchGuildFromId(~guildId)->then(
          guild => {
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
                    let isOwner = switch guild->Js.Nullable.toOption {
                    | None => false
                    | Some(guild) => guild.owner_id === userId
                    }
                    {
                      guild: guild->Js.Nullable.toOption,
                      isAdmin: isAdmin || isOwner,
                      brightIdGuild,
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
    | DiscordRateLimited => {guild: None, isAdmin: false, brightIdGuild: None}->resolve
    | _ => {guild: None, isAdmin: false, brightIdGuild: None}->resolve
    }
  })
}
