type t
type roleName = RoleName(string)
type role = {name: roleName}

@get external getName: 'role => string = "name"

let validateRoleName = name =>
  switch name {
  | RoleName(name) => name
  }

let make = role => {
  let name = role->getName
  {name: RoleName(name)}
}
