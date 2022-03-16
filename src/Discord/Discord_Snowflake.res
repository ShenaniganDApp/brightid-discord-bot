type snowflake = Snowflake(string)

let validateSnowflake = snowflake =>
  switch snowflake {
  | Snowflake(snowflake) => snowflake
  }