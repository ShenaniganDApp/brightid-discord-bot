open Webapi
open Promise

let envConfig = Remix.process["env"]

let githubAccessToken = envConfig["githubAccessToken"]

module GithubGist = {
  type t = {files: Js.Dict.t<{"content": string}>}
}

module Decode = {
  open GithubGist
  open Json.Decode

  let content = field =>
    {
      "content": field.required(. "content", string),
    }

  let files = field => {
    files: content->object->dict->field.required(. "files", _),
  }

  let gist = files->object
}

type gistConfig = {
  id: string,
  name: string,
  token: string,
}

let makeGistConfig = (~id, ~name, ~token) => {
  id,
  name,
  token,
}
module ReadGist = {
  let content = (~config, ~decoder) => {
    let {id, name, token} = config

    let init = Fetch.RequestInit.make(
      ~method_=Get,
      ~headers=Fetch.HeadersInit.make({
        "Authorization": `token ${token}`,
      }),
      (),
    )

    `https://api.github.com/gists/${id}`
    ->Fetch.fetchWithInit(init)
    ->then(res => res->Fetch.Response.json)
    ->then(data =>
      switch data->Json.decode(Decode.gist) {
      | Ok(gist) => {
          let json = gist.files->Js.Dict.get(name)->Belt.Option.getExn
          let content = json["content"]->Json.parseExn->Json.decode(decoder)
          switch content {
          | Ok(content) => content->resolve

          | Error(err) => err->Json.Decode.DecodeError->raise
          }
        }

      | Error(err) => err->Json.Decode.DecodeError->reject
      }
    )
  }
}

module UpdateGist = {
  exception UpdateGistError(exn)
  exception DuplicateKey(string)

