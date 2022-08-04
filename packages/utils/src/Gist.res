open Promise

module NodeFetchPolyfill = {
  type t
  @module("node-fetch") external fetch: t = "default"
  @val external globalThis: 'a = "globalThis"
  globalThis["fetch"] = fetch
}

module Response = {
  type t<'data>

  exception PatchError
  @send external json: t<'data> => Promise.t<'data> = "json"
  @get external status: t<'data> => int = "status"
}

Env.createEnv()

let envConfig = Env.getConfig()

@raises(Env.EnvError)
let envConfig = switch envConfig {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

@raises(Env.EnvError)
let githubAccessToken = envConfig["githubAccessToken"]

@raises(Env.EnvError)
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

module ReadGist = {
  @val @scope("globalThis")
  external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

  @raises([Json.Decode.DecodeError, Not_found, Env.EnvError])
  let content = (~token, ~id, ~name, ~decoder) => {
    let params = {
      "Authorization": `Bearer ${token}`,
    }

    `https://api.github.com/gists/${id}`
    ->fetch(params)
    ->then(res => res->Response.json)
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

  @val @scope("globalThis")
  external fetch: (string, 'params) => Promise.t<Response.t<Js.Json.t>> = "fetch"

  type config<'a> = {
    id: string,
    name: string,
    token: string,
    decoder: Json.Decode.t<'a>,
  }
  let config = (~id, ~name, ~token, ~decoder) => {
    id,
    name,
    token,
    decoder,
  }

  let updateEntry = (~config, ~key, ~entry) => {
    let {id, name, token, decoder} = config
    ReadGist.content(~token, ~id, ~name, ~decoder)
    ->then(content => {
      let prev = content->Js.Dict.get(key)->Belt.Option.getExn
      let new = prev->Js.Obj.assign(entry)
      content->Js.Dict.set(key, new)
      let content = content->Js.Json.stringifyAny
      let files = Js.Dict.empty()
      files->Js.Dict.set(name, {"content": content})
      let body = {
        "gist_id": id,
        "description": "Update guilds",
        "files": files,
      }

      let params = {
        "method": "PATCH",
        "headers": {
          "Authorization": `token ${token}`,
          "Accept": "application/vnd.github+json",
        },
        "body": body->Js.Json.stringifyAny,
      }

      `https://api.github.com/gists/${id}`
      ->fetch(params)
      ->then(res => {
        switch res->Response.status {
        | 200 => Ok(200)->resolve
        | status => {
            res
            ->Response.json
            ->then(
              json => {
                Js.log2(status, json->Json.stringify)
                resolve()
              },
            )
            ->ignore
            Error(Response.PatchError)->resolve
          }
        }
      })
    })
    ->catch(e => {
      Js.log2("e: ", e)
      resolve(Error(e))
    })
  }

  let updateAllEntries = (~config, ~entries) => {
    let {id, name, token, decoder} = config
    ReadGist.content(~token, ~id, ~name, ~decoder)
    ->then(content => {
      let entries = entries->Js.Dict.fromList
      let keys = entries->Js.Dict.keys
      keys->Belt.Array.forEach(key => {
        let prev = content->Js.Dict.get(key)->Belt.Option.getExn
        let entry = entries->Js.Dict.get(key)->Belt.Option.getExn
        let new = prev->Js.Obj.assign(entry)
        content->Js.Dict.set(key, new)
      })
      let content = content->Js.Json.stringifyAny
      let files = Js.Dict.empty()
      files->Js.Dict.set(name, {"content": content})
      let body = {
        "gist_id": id,
        "description": "Update gist",
        "files": files,
      }

      let params = {
        "method": "PATCH",
        "headers": {
          "Authorization": `token ${token}`,
          "Accept": "application/vnd.github+json",
        },
        "body": body->Js.Json.stringifyAny,
      }

      `https://api.github.com/gists/${id}`
      ->fetch(params)
      ->then(res => {
        switch res->Response.status {
        | 200 => Ok(200)->resolve
        | status => {
            res
            ->Response.json
            ->then(
              json => {
                Js.log2(status, json->Json.stringify)
                resolve()
              },
            )
            ->ignore
            Error(Response.PatchError)->resolve
          }
        }
      })
    })
    ->catch(e => {
      Js.log2("e: ", e)
      resolve(Error(e))
    })
  }
}
