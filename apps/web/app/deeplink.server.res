// let uuidNamespace = Remix.process["env"]["UUID_NAMESPACE"]

// module UUID = {
//   type t = string
//   type name = UUIDName(string)
//   @module("uuid") external v5: (string, string) => t = "v5"
// }

// module BrightID = {
//   @module("brightid_sdk")
//   external generateDeepLink: (
//     ~context: string,
//     ~contextId: string,
//     ~nodeUrl: string=?,
//     unit,
//   ) => string = "generateDeepLink"
// }

// let context = "Discord"

// let discordDeepLink = discordId => {
//   let contextId = UUID.v5(uuidNamespace, discordId)
//   BrightID.generateDeepLink(~context, ~contextId, ())
// }

