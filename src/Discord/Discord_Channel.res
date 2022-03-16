type channelName = ChannelName(string)

type channel = {
  id: Discord_Snowflake.snowflake,
  name: channelName,
}

let validateChannelName = channelName => {
  switch channelName {
  | ChannelName(channelName) => channelName
  }
}
