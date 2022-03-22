type t
type roleName = RoleName(string)
type role = {t: t, name: roleName}

type reason = Reason(string)
// @TODO: Color resolvable is missing most of its fields. String works in this case
type colorResolvable = String(string)
// RGB(int, int, int) | Hex(string)

// @TODO: These types and their values should be optional
type roleData = {name: roleName, color: colorResolvable}

@get external getName: t => string = "name"
@send external _edit: (t, ~data: 'roleData, ~reason: string=?) => Js.Promise.t<t> = "edit"

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

let edit = (role, data, reason) => {
  let name = data.name->validateRoleName
  let reason = reason->validateReason
  let data = {"name": name}
  role.t->_edit(~data, ~reason)
}

let make = role => {
  let name = role->getName
  {t: role, name: RoleName(name)}
}
