open NodeFetch
@module("node-fetch")
external fetch: (string, 'params) => promise<Response.t<JSON.t>> = "default"

type node = {
  url: string,
  priority?: int,
  timeout?: int,
}

exception NoRes
exception HttpError(int)

let fetchWithFallback = async (~relativeUrl, defaultNode, fallbackNodes) => {
  let nodes = switch defaultNode {
  | None => fallbackNodes
  | Some(node) => [node, ...fallbackNodes->Array.filter(other => other.url !== node.url)]
  }
  let rec attempt = async index => {
    switch nodes->Array.get(index) {
    | None => raise(NoRes)
    | Some(node) =>
      try {
        let timeout = node.timeout->Option.getOr(10000)
        let response = await fetch(
          `${node.url}${relativeUrl}`,
          {
            "timeout": timeout,
            "method": "GET",
            "headers": {"Content-Type": "application/json", "Accept": "application/json"},
          },
        )
        let status = response->Response.status
        if status >= 500 || status === 429 {
          raise(HttpError(status))
        }

        Some(response)
      } catch {
      | _ => await attempt(index + 1)
      }
    }
  }
  await attempt(0)
}

let decodeResponse = (json, decoder) => {
  switch Json.decode(json, Shared.Decode.Decode_BrightId.Error.data) {
  | Ok(error) if error.error && (error.code >= 500 || error.code === 429) =>
    raise(HttpError(error.code))
  | Ok(error) if error.error => raise(Exceptions.BrightIdError(error))
  | _ =>
    switch Json.decode(json, decoder) {
    | Ok(data) => data
    | Error(error) => raise(Json.Decode.DecodeError(error))
    }
  }
}

let fetchJson = async (~relativeUrl, nodes) => {
  let response = switch await fetchWithFallback(~relativeUrl, nodes->Array.get(0), nodes) {
  | None => raise(NoRes)
  | Some(response) => response
  }
  let json = await Response.json(response)
  let status = response->Response.status
  if status >= 400 {
    switch Json.decode(json, Shared.Decode.Decode_BrightId.Error.data) {
    | Ok(error) if error.error && error.code === status => raise(Exceptions.BrightIdError(error))
    | _ => raise(HttpError(status))
    }
  }
  json
}
