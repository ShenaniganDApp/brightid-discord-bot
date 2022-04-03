exception CreateRoleError(string)

type t = Types.roleManagerT

@send
external _create: (t, ~options: 'options=?) => Promise.t<Types.roleT> = "create"
//@TODO: use the correct return type for a collection
@get external getCache: t => Discord_Collection.t<string, Types.roleT> = "cache"
@get external getGuild: t => Types.guildT = "guild"

// @TODO: options should be an optional type
// @TODO: The data and reason fields should be optional
// as well as the name and color fields
let create = (roleManager, options: Types.createRoleOptions) => {
  let name = options.data.name->Discord_Role.validateRoleName
  let color = options.data.color->Discord_Role.validateColor
  let reason = options.reason->Discord_Role.validateReason
  let data = {"name": name, "color": color}
  roleManager->_create(~options={"data": data, "reason": reason})
}
