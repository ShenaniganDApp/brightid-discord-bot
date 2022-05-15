class EnvironmentError extends Error {
  constructor(message) {
    super(`${Date.now()}: ${message}`)
    this.name = 'EnvironmentError'
  }
}

class RequestHandlerError extends Error {
  constructor(message) {
    super(`${Date.now()}: ${message}`)
    this.name = 'RequestHandlerError'
  }
}

class WhitelistedChannelError extends Error {
  constructor(message) {
    super(`${Date.now()}: ${message}`)
    this.name = 'WhitelistedChannelError'
  }
}

class QRCodeError extends Error {
  constructor(message) {
    super(`${Date.now()}: ${message}`)
    this.name = 'QRCodeError'
  }
}
class VerificationError extends Error {
  constructor(message) {
    super(`${Date.now()}: ${message}`)
    this.name = 'VerificationError'
  }
}

module.exports = {
  EnvironmentError,
  RequestHandlerError,
  WhitelistedChannelError,
  QRCodeError,
  VerificationError,
}
