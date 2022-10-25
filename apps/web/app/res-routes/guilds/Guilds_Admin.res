exception NoBrightIdData

type params = {guildId: string}

type loaderData = {
  user: Js.Nullable.t<RemixAuth.User.t>,
  brightIdGuild: Js.Nullable.t<Types.brightIdGuildData>,
  guild: Js.Nullable.t<Types.guild>,
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
  ->then(user => {
    WebUtils_Gist.ReadGist.content(
      ~config,
      ~decoder=Shared.Decode.Gist.brightIdGuilds,
    )->then(guilds => {
      switch user->Js.Nullable.toOption {
      | None =>
        {
          user: Js.Nullable.null,
          brightIdGuild: Js.Nullable.null,
          isAdmin: false,
          guild: Js.Nullable.null,
        }->resolve
      | Some(existingUser) => {
          let guildData = guilds->Js.Dict.get(guildId)->Belt.Option.getExn
          fetchGuildFromId(~guildId)->then(
            guild => {
              let userId = existingUser->RemixAuth.User.getProfile->RemixAuth.User.getId
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

                      //@TODO: This should use the decoder type
                      let brightIdGuild: Types.brightIdGuildData = {
                        name: guildData.name->Js.Nullable.fromOption,
                        role: guildData.role->Js.Nullable.fromOption,
                        inviteLink: guildData.inviteLink->Js.Nullable.fromOption,
                        sponsorshipAddress: guildData.sponsorshipAddress->Js.Nullable.fromOption,
                        roleId: guildData.roleId->Js.Nullable.fromOption,
                      }

                      {
                        user,
                        brightIdGuild: brightIdGuild->Js.Nullable.return,
                        isAdmin: isAdmin || isOwner,
                        guild,
                      }->resolve
                    },
                  )
                },
              )
            },
          )
        }
      }
    })
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
  let {brightIdGuild, isAdmin, guild} = useLoaderData()
  let {guildId} = useParams()
  let account = Wagmi.useAccount()

  let (state, dispatch) = React.useReducer(reducer, state)

  let roleId = switch brightIdGuild->Js.Nullable.toOption {
  | None => NoBrightIdData->raise
  | Some(brightIdGuild) =>
    switch brightIdGuild.roleId->Js.Nullable.toOption {
    | None => ""
    | Some(roleId) => roleId
    }
  }

  let sign = switch guild->Js.Nullable.toOption {
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

  switch isAdmin {
  | false =>
    <div className="flex flex-1">
      <header className="flex flex-row justify-between md:justify-end m-4">
        <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
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
    switch guild->Js.Nullable.toOption {
    | None =>
      <div className="flex justify-center items-center text-white text-3xl font-bold">
        <div> {"This server does not exist"->React.string} </div>
      </div>
    | Some(guild) =>
      <div className="flex-1 p-4">
        <ReactHotToast.Toaster />
        <div className="flex flex-col flex-1 h-full">
          <header className="flex flex-row justify-between m-4">
            <div className="flex flex-col md:flex-row gap-3">
              <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
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
            </div>
            <div
              className="flex flex-1 justify-around flex-col md:flex-row items-center md:items-start">
              <img className="w-48 h-48 p-5" src={guild->Helpers_Guild.iconUri} />
              {switch brightIdGuild->Js.Nullable.toOption {
              | None =>
                <div className="text-white text-2xl font-semibold justify-center items-center">
                  <div> {"This server is not using BrightID"->React.string} </div>
                </div>
              | Some(brightIdGuild) =>
                <div className="flex flex-col flex-1 justify-center items-start gap-4">
                  <label className="flex flex-col gap-2">
                    {"Role"->React.string}
                    <input
                      className="text-white p-2 rounded bg-extraDark"
                      type_="text"
                      name="role"
                      placeholder={brightIdGuild.role
                      ->Js.Nullable.toOption
                      ->Belt.Option.getWithDefault("No Role Name")}
                      value={state.role->Belt.Option.getWithDefault("")}
                      onChange={onRoleChanged}
                    />
                  </label>
                  <label className="flex flex-col gap-2">
                    {"Invite"->React.string}
                    <input
                      className="text-white p-2 bg-extraDark outline-none"
                      name="inviteLink"
                      type_="text"
                      placeholder={brightIdGuild.inviteLink
                      ->Js.Nullable.toOption
                      ->Belt.Option.getWithDefault("No Invite Link")}
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
                        ->Js.Nullable.toOption
                        ->Belt.Option.getWithDefault("No Sponsorship Address")
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
