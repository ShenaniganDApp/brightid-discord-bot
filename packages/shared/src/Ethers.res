module JsonRpcProvider = {
  type t
}
module Providers = {
  type t
  @new @module("ethers") @scope("providers")
  external jsonRpcProvider: (~url: string) => JsonRpcProvider.t = "JsonRpcProvider"
}

module Contract = {
  type t
  @module("ethers") @new
  external make: (~address: string, ~abi: ABI.t, ~provider: JsonRpcProvider.t) => t = "Contract"
}

module Utils = {
  @module("ethers") @scope("utils")
  external formatBytes32String: string => string = "formatBytes32String"

  @module("ethers") @scope("utils") external formatUnits: (int, int) => int = "formatUnits"
}

module BigNumber = {
  type t

  @module("ethers") @scope("BigNumber")
  external fromString: string => t = "from"
  @val @module("ethers") @scope("constants") external zero: t = "Zero"

  @send external toString: t => string = "toString"

  @send external toFloat: t => float = "toNumber"
  @send external isZero: t => bool = "isZero"
  @send external add: (t, t) => t = "add"
  @send external sub: (t, t) => t = "sub"
  @send external addWithString: (t, string) => t = "add"
  @send external subWithString: (t, string) => t = "sub"
  @send external addWithFloat: (t, float) => t = "add"
  @send external subWithFloat: (t, float) => t = "sub"

  @send external gt: (t, t) => bool = "gt"
  @send external gtWithString: (t, string) => bool = "gt"
  @send external lte: (t, t) => bool = "lte"
}
