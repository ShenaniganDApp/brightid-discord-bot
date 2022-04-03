type t = Types.roleT

@get external getName: t => string = "name"
@send
external _edit: (t, ~data: {"name": string}, ~reason: string=?) => Js.Promise.t<t> = "edit"

let validateRoleName = name =>
  switch name {
  | Types.RoleName(name) => name
  }

let validateColor = color => {
  switch color {
  // | RGB(r, g, b) => [r, g, b]
  // | Hex(hex) => hex
  | Types.String(color) => color
  }
}

let validateReason = reason =>
  switch reason {
  | Types.Reason(reason) => reason
  }

let edit = (role: Types.role, data: Types.roleData, reason) => {
  let name = data.name->validateRoleName
  let reason = reason->validateReason
  let data = {"name": name}
  role.t->_edit(~data, ~reason)
}
