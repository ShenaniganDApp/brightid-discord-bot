open Promise

exception EmptySubmit

@module("../../helpers/updateOrReadGist.js")
external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

let loader: Remix.loaderFunction<Webapi.Fetch.Response.t> = ({params}) => {
  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("0x")
  Remix.redirect(`/guilds/${guildId}/admin`)->resolve
}

let urlModifyRole = (guildId, roleId) => `/guilds/${guildId}/roles/${roleId}`

let action: Remix.actionFunction<'a> = ({request, params}) => {
  open Webapi.Fetch

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(_ => {
    request
    ->Request.formData
    ->then(data => {
      let headers = HeadersInit.make({
        "Authorization": `Bot ${botToken}`,
      })
      let init = RequestInit.make(~method_=Patch, ~headers, ())

      guildId
      ->urlModifyRole("roleId")
      ->Request.makeWithInit(init)
      ->fetchWithRequest
      ->then(
        _ => {
          let role = data->Webapi.FormData.get("role")
          let inviteLink = data->Webapi.FormData.get("inviteLink")
          let sponsorshipAddress = data->Webapi.FormData.get("sponsorshipAddress")

          switch (role, inviteLink, sponsorshipAddress) {
          | (Some(role), Some(inviteLink), Some(sponsorshipAddress)) =>
            guildId
            ->updateGist({
              "role": role,
              "inviteLink": inviteLink,
              "sponsorshipAddress": sponsorshipAddress,
            })
            ->then(
              _ => {
                resolve(Js.Nullable.null)
              },
            )
          | _ => EmptySubmit->reject
          }
        },
      )
    })
    ->catch(e => {
      switch e {
      | EmptySubmit => {
          Remix.redirect(`/guilds/${guildId}/admin`)->ignore
          resolve(Js.Nullable.null)
        }

      | _ => {
          Remix.redirect(`/guilds/${guildId}/admin`)->ignore
          resolve(Js.Nullable.null)
        }
      }
    })
  })
}
