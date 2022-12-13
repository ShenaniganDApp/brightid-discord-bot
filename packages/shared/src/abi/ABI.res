type abiField = {
      constant?: bool,
      inputs?: array<Js.Json.t>,
      name?: string,
      outputs?: array<Js.Json.t>,
      payable?: bool,
      stateMutability?: string,
      \"type"?: string
}
type t = array<abiField>