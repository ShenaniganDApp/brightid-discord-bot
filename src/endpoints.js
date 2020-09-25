const { CONTEXT_ID } = require('./constants')

// BrightId endpoints
const NODE_URL = 'http:%2f%2fnode.brightid.org'

const BRIGHT_ID_ENDPOINT_V5 = 'https://app.brightid.org/node/v5'
const BRIGHTID_VERIFICATION_ENDPOINT = `${BRIGHT_ID_ENDPOINT_V5}/verifications`
const BRIGHTID_SUBSCRIPTION_ENDPOINT = `${BRIGHT_ID_ENDPOINT_V5}/operations`
const BRIGHTID_LINK_VERIFICATION_ENDPOINT = "https://app.brightid.org/link-verification/"
const BRIGHT_ID_APP_DEEPLINK = `https://app.brightid.org/link-verification/${NODE_URL}/${CONTEXT_ID}`
const 
module.exports = {
  NODE_URL,
  BRIGHT_ID_ENDPOINT_V5,
  BRIGHTID_VERIFICATION_ENDPOINT,
  BRIGHTID_SUBSCRIPTION_ENDPOINT,
  BRIGHT_ID_APP_DEEPLINK,
  BRIGHTID_LINK_VERIFICATION_ENDPOINT
}
