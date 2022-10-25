module JsonRpcProvider = {
  type t
  @module("ethers") @new external make: (~url: string) => t = "JsonRpcProvider"
}

module Contract = {
  type t
  @module("ethers") @new
  external make: (~address: string, ~abi: Js.Json.t, ~provider: JsonRpcProvider.t) => t = "Contract"
}

module Utils = {
  @module("ethers") @scope("utils")
  external formatBytes32String: string => string = "formatBytes32String"

  @module("ethers") @scope("utils") external formatUnits: (int, int) => int = "formatUnits"
}
