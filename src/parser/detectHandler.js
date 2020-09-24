const { RequestHandlerError } = require('../error-utils')
const handlers = require('../handlers/index')

const noop = () => undefined

module.exports = function detectHandler(message) {
  // If it's not a flag, we can safely ignore this command.
  if (!message.includes('!')) {
    return noop()
  }
  const command = message.split("!")[1]
  const receivedHandler = handlers.get(command)
  if (message !== '!verify') {
    throw new RequestHandlerError(
      `Could not find command with flag ${requestedNamespace}`,
    )
  }

  if (typeof receivedHandler !== 'function') {
    throw new RequestHandlerError(
      `Could not find command with flag ${requestedHandler}`,
    )
  }

  return receivedHandler
}