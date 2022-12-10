open Shared
exception NoBrightIdData

type params = {guildId: string}

type loaderData = {
  maybeUser: option<RemixAuth.User.t>,
  maybeBrightIdGuild: option<BrightId.Gist.brightIdGuild>,
  maybeDiscordGuild: option<Types.guild>,
  isAdmin: bool,
}

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
    | None =>
      Remix.redirect(`/guilds/${guildId}`)->ignore
      {
        maybeUser: None,
        maybeBrightIdGuild: None,
        isAdmin: false,
        maybeDiscordGuild: None,
      }->resolve
    | Some(user) =>
      open Shared.Decode
      WebUtils_Gist.ReadGist.content(~config, ~decoder=Decode_Gist.brightIdGuilds)->then(guilds => {
        let maybeBrightIdGuild = guilds->Js.Dict.get(guildId)
        fetchDiscordGuildFromId(~guildId)->then(
          maybeDiscordGuild => {
            let maybeDiscordGuild = maybeDiscordGuild->Js.Nullable.toOption
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
                    let isOwner = switch maybeDiscordGuild {
                    | None => false
                    | Some(guild) => guild.owner_id === userId
                    }

                    {
                      maybeUser: Some(user),
                      maybeBrightIdGuild,
                      isAdmin: isAdmin || isOwner,
                      maybeDiscordGuild,
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
}

let truncateAddress = address =>
  address->Js.String2.slice(~from=0, ~to_=6) ++
  "..." ++
  address->Js.String2.slice(~from=-5, ~to_=Js.String.length(address))

type state = {
  role: option<string>,
  inviteLink: option<string>,
  sponsorshipAddress: option<string>,
}

let state = {
  role: None,
  inviteLink: None,
  sponsorshipAddress: None,
}

type actions =
  | RoleChanged(option<string>)
  | InviteLinkChanged(option<string>)
  | SponsorshipAddressChanged(option<string>)

let reducer = (state, action) =>
  switch action {
  | RoleChanged(role) => {...state, role}
  | InviteLinkChanged(inviteLink) => {...state, inviteLink}
  | SponsorshipAddressChanged(sponsorshipAddress) => {
      ...state,
      sponsorshipAddress,
    }
  }

@react.component
let default = () => {
  open Remix
  let context = useOutletContext()
  let {maybeBrightIdGuild, isAdmin, maybeDiscordGuild, maybeUser} = useLoaderData()
  let {guildId} = useParams()
  let account = Wagmi.useAccount()

  let (state, dispatch) = React.useReducer(reducer, state)

  let roleId = switch maybeBrightIdGuild {
  | None => NoBrightIdData->raise
  | Some(brightIdGuild) =>
    switch brightIdGuild.roleId {
    | None => ""
    | Some(roleId) => roleId
    }
  }

  let sign = switch maybeDiscordGuild {
  | None => None // Toast error
  | Some(guild) =>
    Wagmi.useSignMessage({
      "message": `I consent that the SP in this address is able to be used by members of ${guild.name} Discord Server`,
      "onError": e =>
        switch e["name"] {
        | "ConnectorNotFoundError" =>
          ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error("No wallet found", ())
        | _ => ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.error(e["message"], ())
        },
      "onSuccess": _ => {
        switch account["data"]->Js.Nullable.toOption {
        | None => Js.log(account)
        | Some(data) => {
            data["address"]->Js.Nullable.toOption->SponsorshipAddressChanged->dispatch
            ReactHotToast.Toaster.makeToaster->ReactHotToast.Toaster.success("Signed", ())
          }
        }
      },
    })->Some
  }

  let handleSign = (_: ReactEvent.Mouse.t) =>
    switch sign {
    | None => ()
    | Some(sign) => sign["signMessage"]()
    }

  let reset = _ => {
    None->RoleChanged->dispatch
    None->InviteLinkChanged->dispatch
    None->SponsorshipAddressChanged->dispatch
  }

  let onRoleChanged = e => {
    let value = ReactEvent.Form.currentTarget(e)["value"]->Js.Nullable.toOption
    value->RoleChanged->dispatch
  }

  let onInviteLinkChanged = e => {
    let value = ReactEvent.Form.currentTarget(e)["value"]->Js.Nullable.toOption
    value->InviteLinkChanged->dispatch
  }

  // let onSponsorshipAddressChanged = e => {
  //   let value = ReactEvent.Form.currentTarget(e)["value"]->Js.Nullable.toOption
  //   switch brightIdGuild->Js.Nullable.toOption {
  //   | Some({sponsorshipAddress}) =>
  //     switch sponsorshipAddress->Js.Nullable.toOption === value {
  //     | true => None->SponsorshipAddressChanged->dispatch
  //     | false => value->SponsorshipAddressChanged->dispatch
  //     }
  //   | None => NoBrightIdData->raise
  //   }
  // }

  let onSubmit = _ => {
    // let t = ReactHotToast.Toaster.makeToaster
    // ReactHotToast.Toaster.makeCustomToaster(t => <div> {"Submitted"->React.string} </div>)
    reset()
  }

  let isSomeOrString = value =>
    switch value {
    | None => false
    | Some(value) => !(value === "")
    }

  let hasChangesToSave = Belt.Array.some(
    [state.role, state.inviteLink, state.sponsorshipAddress],
    isSomeOrString,
  )
  switch maybeUser {
  | None => <DiscordLoginButton label="Login to Discord" />
  | Some(_) =>
    switch isAdmin {
    | false =>
      <div className="flex flex-1">
        <header className="flex flex-row justify-between md:justify-end m-4">
          <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} maybeUser />
          <Link
            className="p-2 bg-transparent font-semibold rounded-3xl text-4xl text-white"
            to={`/guilds/${guildId}`}>
            {`⬅️`->React.string}
          </Link>
        </header>
        <div className="flex justify-center items-center text-white text-3xl font-bold">
          <div> {"You are not an admin in this server"->React.string} </div>
        </div>
      </div>
    | true =>
      switch maybeDiscordGuild {
      | None => <> </>
      | Some(guild) =>
        <div className="flex-1 p-4">
          <ReactHotToast.Toaster />
          <div className="flex flex-col flex-1 h-full">
            <header className="flex flex-row justify-between m-4">
              <div className="flex flex-col md:flex-row gap-3">
                <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} maybeUser />
                <Link
                  className="p-2 bg-transparent font-semibold rounded-3xl text-4xl text-white"
                  to={`/guilds/${guildId}`}>
                  {`⬅️`->React.string}
                </Link>
              </div>
              <RainbowKit.ConnectButton className="h-full" />
            </header>
            <Remix.Form
              method={#post}
              action={`/guilds/${guildId}/${roleId}/adminSubmit`}
              className=" flex-1 text-white text-2xl font-semibold justify-center  items-center relative">
              <div>
                <div> {"Admin Commands"->React.string} </div>
                <img className=" w-48 h-48 p-5 rounded" src={guild->Helpers_Guild.iconUri} />
              </div>
              <div className="flex flex-1 justify-around flex-col items-center ">
                {switch maybeBrightIdGuild {
                | None =>
                  <div className="text-white text-2xl font-semibold justify-center items-center">
                    <div> {"This server is not using BrightID"->React.string} </div>
                  </div>
                | Some(brightIdGuild) =>
                  <div className="flex flex-col flex-1 justify-center items-start gap-4">
                    <label className="flex flex-col gap-2">
                      {"Role Name"->React.string}
                      <input
                        className="text-white p-2 rounded bg-extraDark cursor-not-allowed"
                        type_="text"
                        name="role"
                        placeholder={brightIdGuild.role->Belt.Option.getWithDefault("No Role Name")}
                        value={state.role->Belt.Option.getWithDefault("")}
                        onChange={onRoleChanged}
                        disabled={true}
                      />
                    </label>
                    <label className="flex flex-col gap-2">
                      {"Public Invite Link"->React.string}
                      <input
                        className="text-white p-2 bg-extraDark outline-none"
                        name="inviteLink"
                        type_="text"
                        placeholder={brightIdGuild.inviteLink->Belt.Option.getWithDefault(
                          "No Invite Link",
                        )}
                        value={state.inviteLink->Belt.Option.getWithDefault("")}
                        onChange=onInviteLinkChanged
                      />
                    </label>
                    <label className="flex flex-col gap-2">
                      {"Sponsorship Address"->React.string}
                      <div className="flex flex-row gap-4 bg-transparent">
                        <input
                          className="text-white p-2 bg-dark"
                          name="sponsorshipAddress"
                          type_="text"
                          placeholder={brightIdGuild.sponsorshipAddress
                          ->Belt.Option.getWithDefault("0x")
                          ->truncateAddress}
                          value={state.sponsorshipAddress->Belt.Option.getWithDefault("")}
                          readOnly={true}
                        />
                        <div
                          className="p-2 border-2 border-brightid text-white font-xl rounded"
                          onClick={handleSign}>
                          {React.string("Sign")}
                        </div>
                      </div>
                    </label>
                  </div>
                }}
              </div>
              <SubmitPopup hasChangesToSave reset />
            </Remix.Form>
          </div>
        </div>
      }
    }
  }
}
