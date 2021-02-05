const UTF8_FORMAT = 'utf8'
const BASE64_FORMAT = 'base64'

function decodeData(encodedData) {
  const bufferedContent = Buffer.from(encodedData, BASE64_FORMAT)
  return JSON.parse(bufferedContent.toString(UTF8_FORMAT))
}

function encodeData(decodedData) {
  const updatedContent = Buffer.from(
    JSON.stringify(decodedData, null, 2),
    UTF8_FORMAT,
  )
  return updatedContent.toString(BASE64_FORMAT)
}

function marshallFileUpdate({ message, content, sha }) {
  return JSON.stringify({
    message,
    content,
    sha,
  })
}

module.exports = {
  decodeData,
  encodeData,
  marshallFileUpdate,
}
