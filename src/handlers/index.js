const meHandler = require('./me')
const verifyHandler = require('./verify')

const handlers = new Map([
  ['verify', verifyHandler],
  ['me', meHandler],
])

module.exports = handlers
