open Constants
// BrightId endpoints
let nodeUrl = "http:%2f%2fnode.brightid.org"

let brightIdEndpointv5 = "https://app.brightid.org/node/v5"
let brightIdVerificationEndpoint = `${brightIdEndpointv5}/verifications`
let brightIdSubscriptionEndpoint = `${brightIdEndpointv5}/operations`
let brightIdAppDeeplink = `brightid://link-verification/${nodeUrl}/${contextId}`
let brightIdLinkVerificationEndpoint = `https://app.brightid.org/link-verification/${nodeUrl}/${contextId}`