  let updateEntry = (~content, ~key, ~entry, ~config) => {
    let {id, name, token} = config
    content->Js.Dict.set(key, entry)
    let content = content->Js.Json.stringifyAny
    let files = Js.Dict.empty()
    files->Js.Dict.set(name, {"content": content})
    let body = {
      "gist_id": id,
      "description": `Update gist entry with key: ${key}`,
      "files": files,
    }

    let init = Fetch.RequestInit.make(
      ~method_=Patch,
      ~body=Fetch.BodyInit.make(body->Js.Json.stringifyAny->Belt.Option.getExn),
      ~headers=Fetch.HeadersInit.make({
        "Authorization": `token ${token}`,
        "Accept": "application/vnd.github+json",
      }),
      (),
    )

    `https://api.github.com/gists/${id}`
    ->Fetch.fetchWithInit(init)
    ->then(res => {
      switch res->Fetch.Response.status {
      | 200 => Ok(200)->resolve
      | status => {
          res
          ->Fetch.Response.json
          ->then(json => {
            Js.log2(status, json->Json.stringify)
            resolve()
          })
          ->ignore
          Error(#Patch_Error)->resolve
        }
      }
    })
    ->catch(e => {
      Js.log2("e: ", e)
      resolve(Error(#Unkown_Error))
    })
  }

  let removeEntry = (~content, ~key, ~config) => {
    let {id, name, token} = config
    let entries = content->Js.Dict.entries->Belt.Array.keep(((k, _)) => key !== k)
    let content = entries->Js.Dict.fromArray->Js.Json.stringifyAny
    let files = Js.Dict.empty()
    files->Js.Dict.set(name, {"content": content})
    let body = {
      "gist_id": id,
      "description": `Remove entry with id : ${key}`,
      "files": files,
    }

    let init = Fetch.RequestInit.make(
      ~method_=Patch,
      ~body=Fetch.BodyInit.make(body->Js.Json.stringifyAny->Belt.Option.getExn),
      ~headers=Fetch.HeadersInit.make({
        "Authorization": `token ${token}`,
        "Accept": "application/vnd.github+json",
      }),
      (),
    )

    `https://api.github.com/gists/${id}`
    ->Fetch.fetchWithInit(init)
    ->then(res => {
      switch res->Fetch.Response.status {
      | 200 => Ok(200)->resolve
      | status => {
          res
          ->Fetch.Response.json
          ->then(json => {
            Js.log2(status, json->Json.stringify)
            resolve()
          })
          ->ignore
          Error(#Patch_Error)->resolve
        }
      }
    })
    ->catch(e => {
      Js.log2("e: ", e)
      resolve(Error(#Unknown_Error))
    })
  }

  // let removeManyEntries = (~content, ~keys, ~config) => {
  //   exception NoKeysMatch
  //   let {id, name, token} = config
  //   let entries =
  //     content->Js.Dict.entries->Belt.Array.keep(((k, _)) => !Belt.Set.String.has(keys, k))
  //   switch entries->Belt.Array.length {
  //   | 0 => NoKeysMatch->UpdateGistError->Error->resolve
  //   | _ =>
  //     let content = entries->Js.Dict.fromArray->Js.Json.stringifyAny
  //     let files = Js.Dict.empty()
  //     files->Js.Dict.set(name, {"content": content})
  //     let size = keys->Belt.Set.String.size
  //     let body = {
  //       "gist_id": id,
  //       "description": j`Removed  $size entries`,
  //       "files": files,
  //     }

  //     let init = Fetch.RequestInit.make(
  //       ~method_=Patch,
  //       ~body=Fetch.BodyInit.make(body->Js.Json.stringifyAny->Belt.Option.getExn),
  //       ~headers=Fetch.HeadersInit.make({
  //         "Authorization": `token ${token}`,
  //         "Accept": "application/vnd.github+json",
  //       }),
  //       (),
  //     )

  //     `https://api.github.com/gists/${id}`
  //     ->Fetch.fetchWithInit(init)
  //     ->then(res => {
  //       switch res->Fetch.Response.status {
  //       | 200 => Ok(200)->resolve
  //       | status => {
  //           res
  //           ->Fetch.Response.json
  //           ->then(json => {
  //             Js.log2(status, json->Json.stringify)
  //             Ok(status)->resolve
  //           })
  //           ->ignore
  //           Error(#Patch_Error)->resolve
  //         }
  //       }
  //     })
  //     ->catch(e => {
  //       Js.log2("e: ", e)
  //       Error(#Unknown_Error)->resolve
  //     })
  //   }
  // }

  let updateAllEntries = (~content, ~entries, ~config) => {
    let {id, name, token} = config

    let entries = entries->Js.Dict.fromList
    let keys = entries->Js.Dict.keys
    keys->Belt.Array.forEach(key => {
      let entry = entries->Js.Dict.get(key)->Belt.Option.getExn
      content->Js.Dict.set(key, entry)
    })
    let content = content->Js.Json.stringifyAny
    let files = Js.Dict.empty()
    files->Js.Dict.set(name, {"content": content})
    let body = {
      "gist_id": id,
      "description": "Update gist",
      "files": files,
    }

    let init = Fetch.RequestInit.make(
      ~method_=Patch,
      ~body=Fetch.BodyInit.make(body->Js.Json.stringifyAny->Belt.Option.getExn),
      ~headers=Fetch.HeadersInit.make({
        "Authorization": `token ${token}`,
        "Accept": "application/vnd.github+json",
      }),
      (),
    )

    `https://api.github.com/gists/${id}`
    ->Fetch.fetchWithInit(init)
    ->then(res => {
      switch res->Fetch.Response.status {
      | 200 => Ok(200)->resolve
      | status => {
          res
          ->Fetch.Response.json
          ->then(json => {
            Js.log2(status, json->Json.stringify)
            resolve()
          })
          ->ignore
          Error(#Patch_Error)->resolve
        }
      }
    })
    ->catch(e => {
      Js.log2("e: ", e)
      resolve(Error(#Unknown_Error))
    })
  }

  // let addEntry = (~content, ~key, ~entry, ~config) => {
  //   let {id, name, token} = config
  //   switch content->Js.Dict.get(key) {
  //   | Some(_) => key->DuplicateKey->Error->resolve
  //   | None => {
  //       content->Js.Dict.set(key, entry)
  //       let content = content->Js.Json.stringifyAny
  //       let files = Js.Dict.empty()
  //       files->Js.Dict.set(name, {"content": content})
  //       let body = {
  //         "gist_id": id,
  //         "description": `Add gist entry with key: ${key}`,
  //         "files": files,
  //       }

  //       let init = Fetch.RequestInit.make(
  //         ~method_=Patch,
  //         ~body=Fetch.BodyInit.make(body->Js.Json.stringifyAny->Belt.Option.getExn),
  //         ~headers=Fetch.HeadersInit.make({
  //           "Authorization": `token ${token}`,
  //           "Accept": "application/vnd.github+json",
  //         }),
  //         (),
  //       )

  //       `https://api.github.com/gists/${id}`
  //       ->Fetch.fetchWithInit(init)
  //       ->then(res => {
  //         switch res->Fetch.Response.status {
  //         | 200 => Ok(200)->resolve
  //         | status => {
  //             res
  //             ->Fetch.Response.json
  //             ->then(json => {
  //               Js.log2(status, json->Json.stringify)
  //               resolve()
  //             })
  //             ->ignore
  //             Error(#Patch_Error)->resolve
  //           }
  //         }
  //       })
  //       ->catch(e => {
  //         Js.log2("e: ", e)
  //         resolve(Error(#Unknown_Error))
  //       })
  //     }
  //   }
  // }
}
