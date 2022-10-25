open Promise

exception EmptySubmit
exception GuildDoesNotExist(string)

// @module("../../helpers/updateOrReadGist.js")
// external updateGist: (string, 'a) => Js.Promise.t<unit> = "updateGist"

let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

let loader: Remix.loaderFunction<Webapi.Fetch.Response.t> = ({params}) => {
  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getExn
  Remix.redirect(`/guilds/${guildId}/admin`)->resolve
}

let modifyRoleUrl = (guildId, roleId) => `/guilds/${guildId}/roles/${roleId}`

module Form = {
  type t = {
    role: option<string>,
    inviteLink: option<string>,
    sponsorshipAddress: option<string>,
  }

  let someIfString = entryValue => {
    switch Webapi.FormData.EntryValue.classify(entryValue) {
    | #String(x) => x === "" ? None : Some(x)
    | #File(_) => None
    }
  }

  let getIfString = (formData, field) => {
    Webapi.FormData.get(formData, field)->Belt.Option.flatMap(someIfString)
  }

  let make = formData => {
    {
      role: getIfString(formData, "role"),
      inviteLink: getIfString(formData, "inviteLink"),
      sponsorshipAddress: getIfString(formData, "sponsorshipAddress"),
    }
  }
}

let action: Remix.actionFunction<'a> = async ({request, params}) => {
  open Webapi.Fetch

  let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")
  let roleId = params->Js.Dict.get("roleId")->Belt.Option.getWithDefault("")

  let _ = switch await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request) {
  | data => Some(data)
  | exception JsError(_) => None
  }

  let data = await Request.formData(request)

  let {role, inviteLink, sponsorshipAddress} = Form.make(data)
  let _ = switch role {
  | Some(role) =>
    let headers = HeadersInit.make({
      "Authorization": `Bot ${botToken}`,
      "Content-Type": "application/x-www-form-urlencoded",
    })
    let body = BodyInit.make(`{name: ${role}}`)
    let init = RequestInit.make(~method_=Patch, ~headers, ~body, ())
    Some()
  // let req =
  //   `https://discord.com/api/guilds/${guildId}/roles/${roleId}`->Request.makeWithInit(init)
  // switch await fetchWithRequest(req) {
  // | data =>
  //   Js.log(data)
  //   Some(data)
  // | exception JsError(e) =>
  //   Js.log(e)
  //   None
  // }
  | None => None
  }

  open WebUtils_Gist
  let config = makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )
  let content = await ReadGist.content(~config, ~decoder=Shared.Decode.Gist.brightIdGuilds)
  let prevEntry = switch content->Js.Dict.get(guildId) {
  | Some(entry) => entry
  | None => GuildDoesNotExist(guildId)->raise
  }

  let atleastOneSome = Belt.Array.some([role, inviteLink, sponsorshipAddress], Belt.Option.isSome)
  switch atleastOneSome {
  | false => EmptySubmit->Error
  | true => {
      open Belt.Option
      let entry = {
        ...prevEntry,
        role: isSome(role) ? role : prevEntry.role,
        inviteLink: isSome(inviteLink) ? inviteLink : prevEntry.inviteLink,
        sponsorshipAddress: isSome(sponsorshipAddress)
          ? sponsorshipAddress
          : prevEntry.sponsorshipAddress,
      }

      switch await UpdateGist.updateEntry(~content, ~key=guildId, ~config, ~entry) {
      | data => Ok(data)
      | exception JsError(e) => JsError(e)->Error
      }
    }
  }

  // ->catch(e => {
  //   switch e {
  //   | EmptySubmit => {
  //       Remix.redirect(`/guilds/${guildId}/admin`)->ignore
  //       resolve(Js.Nullable.null)
  //     }

  //   | _ => {
  //       Remix.redirect(`/guilds/${guildId}/admin`)->ignore
  //       resolve(Js.Nullable.null)
  //     }
  //   }
  // })
}
