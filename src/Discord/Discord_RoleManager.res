exception CreateRoleError(string)

type role
type roleManager
type roleName = RoleName(string)
type reason = Reason(string)
// @TODO: Color resolvable is missing most of its fields. String works in this case
type colorResolvable = String(string)
// RGB(int, int, int) | Hex(string)

// @TODO: These types and their values should be optional
type roleData = {name: roleName, color: colorResolvable}
type makeRoleOptions = {data: roleData, reason: reason}

@send
external createGuildRole: ('roleManager, ~options: 'options=?) => Js.Promise.t<'role> = "create"

let validateRoleName = name =>
  switch name {
  | RoleName(name) => name
  }

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
  let name = options.data.name->validateRoleName
  let color = options.data.color->validateColor
  let reason = options.reason->validateReason
  let data = {"name": name, "color": color}
  roleManager->createGuildRole(~options={"data": data, "reason": reason})
}
