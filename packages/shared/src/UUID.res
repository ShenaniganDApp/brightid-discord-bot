type t = string
type name = UUIDName(string)
@module("uuid") external v5: (string, string) => t = "v5"
