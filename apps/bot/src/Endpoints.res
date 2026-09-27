let {context} = module(Constants)
// BrightId endpoints
let nodeUrl = "https:%2f%2faura-node.brightid.org"

let brightIdEndpointv5 = "https://aura-node.brightid.org/brightid/v5"
let brightIdVerificationEndpoint = `${brightIdEndpointv5}/verifications`
let brightIdSubscriptionEndpoint = `${brightIdEndpointv5}/operations`
let brightIdAppsEndpoint = `${brightIdEndpointv5}/apps`
let brightIdAppDeeplink = `brightid://link-verification/${nodeUrl}/${context}`
let brightIdLinkVerificationEndpoint = `https://app.brightid.org/link-verification/${nodeUrl}/${context}`

let nodeUrls = ["https://aura-node.brightid.org/brightid/v5", "https://app.brightid.org/node/v5"]
let nodes = {
  open FetchTools
  nodeUrls->Array.mapWithIndex((url, i) => {
    url,
    priority: i,
    timeout: 10000,
  })
}
