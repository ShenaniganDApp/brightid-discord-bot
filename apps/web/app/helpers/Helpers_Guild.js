// Generated by ReScript, PLEASE EDIT WITH CARE


function iconUri(param) {
  var icon = param.icon;
  if (icon !== undefined) {
    return "https://cdn.discordapp.com/icons/" + param.id + "/" + icon + ".png";
  } else {
    return "/assets/brightid_logo_white.png";
  }
}

export {
  iconUri ,
}
/* No side effect */
