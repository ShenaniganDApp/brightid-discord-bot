open Promise
//Client
@module("discord.js") @new external createDiscordClient: 'a => 'b = "Client"
type rec client = Client(client)
@send external on: ('a, 'b, 'c => unit) => unit = "on"
@send external login: ('a, string) => unit = "login"

// Snowflake
type snowflake = Snowflake(string)
let validateSnowflake = snowflake => {
  switch snowflake {
  | Snowflake(snowflake) => snowflake
  }
}

// Roles
exception CreateRoleError(string)

type role
type roleManager
type roleName = RoleName(string)
type reason = Reason(string)
// @TODO: Color resolvable is missing most of its fields. String works in this case
type colorResolvable = String(string)
// RGB(int, int, int) | Hex(string)

// @TODO: These types and their values should be optional
type roleData = RoleData({name: roleName, color: colorResolvable})
type createRoleOptions = CreateRoleOptions({data: roleData, reason: reason})

@send
external createGuildRole: ('roleManager, ~options: 'options=?) => Js.Promise.t<'role> = "create"

// @val @module(("discord.js", "Guild")) external guildId: 'a = ""
// Js.log(guildId)

type guildName = GuildName(string)

let validateGuildName = guildName => {
  switch guildName {
  | GuildName(guildName) => guildName
  }
}

type guild = Guild({id: snowflake, name: guildName})
@get external getGuildRoleManager: guild => roleManager = "roles"

let validateGuild = guild => {
  switch guild {
  | Guild(guild) => {
      let id = validateSnowflake(guild.id)
      let name = validateGuildName(guild.name)
      {"id": id, "name": name}
    }
  }
}

type event =
  | Ready(unit => unit)
  | GuildCreate(guild => unit)

let make = () => {
  let client = createDiscordClient()
  Client(client)
}

let onEvent = (client, event) => {
  switch client {
  | Client(client) =>
    switch event {
    | Ready(callback) => client->on("ready", callback)
    | GuildCreate(callback) => client->on("guildCreate", callback)
    }
  }
}

let loginClient = (client, token) => {
  switch client {
  | Client(client) =>
    switch token {
    | Env.DiscordToken(token) => login(client, token)
    }
  }
}

let validateOptions = options => {
  switch options {
  | CreateRoleOptions({data: roleData, reason}) => {"data": roleData, "reason": reason}
  }
}

let validateName = name =>
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

let validateRoleData = data =>
  switch data {
  | RoleData(data) => {
      let name = validateName(data.name)
      let color = validateColor(data.color)
      {"name": name, "color": color}
    }
  }

let validateReason = reason =>
  switch reason {
  | Reason(reason) => reason
  }

// @TODO: options should be an optional type
// @TODO: The data and reason fields should be optional
// as well as the name and color fields
let createGuildRoleClient = (roleManager, options) => {
  let options = options->validateOptions
  let data = options["data"]->validateRoleData
  let reason = options["reason"]->validateReason
  let createOptions = {"data": {"name": data["name"], "color": data["color"]}, "reason": reason}
  roleManager->createGuildRole(~options=createOptions)
}
