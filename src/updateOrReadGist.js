const fetch = require('node-fetch')
const {
  decodeData,
  encodeData,
  marshallFileUpdate,
} = require('./handler-utils')

const { error, log } = require('./utils')

function updateGist(guildId, obj) {
  fetch(`https://api.github.com/gists/bf60347b40acabad78e3f840ba2b5c7f`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}`,
    },
  })
    .then(res => res.json())
    .then(body => {
      const parsedContent = JSON.parse(body.files['guildData.json'].content)

      parsedContent[guildId] = { ...parsedContent[guildId], ...obj }
      const content = JSON.stringify(parsedContent)
      const updatedBody = {
        description: 'Update guilds',
        files: {
          'guildData.json': {
            content,
          },
        },
      }

      fetch(`https://api.github.com/gists/bf60347b40acabad78e3f840ba2b5c7f`, {
        method: 'PATCH',
        headers: {
          Authorization: `token ${process.env.GITHUB_API_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
        },
        body: JSON.stringify(updatedBody),
      }).then(res => {
        if (res.status == 200) {
          log(`${res.status}: Updated guild Data for ${guildId}`)
        } else {
          log(`${res.error}: Something went wrong`)
        }
      })
    })
    .catch(err => {
      error(err)
    })
}

function readGist() {
  return fetch(
    'https://api.github.com/gists/bf60347b40acabad78e3f840ba2b5c7f',
    {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}`,
      },
    },
  )
    .then(res => res.json())
    .then(body => {
      const {
        files: {
          'guildData.json': { content },
        },
      } = body

      return JSON.parse(content) // Manipulated the decoded content:
    })
}

module.exports = { updateGist, readGist }
