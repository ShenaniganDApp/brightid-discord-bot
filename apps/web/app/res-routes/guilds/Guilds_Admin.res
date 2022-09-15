// exception NoBrightIdData

// type params = {guildId: string}

// type loaderData = {
//   user: Js.Nullable.t<RemixAuth.User.t>,
//   brightIdGuild: Js.Nullable.t<Types.brightIdGuildData>,
//   guild: Js.Nullable.t<Types.guild>,
//   isAdmin: bool,
// }

// let loader: Remix.loaderFunction<Js.Nullable.t<unit>> = ({request, params}) => {
//   open Json.Decode
//   open DiscordServer
//   open Promise
//   open Utils

//   let brightIdGuild = object(field =>
//     {
//       "role": field.optional(. "role", string),
//       "name": field.optional(. "name", string),
//       "inviteLink": field.optional(. "inviteLink", string),
//       "roleId": field.optional(. "roleId", string),
//     }
//   )

//   let brightIdGuilds = brightIdGuild->dict

//   // @TODO: this relies on node-fetch. Can't use it in remix
//   let config = Gist.makeGistConfig(
//     ~id=Remix.process["env"]["GIST_ID"],
//     ~name="guildData.json",
//     ~token=Remix.process["env"]["GITHUB_ACCESS_TOKEN"],
//   )

//   let guildId = params->Js.Dict.get("guildId")->Belt.Option.getWithDefault("")

//   AuthServer.authenticator
//   ->RemixAuth.Authenticator.isAuthenticated(request)
//   ->then(user => {
//     Gist.ReadGist.content(~config, ~decoder=brightIdGuilds)->then(guilds => {
//       resolve()
//       switch user->Js.Nullable.toOption {
//       | None =>
//         {
//           user: Js.Nullable.null,
//           brightIdGuild: Js.Nullable.null,
//           isAdmin: false,
//           guild: Js.Nullable.null,
//         }->resolve
//       | Some(existingUser) => {
//           let guildData = guilds->Js.Dict.get(guildId)->Belt.Option.getExn
//           fetchGuildFromId(~guildId)->then(
//             guild => {
//               let userId = existingUser->RemixAuth.User.getProfile->RemixAuth.User.getId
//               fetchGuildMemberFromId(~guildId, ~userId)->then(
//                 guildMember => {
//                   let memberRoles = switch guildMember->Js.Nullable.toOption {
//                   | None => []
//                   | Some(guildMember) => guildMember.roles
//                   }
//                   fetchGuildRoles(~guildId)->then(
//                     guildRoles => {
//                       let isAdmin = memberIsAdmin(~guildRoles, ~memberRoles)
//                       let isOwner = switch guild->Js.Nullable.toOption {
//                       | None => false
//                       | Some(guild) => guild.owner_id === userId
//                       }

//                       //@TODO: This should use the decoder type
//                       let brightIdGuild: Types.brightIdGuildData = {
//                         name: guildData["name"]->Js.Nullable.fromOption,
//                         role: guildData["role"]->Js.Nullable.fromOption,
//                         inviteLink: guildData["inviteLink"]->Js.Nullable.fromOption,
//                         sponsorshipAddress: Js.Nullable.null,
//                         roleId: guildData["roleId"]->Js.Nullable.fromOption,
//                       }

//                       {
//                         user,
//                         brightIdGuild: brightIdGuild->Js.Nullable.return,
//                         isAdmin: isAdmin || isOwner,
//                         guild,
//                       }->resolve
//                     },
//                   )
//                 },
//               )
//             },
//           )
//         }
//       }
//     })
//   })
// }

// type state = {
//   role: option<string>,
//   inviteLink: option<string>,
//   sponsorshipAddress: option<string>,
// }

// let state = {
//   role: None,
//   inviteLink: None,
//   sponsorshipAddress: None,
// }

// type actions =
//   | RoleChanged(option<string>)
//   | InviteLinkChanged(option<string>)
//   | SponsorshipAddressChanged(option<string>)

// let reducer = (state, action) =>
//   switch action {
//   | RoleChanged(role) => {...state, role}
//   | InviteLinkChanged(inviteLink) => {...state, inviteLink}
//   | SponsorshipAddressChanged(sponsorshipAddress) => {
//       ...state,
//       sponsorshipAddress,
//     }
//   }

// @react.component
// let default = () => {
//   open Remix
//   let context = useOutletContext()
//   let {user, brightIdGuild, isAdmin, guild} = useLoaderData()
//   let {guildId} = useParams()

//   let state = switch brightIdGuild->Js.Nullable.toOption {
//   | None => NoBrightIdData->raise
//   | Some(brightIdGuild) => {
//       role: brightIdGuild.role->Js.Nullable.toOption,
//       inviteLink: brightIdGuild.inviteLink->Js.Nullable.toOption,
//       sponsorshipAddress: brightIdGuild.sponsorshipAddress->Js.Nullable.toOption,
//     }
//   }

//   let (state, dispatch) = React.useReducer(reducer, state)

