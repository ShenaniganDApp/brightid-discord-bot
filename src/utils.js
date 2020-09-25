// NOTE: As this is a "server bot",
// we don't avoid logging on production, as users will be able
// to see logs from their individual heroku instances
function error(...args) {
  console.error(`${Date.now()}:`, ...args)
}
function log(...args) {
  console.log(`${Date.now()}:`, ...args)
}

const Warned = new Map()
function warnOnce(domain, ...args) {
  if (!Warned.get(domain)) {
    Warned.set(domain, true)
    console.warn(`${Date.now()}:`, ...args)
  }
}

module.exports = { error, log, warnOnce }
