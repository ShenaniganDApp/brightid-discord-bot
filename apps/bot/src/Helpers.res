let nowInSeconds = () => {
  (Date.now() /. 1000.0)->Float.toInt
}

let fifteenMinutesFromNow = () => {
  let fifteenMinutesInSeconds = 15 * 60
  nowInSeconds() + fifteenMinutesInSeconds
}
