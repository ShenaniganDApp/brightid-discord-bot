let getAppInfo = async (~nodes=Endpoints.nodes, context) => {
  let json = await FetchTools.fetchJson(~relativeUrl=`/apps/${context}`, nodes)
  let {data} = FetchTools.decodeResponse(json, Decode.Decode_BrightId.App.data)
  if data.id !== context || data.context !== context {
    raise(Json.Decode.DecodeError("BrightID application does not match the requested app"))
  }
  data
}
