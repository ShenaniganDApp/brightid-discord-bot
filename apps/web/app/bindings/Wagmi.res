// type queryArgs = {
//   "onSuccess": option<unit => unit>,
//   "onSettled": option<unit => unit>,
//   "onError": option<unit => unit>,
//   "onMutate": option<unit => unit>,
// }
type queryResult<'data> = {
  "data": Js.Nullable.t<'data>,
  "error": Js.Nullable.t<string>,
  "isError": bool,
  "isLoading": bool,
  "isSuccess": bool,
}
@module("wagmi")
external useAccount: 'a => queryResult<{"address": Js.Nullable.t<string>}> = "useAccount"
@module("wagmi")
external useSignMessage: 'a => {
  ...queryResult<{
    "signature": Js.Nullable.t<string>,
  }>,
  "signMessage": unit => unit,
} = "useSignMessage"
