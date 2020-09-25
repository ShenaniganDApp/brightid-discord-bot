const { verify } = require('tweetnacl')
const errors = require('../error-utils')
const handlers = require('../handlers/index')

const noop = () => undefined
const commmands = ['!verify', '!me']
module.exports = function detectHandler(message) {
  // If it's not a flag, we can safely ignore this command.
  if (!message.includes('!')) {
    return noop()
  }
  const command = message.split('!')[1]
  const receivedHandler = handlers.get(command)
  if (!commmands.includes(message)) {
    throw new errors.RequestHandlerError(
      `Could not find command with flag ${requestedNamespace}`,
    )
  }

  if (typeof receivedHandler !== 'function') {
    throw new errors.RequestHandlerError(
      `Could not find command with flag ${requestedHandler}`,
    )
  }

  return receivedHandler
}
