module Toaster = {
  type t
  @module("react-hot-toast")
  external makeToaster: t = "default"

  @react.component @module("react-hot-toast")
  external make: unit => React.element = "Toaster"

  @send external success: (t, string) => unit = "success"
  @send external error: (t, string) => unit = "error"
}
