type t
type channelName = ChannelName(string)

@get external getChannelId: t => string = "id"
@get external getChannelName: t => string = "name"

type channel = {
  t: t,
  id: Discord_Snowflake.snowflake,
  name: channelName,
}

let validateChannelName = channelName => {
  switch channelName {
  | ChannelName(channelName) => channelName
  }
}

let make = channel => {
  let id = getChannelId(channel)
  let name = getChannelName(channel)
  {
    t: channel,
    id: Snowflake(id),
    name: ChannelName(name),
  }
}
