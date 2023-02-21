@module("brightid_sdk")
external verifyContextId: (
  ~context: string,
  ~contextId: string,
  ~nodeUrl: string=?,
  unit,
) => promise<JSON.t> = "verifyContextId"

@module("brightid_sdk")
external generateDeeplink: (
  ~context: string,
  ~contextId: string,
  ~nodeUrl: string=?,
  unit,
) => string = "generateDeeplink"
