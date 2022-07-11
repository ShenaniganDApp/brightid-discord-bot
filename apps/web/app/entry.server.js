// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Remix from "remix";
import * as ServerJs from "react-dom/server.js";

var ResponseInit = {};

function $$default(request, responseStatusCode, responseHeaders, remixContext) {
  var markup = ServerJs.renderToString(React.createElement(Remix.RemixServer, {
            context: remixContext,
            url: request.url
          }));
  responseHeaders.set("Content-Type", "text/html");
  return new Response("<!DOCTYPE html>" + markup, {
              status: responseStatusCode,
              headers: responseHeaders
            });
}

export {
  ResponseInit ,
  $$default ,
  $$default as default,
  
}
/* react Not a pure module */
