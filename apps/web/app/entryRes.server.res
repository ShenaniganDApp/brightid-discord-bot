module ResponseInit = {
  type t

  external make: {..} => t = "%identity"
}

module BodyInit = {
  open Webapi.Fetch
  external makeWithPipeapleStream: NodeJs.Stream.PassThrough.t<
    NodeJs.Buffer.t,
    NodeJs.Buffer.t,
  > => BodyInit.t = "%identity"
}

@module("isbot") external isbot: string => bool = "default"

module ReactDOMServer = {
  type pipe = NodeJs.Stream.PassThrough.t<
    NodeJs.Buffer.t,
    NodeJs.Buffer.t,
  > => NodeJs.Stream.writable<NodeJs.Buffer.t>
  type abort = unit => unit

  type pipeableStream = {
    abort: abort,
    pipe: pipe,
  }

  @get external pipe: pipeableStream => pipe = "pipe"
  @get external abort: pipeableStream => abort = "abort"

  @module("react-dom/server")
  external renderToPipeableStream: (React.element, 'options) => pipeableStream =
    "renderToPipeableStream"
}

// TODO: Swap out for Webapi.Fetch.Response when it supports construction
// See https://github.com/tinymce/rescript-webapi/issues/63
@new
external makeResponse: (Webapi.Fetch.BodyInit.t, ResponseInit.t) => Webapi.Fetch.Response.t =
  "Response"

type onAllReady = {
  onAllReady: unit => unit,
  onShellError: exn => unit,
  onError: exn => unit,
}
type onShellReady = {
  onShellReady: unit => unit,
  onShellError: exn => unit,
  onError: exn => unit,
}
type ready = AllReady(onAllReady) | ShellReady(onShellReady)

@live
let default = (request, responseStatusCode, responseHeaders, remixContext) => {
  open Webapi
  let abortDelay = 5000

  let maybeCallbackName =
    request
    ->Fetch.Request.headers
    ->Fetch.Headers.get("User-Agent")
    ->Belt.Option.map(isbot)
    ->Belt.Option.map(onAllReady => onAllReady ? "onAllReady" : "onShellReady")

  Promise.make((resolve, reject) => {
    let onAllReadyOptions = pipe => {
      let callbackFn = () => {
        let body = NodeJs.Stream.PassThrough.make()

        request->Fetch.Request.headers->Fetch.Headers.set("Content-Type", "text/html")

        let response = BodyInit.makeWithPipeapleStream(body)->makeResponse(
          ResponseInit.make({
            "status": responseStatusCode,
            "headers": responseHeaders,
          }),
        )

        resolve(. response)
        pipe(body)->ignore
      }
      {
        onAllReady: callbackFn,
        onShellError: err => reject(. err),
        onError: err => Js.Console.error(err),
      }
    }
    let onShellReadyOptions = pipe => {
      let callbackFn = () => {
        let body = NodeJs.Stream.PassThrough.make()

        request->Fetch.Request.headers->Fetch.Headers.set("Content-Type", "text/html")

        let response = BodyInit.makeWithPipeapleStream(body)->makeResponse(
          ResponseInit.make({
            "status": responseStatusCode,
            "headers": responseHeaders,
          }),
        )

        resolve(. response)
        pipe(body)->ignore
      }
      {
        onShellReady: callbackFn,
        onShellError: err => reject(. err),
        onError: err => Js.Console.error(err),
      }
    }

    // This is hacky because we can't access the return in params in rescript
    open ReactDOMServer
    if maybeCallbackName->Belt.Option.getWithDefault("") === "onAllReady" {
      let allStream = renderToPipeableStream(
        <Remix.RemixServer context={remixContext} url={request->Fetch.Request.url} />,
        onAllReadyOptions(%raw(`allStream`)->pipe),
      )
      let _ = NodeJs.Timers.setTimeout(allStream.abort, abortDelay)
    } else if maybeCallbackName->Belt.Option.getWithDefault("") === "onShellReady" {
      let {abort, pipe} = renderToPipeableStream(
        <Remix.RemixServer context={remixContext} url={request->Fetch.Request.url} />,
        onShellReadyOptions(%raw(`pipe`)),
      )

      let _ = NodeJs.Timers.setTimeout(abort, abortDelay)
    }
  })
}
