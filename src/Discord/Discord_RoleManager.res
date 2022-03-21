exception CreateRoleError(string)

type t
type roleManager = {t: t, cache: array<Discord_Role.role>}
type reason = Reason(string)
// @TODO: Color resolvable is missing most of its fields. String works in this case
type colorResolvable = String(string)
// RGB(int, int, int) | Hex(string)

// @TODO: These types and their values should be optional
type roleData = {name: Discord_Role.roleName, color: colorResolvable}
type makeRoleOptions = {data: roleData, reason: reason}

@send
external createGuildRole: (t, ~options: 'options=?) => Js.Promise.t<Discord_Role.t> = "create"
//@TODO: use the correct return type for a collection
@get external getCache: t => 'a = "cache"

let validateColor = color => {
  switch color {
  // | RGB(r, g, b) => [r, g, b]
  // | Hex(hex) => hex
  | String(color) => color
  }
}

let validateReason = reason =>
  switch reason {
  | Reason(reason) => reason
  }

// @TODO: options should be an optional type
// @TODO: The data and reason fields should be optional
// as well as the name and color fields
let makeGuildRole = (roleManager, options) => {
  let name = options.data.name->Discord_Role.validateRoleName
  let color = options.data.color->validateColor
  let reason = options.reason->validateReason
  let data = {"name": name, "color": color}
  roleManager->createGuildRole(~options={"data": data, "reason": reason})
}

let make = roleManager => {
  let cache = roleManager->getCache
  // ->Belt.Map.String.map(Discord_Role.make)
  {t: roleManager, cache: cache}
}
