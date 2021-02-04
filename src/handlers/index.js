const meHandler = require('./me')
const verifyHandler = require('./verify')
const guildsHandler = require('./guilds')
const inviteHandler = require('./invite')
const roleHandler = require('./role')

const handlers = new Map([
  ['!verify', verifyHandler],
  ['!me', meHandler],
  ['!guilds', guildsHandler],
  ['!invite', inviteHandler],
  ['!role', roleHandler],
])

module.exports = handlers
