@module("brightid_sdk")
external verifyContextId: (
  ~context: string,
  ~contextId: string,
  unit,
) => RescriptCore.Promise.t<Js.Json.t> = "verifyContextId"

@module("brightid_sdk")
external generateDeeplink: (~context: string, ~contextId: string, unit) => string =
  "generateDeeplink"
