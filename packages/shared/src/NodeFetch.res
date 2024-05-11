type t
@module("node-fetch") external fetch: t = "default"
@val external globalThis: 'a = "globalThis"
globalThis["fetch"] = fetch

module Response = {
  type t<'data>

  @send external json: t<'data> => promise<'data> = "json"
  @get external status: t<'data> => int = "status"
}
