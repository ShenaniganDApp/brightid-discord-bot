let {context} = module(Constants)
// BrightId endpoints
let nodeUrl = "http:%2f%2fnode.brightid.org"

let brightIdEndpointv5 = "https://app.brightid.org/node/v5"
let brightIdVerificationEndpoint = `${brightIdEndpointv5}/verifications`
let brightIdSubscriptionEndpoint = `${brightIdEndpointv5}/operations`
let brightIdAppsEndpoint = `${brightIdEndpointv5}/apps`
let brightIdAppDeeplink = `brightid://link-verification/${nodeUrl}/${context}`
let brightIdLinkVerificationEndpoint = `https://app.brightid.org/link-verification/${nodeUrl}/${context}`
