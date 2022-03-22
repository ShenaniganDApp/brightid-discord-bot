type t<'key, 'value>

@send external find: (t<'key, 'value>, unit => bool) => Js.Nullable.t<'value> = "find"
@send external mapValues: (t<'key, 'value>, 'value => 'result) => t<'key, 'result> = "mapValues"
@send external keyArray: t<'key, 'value> => array<'key> = "keyArray"
@send external array: t<'key, 'value> => array<'value> = "array"
