let iconUri = ({id, icon}: Types.guild) => {
  switch icon {
  | None => "/assets/brightid_logo_white.png"
  | Some(icon) => `https://cdn.discordapp.com/icons/${id}/${icon}.png`
  }
}
