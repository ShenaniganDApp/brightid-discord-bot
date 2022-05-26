module ResponseInit = {
  type t

  external make: {..} => t = "%identity"
}

// TODO: Swap out for Webapi.Fetch.Response when it supports construction
// See https://github.com/tinymce/rescript-webapi/issues/63
@new
external makeResponse: (Webapi.Fetch.BodyInit.t, ResponseInit.t) => Webapi.Fetch.Response.t =
  "Response"

let default = (request, responseStatusCode, responseHeaders, remixContext) => {
  open Webapi

  let markup = ReactDOMServer.renderToString(
    <Remix.RemixServer context={remixContext} url={request->Fetch.Request.url} />,
  )

  responseHeaders->Fetch.Headers.set("Content-Type", "text/html")

  makeResponse(
    Fetch.BodyInit.make("<!DOCTYPE html>" ++ markup),
    ResponseInit.make({
      "status": responseStatusCode,
      "headers": responseHeaders,
    }),
  )
}
