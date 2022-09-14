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

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("0x")
  AuthServer.authenticator
  ->RemixAuth.Authenticator.isAuthenticated(request)
  ->then(user => {
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
        res => {
          let role = data->Webapi.FormData.get("role")
          let inviteLink = data->Webapi.FormData.get("inviteLink")

          switch (role, inviteLink) {
          | (Some(role), Some(inviteLink)) =>
            guildId->updateGist({"role": role, "inviteLink": inviteLink})
          | _ => EmptySubmit->reject
          }
        },
      )
    })
    ->catch(e => {
      switch e {
      | EmptySubmit => {
          Remix.redirect(`/guilds/${guildId}/admin`)->ignore
          resolve()
        }

      | _ => {
          Remix.redirect(`/guilds/${guildId}/admin`)->ignore
          resolve()
        }
      }
    })
  })
}
