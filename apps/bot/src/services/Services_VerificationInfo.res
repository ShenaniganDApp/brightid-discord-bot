type verificationInfo = VerificationInfo(BrightId.ContextId.t)

Env.createEnv()

let config = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let {context} = module(Constants)

let decodeVerification = (json, contextId) => {
  let {data} = FetchTools.decodeResponse(json, Decode.Decode_BrightId.ContextId.data)
  let isUnlinked = !data.unique && data.contextIds->Array.length === 0
  if (
    data.app !== context ||
    data.context !== context ||
    (!isUnlinked && !(data.contextIds->Array.includes(contextId)))
  ) {
    raise(Json.Decode.DecodeError("BrightID verification does not match the requested account"))
  }
  VerificationInfo(data)
}

let getVerificationInfo = async (~nodes=Endpoints.nodes, contextId) => {
  let json = await FetchTools.fetchJson(
    ~relativeUrl=`/verifications/${context}/${contextId}`,
    nodes,
  )
  decodeVerification(json, contextId)
}

let fetchVerificationInfo = id => {
  let contextId = id->UUID.v5(config["uuidNamespace"])
  getVerificationInfo(contextId)
}

let getBrightIdVerification = member => {
  let id = member->Discord.GuildMember.getGuildMemberId
  id->fetchVerificationInfo
}

let getVerifiedContextIds = async (~nodes=Endpoints.nodes, ()) => {
  let json = await FetchTools.fetchJson(~relativeUrl=`/verifications/${context}`, nodes)
  let {data} = FetchTools.decodeResponse(json, Decode.Decode_BrightId.Verifications.data)
  Set.fromArray(data.contextIds)
}
