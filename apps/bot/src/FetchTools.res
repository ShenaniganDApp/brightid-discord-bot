open NodeFetch
@module("node-fetch")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "default"

type node = {
  url: string,
  priority?: int,
  timeout?: int,
}

exception NoRes

let rec fetchWithFallback = async (~relativeUrl, ~nodeIndex=0, defaultNode, fallbackNodes) => {
  let sortedNodes =
    nodeIndex > 0 ? fallbackNodes->Array.sort((a, b) => a.priority > b.priority ? 1 : -1) : []
  try {
    let node =
      sortedNodes->Array.get(nodeIndex)->Option.mapWithDefault(defaultNode, node => Some(node))
    switch node {
    | None => None
    | Some(node) =>
      let timeout = node.timeout->Option.getWithDefault(1000)
      let response = await fetch(
        `${node.url}${relativeUrl}`,
        {
          "timeout": timeout,
          "method": "GET",
          "headers": {"Content-Type": "application/json", "Accept": "application/json"},
        },
      )
      if response->Response.status === 404 {
        raise(NoRes)
      }

      Some(response)
    }
  } catch {
  | _ => await fetchWithFallback(~relativeUrl, ~nodeIndex=nodeIndex + 1, defaultNode, fallbackNodes)
  }
}
