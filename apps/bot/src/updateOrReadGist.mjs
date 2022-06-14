import fetch from 'node-fetch'

import { error, log } from './utils.mjs'

export function updateGist(guildId, obj) {
  fetch(`https://api.github.com/gists/${process.env.GIST_ID}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${process.env.GITHUB_ACCESS_TOKEN}`,
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

      fetch(`https://api.github.com/gists/${process.env.GIST_ID}`, {
        method: 'PATCH',
        headers: {
          Authorization: `token ${process.env.GITHUB_ACCESS_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
        },
        body: JSON.stringify(updatedBody),
      }).then(res => {
        console.log('res: ', res)
        console.log('process.env.GIST_ID: ', process.env.GIST_ID)
        console.log(
          'process.env.GITHUB_ACCESS_TOKEN: ',
          process.env.GITHUB_ACCESS_TOKEN,
        )
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

export function readGist() {
  return fetch(`https://api.github.com/gists/${process.env.GIST_ID}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${process.env.GITHUB_ACCESS_TOKEN}`,
    },
  })
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
