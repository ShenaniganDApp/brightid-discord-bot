type snowflake = Snowflake(string)

module SnowflakeCompare = Belt.Id.MakeComparable({
  type t = snowflake
  let cmp = (a, b) => compare(a, b)
})

let validateSnowflake = snowflake =>
  switch snowflake {
  | Snowflake(snowflake) => snowflake
  }