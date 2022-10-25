module Toaster = {
  type t
  @module("react-hot-toast")
  external makeToaster: t = "default"

  @module("react-hot-toast")
  external makeCustomToaster: (t => React.element, ~options: 'options=?, unit) => unit = "default"

  @react.component @module("react-hot-toast")
  external make: unit => React.element = "Toaster"

  @send external success: (t, string, ~options: 'options=?, unit) => unit = "success"
  @send external error: (t, string, ~options: 'options=?, unit) => unit = "error"
  @send external dismiss: (t, string) => unit = "dismiss"
}
