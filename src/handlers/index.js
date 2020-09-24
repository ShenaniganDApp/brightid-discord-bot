
const verifyHandler = require('./verify')


const handlers = new Map([
  ['verify', verifyHandler],
])

module.exports = handlers