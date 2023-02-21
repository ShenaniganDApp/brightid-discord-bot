open Promise

exception EmptySubmit
exception GuildDoesNotExist(string)

// @module("../../helpers/updateOrReadGist.js")
// external updateGist: (string, 'a) => promise<unit> = "updateGist"

let botToken = Remix.process["env"]["DISCORD_API_TOKEN"]

let loader: Remix.loaderFunction<Webapi.Fetch.Response.t> = ({params}) => {
  let guildId = params->Dict.get("guildId")->Option.getExn
  Remix.redirect(`/guilds/${guildId}/admin`)->resolve
}

let modifyRoleUrl = (guildId, roleId) => `https://discord.com/api/guilds/${guildId}/roles/${roleId}`

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
    Webapi.FormData.get(formData, field)->Option.flatMap(someIfString)
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

  let guildId = params->Dict.get("guildId")->Option.getWithDefault("")
  // let roleId = params->Dict.get("roleId")->Option.getWithDefault("")

  let _ = switch await RemixAuth.Authenticator.isAuthenticated(AuthServer.authenticator, request) {
  | data => Some(data)
  | exception JsError(_) => None
  }

  let data = await Request.formData(request)

  let {role, inviteLink, sponsorshipAddress} = Form.make(data)
  // let _ = switch role {
  // | Some(role) =>
  //   let headers = HeadersInit.make({
  //     "Authorization": `Bot ${botToken}`,
  //     "Content-Type": "application/x-www-form-urlencoded",
  //   })
  //   let body = BodyInit.make(`{name: ${role}}`)
  //   let init = RequestInit.make(~method_=Patch, ~headers, ~body, ())

  //   let req = modifyRoleUrl(guildId, roleId)->Request.makeWithInit(init)
  //   switch await fetchWithRequest(req) {
  //   | data =>
  //     Console.log(data)
  //     Some(data)
  //   | exception JsError(e) =>
  //    Console.log(e)
  //     None
  //   }
  // | None => None
  // }

  open WebUtils_Gist
  let config = makeGistConfig(
    ~id=Remix.process["env"]["GIST_ID"],
    ~name="guildData.json",
    ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
  )
  let content = await ReadGist.content(~config, ~decoder=Shared.Decode.Decode_Gist.brightIdGuilds)
  let prevEntry = switch content->Dict.get(guildId) {
  | Some(entry) => entry
  | None => GuildDoesNotExist(guildId)->raise
  }

  let atleastOneSome = Array.some([role, inviteLink, sponsorshipAddress], Option.isSome)
  switch atleastOneSome {
  | false => EmptySubmit->Error
  | true => {
      open Option
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
  //       resolve(Nullable.null)
  //     }

  //   | _ => {
  //       Remix.redirect(`/guilds/${guildId}/admin`)->ignore
  //       resolve(Nullable.null)
  //     }
  //   }
  // })
}