//   let reset = _ =>
//     switch brightIdGuild->Js.Nullable.toOption {
//     | None => NoBrightIdData->raise
//     | Some(brightIdGuild) => {
//         brightIdGuild.role->Js.Nullable.toOption->RoleChanged->dispatch
//         brightIdGuild.inviteLink->Js.Nullable.toOption->InviteLinkChanged->dispatch
//         brightIdGuild.sponsorshipAddress->Js.Nullable.toOption->SponsorshipAddressChanged->dispatch
//       }
//     }

//   let onRoleChanged = e => {
//     let value = ReactEvent.Form.currentTarget(e)["value"]->Js.Nullable.return

//     value->Js.Nullable.toOption->RoleChanged->dispatch
//   }
//   let onInviteLinkChanged = e => {
//     let value = ReactEvent.Form.currentTarget(e)["value"]->Js.Nullable.return
//     value->Js.Nullable.toOption->InviteLinkChanged->dispatch
//   }

//   // let onSubmit = e => {

//   // }

//   let hasChangesToSave = switch brightIdGuild->Js.Nullable.toOption {
//   | None => false
//   | Some(brightIdGuild) => {
//       let defaultState = {
//         role: brightIdGuild.role->Js.Nullable.toOption,
//         inviteLink: brightIdGuild.inviteLink->Js.Nullable.toOption,
//         sponsorshipAddress: brightIdGuild.sponsorshipAddress->Js.Nullable.toOption,
//       }
//       defaultState != state
//     }
//   }

//   switch isAdmin {
//   | false =>
//     <div className="flex flex-1">
//       <header className="flex flex-row justify-between md:justify-end m-4">
//         <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
//         <Link
//           className="p-4 bg-brightid font-semibold rounded-3xl text-xl text-white"
//           to={`/guilds/${guildId}`}>
//           {`⬅️ Go Back`->React.string}
//         </Link>
//       </header>
//       <div className="flex justify-center items-center text-white text-3xl font-bold">
//         <div> {"You are not an admin in this server"->React.string} </div>
//       </div>
//     </div>
//   | true =>
//     switch guild->Js.Nullable.toOption {
//     | None =>
//       <div className="flex justify-center items-center text-white text-3xl font-bold">
//         <div> {"This server does not exist"->React.string} </div>
//       </div>
//     | Some(guild) =>
//       <div className="flex-1 p-4">
//         <ReactHotToast.Toaster />
//         <div className="flex flex-col flex-1 h-full">
//           <header className="flex flex-row justify-between md:justify-end m-4">
//             <SidebarToggle handleToggleSidebar={context["handleToggleSidebar"]} />
//             <Link
//               className="p-4 bg-brightid font-semibold rounded-3xl text-xl text-white"
//               to={`/guilds/${guildId}`}>
//               {`⬅️ Go Back`->React.string}
//             </Link>
//           </header>
//           <Remix.Form
//             method={#post}
//             action={`/guilds/${guildId}/adminSubmit`}
//             className="flex-1 text-white text-2xl font-semibold justify-center items-center relative">
//             <div>
//               <div> {"Admin Commands"->React.string} </div>
//             </div>
//             <div className="flex flex-1">
//               <img className="w-48 h-48 p-5" src={guild->Helpers_Guild.iconUri} />
//               {switch brightIdGuild->Js.Nullable.toOption {
//               | None =>
//                 <div className="text-white text-2xl font-semibold justify-center items-center">
//                   <div> {"This server is not using BrightID"->React.string} </div>
//                 </div>
//               | Some(brightIdGuild) =>
//                 <div className="flex flex-col flex-1 justify-center items-center gap-4">
//                   <label className="flex flex-col gap-2">
//                     {"Role"->React.string}
//                     <input
//                       className="text-white p-2 rounded bg-extraDark"
//                       type_="text"
//                       name="role"
//                       placeholder="No Role Name"
//                       value={state.role->Belt.Option.getWithDefault(
//                         brightIdGuild.role->Js.Nullable.toOption->Belt.Option.getWithDefault(""),
//                       )}
//                       onChange={onRoleChanged}
//                     />
//                   </label>
//                   <label className="flex flex-col gap-2">
//                     {"Invite"->React.string}
//                     <input
//                       className="text-white p-2 bg-extraDark"
//                       name="inviteLink"
//                       type_="text"
//                       placeholder="No Invite Link"
//                       value={state.inviteLink->Belt.Option.getWithDefault(
//                         brightIdGuild.inviteLink
//                         ->Js.Nullable.toOption
//                         ->Belt.Option.getWithDefault(""),
//                       )}
//                       onChange=onInviteLinkChanged
//                     />
//                   </label>
//                   // <label className="flex flex-col">
//                   //   {"Sponsorship Address"->React.string} <input name="sponsorship" type_=#text />
//                   // </label>
//                 </div>
//               }}
//             </div>
//             <SubmitPopup hasChangesToSave reset />
//           </Remix.Form>
//         </div>
//       </div>
//     }
//   }
// }

