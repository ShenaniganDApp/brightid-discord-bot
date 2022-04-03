type t = Types.channelT

@get external getChannelId: t => string = "id"
@get external getChannelName: t => string = "name"

let validateChannelName = channelName => {
  switch channelName {
  | Types.ChannelName(channelName) => channelName
  }
}
