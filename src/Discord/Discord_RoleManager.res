exception CreateRoleError(string)

type t
type roleManager = {
  t: t,
  cache: Belt.Map.t<
    Discord_Snowflake.snowflake,
    Discord_Role.role,
    Discord_Snowflake.SnowflakeCompare.identity,
  >,
}

type makeRoleOptions = {data: Discord_Role.roleData, reason: Discord_Role.reason}

@send
external createGuildRole: (t, ~options: 'options=?) => Js.Promise.t<Discord_Role.t> = "create"
//@TODO: use the correct return type for a collection
@get external getCache: t => Discord_Collection.t<string, Discord_Role.t> = "cache"

// @TODO: options should be an optional type
// @TODO: The data and reason fields should be optional
// as well as the name and color fields
let makeGuildRole = (roleManager, options) => {
  let name = options.data.name->Discord_Role.validateRoleName
  let color = options.data.color->Discord_Role.validateColor
  let reason = options.reason->Discord_Role.validateReason
  let data = {"name": name, "color": color}
  roleManager->createGuildRole(~options={"data": data, "reason": reason})
}

let make = roleManager => {
  let cache = roleManager->getCache
  let keys =
    cache->Discord_Collection.keyArray->Belt.Array.map(key => Discord_Snowflake.Snowflake(key))
  let values = cache->Discord_Collection.array->Belt.Array.map(Discord_Role.make)
  let cache =
    Belt.Array.zip(keys, values)->Belt.Map.fromArray(~id=module(Discord_Snowflake.SnowflakeCompare))

  {t: roleManager, cache: cache}
}
