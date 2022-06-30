type gist = {
  html_url: string,
  id: string,
}

type loaderData = array<gist>

// Explicit return type for type safety
let loader = (): Promise.t<loaderData> =>
  Webapi.Fetch.fetch("https://api.github.com/gists")
  ->Promise.then(res => res->Webapi.Fetch.Response.json)
  ->Promise.thenResolve(json =>
    json
    ->Js.Json.decodeArray
    ->Belt.Option.map(gists =>
      gists->Js.Array2.map(gist => {
        let gist = gist->Js.Json.decodeObject->Belt.Option.getUnsafe

        {
          html_url: gist
          ->Js.Dict.get("html_url")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
          id: gist
          ->Js.Dict.get("id")
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getExn,
        }
      })
    )
    ->Belt.Option.getUnsafe
  )

let default = () => {
  let gists: loaderData = Remix.useLoaderData()

  <ul>
    {gists
    ->Js.Array2.map(gist =>
      <li key={gist.id}> <a href={gist.html_url}> {gist.id->React.string} </a> </li>
    )
    ->React.array}
  </ul>
}
