module.exports = function parseWhitelistedChannels() {
  const channels = process.env.WHITELISTED_CHANNELS
  if (!channels) {
    return ['*']
  }

  return channels.split(',')
}
