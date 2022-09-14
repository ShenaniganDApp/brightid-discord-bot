module FaBars = {
  @react.component @module("react-icons/fa")
  external make: (~className: string=?, ~size: int=?) => React.element = "FaBars"
}

module FaEdit = {
  @react.component @module("react-icons/fa")
  external make: (~className: string=?, ~size: int=?) => React.element = "FaEdit"
}
