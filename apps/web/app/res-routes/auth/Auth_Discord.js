// Generated by ReScript, PLEASE EDIT WITH CARE

import * as AuthServer from "../../AuthServer.js";
import * as $$Node from "@remix-run/node";

function loader(param) {
  return Promise.resolve($$Node.redirect("/"));
}

function action(param) {
  return AuthServer.authenticator.authenticate("discord", param.request);
}

export {
  loader ,
  action ,
}
/* AuthServer Not a pure module */
