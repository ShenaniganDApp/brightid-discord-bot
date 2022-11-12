@module("brightid_sdk")
external verifyContextId: (
  ~context: string,
  ~contextId: string,
  ~nodeUrl: string=?,
  unit,
) => Js.Promise.t<Js.Json.t> = "verifyContextId"

@module("brightid_sdk")
external generateDeeplink: (
  ~context: string,
  ~contextId: string,
  ~nodeUrl: string=?,
  unit,
) => string = "generateDeeplink"
