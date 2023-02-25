// exception NoAccountAddress(string)

// module Modal = {
//   @react.component @react.component
//   let make = (~children) => {
//     let (showModal, setShowModal) = React.useState(_ => true)

//     {
//       showModal
//         ? <>
//             <div
//               className="justify-center items-center flex overflow-x-hidden overflow-y-auto fixed inset-0 z-50 outline-none focus:outline-none flex-1">
//               <div className="relative w-auto my-6 max-w-3xl "> {children} </div>
//             </div>
//             <div
//               className="opacity-25 fixed inset-0 z-40 bg-black"
//               onClick={_ => setShowModal(_ => false)}
//             />
//           </>
//         : <> </>
//     }
//   }
// }

// module Lottie = {
//   @react.component @module("react-lottie")
//   external make: (
//     ~options: {
//       "animationData": JSON.t,
//       "loop": bool,
//       "autoplay": bool,
//       "rendererSettings": {"preserveAspectRatio": string},
//     },
//     ~style: 'a=?,
//     ~className: string=?,
//   ) => React.element = "default"
// }

// let {contractAddressID, contractAddressETH} = module(Shared.Constants)

// type params = {guildId: string}

// let abi: Shared.ABI.t = %raw(`require("~/../../packages/shared/src/abi/SP.json")`)

// // let loader = () => {()}

// // let action = () => {()}

// @react.component
// let default = () => {
//   let {guildId} = Remix.useParams()
//   let transition = Remix.useTransition()
//   let {address: maybeAddress} = Wagmi.useAccount()

//   let address = maybeAddress->Option.getWithDefault("")

//   let mainnetSP = Wagmi.useBalance({
//     "address": address,
//     "token": contractAddressETH,
//     "chainId": 1,
//   })

//   let idSP = Wagmi.useBalance({
//     "address": address,
//     "token": contractAddressID,
//     "chainId": 74,
//   })

//   let formattedMainnetSP = switch mainnetSP["status"] {
//   | #success => mainnetSP["data"]->Option.map(data => data["formatted"])->Option.getWithDefault("0")
//   | #loading => "Loading"
//   | #error => "Error"
//   | _ => "unknown"
//   }

//   let formattedIDSP = switch idSP["status"] {
//   | #success => idSP["data"]->Option.map(data => data["formatted"])->Option.getWithDefault("0")
//   | #loading => "Loading"
//   | #error => "Error"
//   | _ => "unknown"
//   }

//   let makeDefaultOptions = animationData =>
//     {
//       "loop": true,
//       "autoplay": true,
//       "animationData": animationData,
//       "rendererSettings": {
//         "preserveAspectRatio": "xMidYMid slice",
//       },
//     }

//   //TODO This is too slow to use if we navigate here directly
//   // let guildName = switch context["guilds"]->Array.findIndexOpt(guild => guild.id === guildId) {
//   // | None => ""
//   // | Some(index) =>
//   //   switch context["guilds"]->Array.get(index) {
//   //   | Some({name: Some(name)}) => name
//   //   | _ => ""
//   //   }
//   // }
//   <div className="flex flex-1 width-full height-full justify-center items-center">
//     {switch maybeAddress {
//     | None => <RainbowKit.ConnectButton />
//     | Some(_) =>
//       transition->Remix.Transition.state === "submitting"
//         ? <div>
//             <Lottie options={makeDefaultOptions(assignSPYellow)} style={{"width": "25vw"}} />
//             <p className="text-white font-bold text-24">
//               {React.string(`Assigning Sponsorships to Server`)}
//             </p>
//           </div>
//         : <Remix.Form className="flex flex-col width-full height-full">
//             <div className="flex justify-around p-10">
//               <label className="text-white font-bold text-32"> {"ID SP"->React.string} </label>
//               <p className="text-white font-bold text-24"> {React.string(`${formattedIDSP}`)} </p>
//               <label className="text-white font-bold text-32"> {"Mainnet SP"->React.string} </label>
//               <p className="text-white font-bold text-24">
//                 {React.string(`${formattedMainnetSP}`)}
//               </p>
//             </div>
//             <input
//               className="appearance-none text-white bg-transparent text-3xl text-center p-5"
//               type_="number"
//               name="sponsorships"
//               defaultValue="1"
//             />
//             <button className="text-white p-5" type_="submit"> {React.string("Assign")} </button>
//           </Remix.Form>
//     }}
//   </div>
// }

