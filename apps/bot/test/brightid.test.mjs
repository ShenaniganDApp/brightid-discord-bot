import assert from 'node:assert/strict'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { createServer } from 'node:http'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test, { after } from 'node:test'

const directory = mkdtempSync(join(tmpdir(), 'brightid-api-test-'))
process.env.ENV_FILE = join(directory, '.env')
writeFileSync(process.env.ENV_FILE, '')
after(() => rmSync(directory, { recursive: true, force: true }))
for (const name of [
  'DISCORD_API_TOKEN',
  'DISCORD_CLIENT_ID',
  'GIST_ID',
  'GITHUB_ACCESS_TOKEN',
  'DISCORD_LOG_CHANNEL_ID',
]) {
  process.env[name] = 'api-test'
}
process.env.UUID_NAMESPACE = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'

const Verification = await import(
  '../src/services/Services_VerificationInfo.mjs'
)
const App = await import('../src/services/Services_AppInfo.mjs')
const Exceptions = await import('../src/Exceptions.mjs')
const Commands = await import('../src/commands/Commands_Verify.mjs')
const Buttons = await import('../src/buttons/Buttons_Verify.mjs')
const Endpoints = await import('../src/Endpoints.mjs')

const id = '17b91b76-e55d-4eab-b592-3bd5fa2d8c11'
// V5 envelope shapes observed on Aura; identifiers and counts are test values.
const verified = {
  data: { unique: true, app: 'Discord', context: 'Discord', contextIds: [id] },
}
const unverified = { ...verified, data: { ...verified.data, unique: false } }
const app = {
  data: {
    id: 'Discord',
    name: 'Discord Unique Bot',
    context: 'Discord',
    verification: 'BrightID',
    logo: '',
    url: '',
    assignedSponsorships: 2,
    unusedSponsorships: 1,
    testing: false,
    soulbound: false,
    soulboundMessage: '',
  },
}
const apiError = (errorNum, code = 403) => ({
  error: true,
  errorNum,
  errorMessage: 'BrightID API error',
  code,
})

async function node(t, handler, timeout = 1000) {
  const server = createServer(handler)
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve))
  t.after(
    () =>
      new Promise(resolve => {
        server.close(resolve)
        server.closeAllConnections()
      }),
  )
  return {
    url: `http://127.0.0.1:${server.address().port}/brightid/v5`,
    timeout,
  }
}

function send(response, status, body) {
  response.writeHead(status, { 'Content-Type': 'application/json' })
  response.end(JSON.stringify(body))
}

const domainError = number => error =>
  error.RE_EXN_ID === Exceptions.BrightIdError && error._1.errorNum === number

test('bot requests use Aura first and remain on v5', () => {
  assert.ok(Endpoints.nodes.every(node => node.url.endsWith('/v5')))
  assert.equal(
    Endpoints.nodes[0].url,
    'https://aura-node.brightid.org/brightid/v5',
  )
})

test('502 HTML falls back to a working v5 node and validates the account', async t => {
  const paths = []
  const failed = await node(t, (request, response) => {
    paths.push(request.url)
    response.writeHead(502, { 'Content-Type': 'text/html' })
    response.end('<html>Bad Gateway</html>')
  })
  const healthy = await node(t, (request, response) => {
    paths.push(request.url)
    send(response, 200, verified)
  })
  const result = await Verification.getVerificationInfo([failed, healthy], id)
  assert.equal(result._0.unique, true)
  assert.deepEqual(paths, [
    `/brightid/v5/verifications/Discord/${id}`,
    `/brightid/v5/verifications/Discord/${id}`,
  ])
})

test(
  'all failed nodes are attempted once and then reject',
  { timeout: 3000 },
  async t => {
    let requests = 0
    const failed = await node(t, (_, response) => {
      requests++
      send(response, 503, {})
    })
    const second = await node(t, (_, response) => {
      requests++
      send(response, 502, {})
    })
    await assert.rejects(Verification.getVerificationInfo([failed, second], id))
    assert.equal(requests, 2)
    await assert.rejects(Verification.getVerificationInfo([], id))
  },
)

test(
  'a timed-out node falls back rather than hanging verification',
  { timeout: 3000 },
  async t => {
    const stalled = await node(t, () => {}, 50)
    const healthy = await node(t, (_, response) =>
      send(response, 200, verified),
    )
    const result = await Verification.getVerificationInfo(
      [stalled, healthy],
      id,
    )
    assert.equal(result._0.unique, true)
  },
)

for (const [status, errorNum] of [
  [403, 3],
  [403, 4],
  [404, 2],
  [404, 12],
]) {
  test(`HTTP ${status} BrightID error ${errorNum} is preserved without failover`, async t => {
    let fallbackCalls = 0
    const primary = await node(t, (_, response) =>
      send(response, status, apiError(errorNum, status)),
    )
    const secondary = await node(t, (_, response) => {
      fallbackCalls++
      send(response, 200, verified)
    })
    await assert.rejects(
      Verification.getVerificationInfo([primary, secondary], id),
      domainError(errorNum),
    )
    assert.equal(fallbackCalls, 0)
  })
}

test('false uniqueness is preserved and cannot become a verified result', async t => {
  const source = await node(t, (_, response) => send(response, 200, unverified))
  const result = await Verification.getVerificationInfo([source], id)
  assert.equal(result._0.unique, false)
})

for (const [name, body] of [
  ['null', null],
  ['array', []],
  ['missing fields', { data: {} }],
  ['wrong type', { data: { ...verified.data, unique: 'true' } }],
  ['null uniqueness', { data: { ...verified.data, unique: null } }],
  ['wrong app', { data: { ...verified.data, app: 'other' } }],
  ['wrong context', { data: { ...verified.data, context: 'other' } }],
  ['wrong account', { data: { ...verified.data, contextIds: ['other'] } }],
  ['empty account list', { data: { ...verified.data, contextIds: [] } }],
]) {
  test(`${name} verification response is rejected`, async t => {
    const source = await node(t, (_, response) => send(response, 200, body))
    await assert.rejects(Verification.getVerificationInfo([source], id))
  })
}

test('HTML success and HTTP error with a success-shaped body cannot verify a user', async t => {
  const html = await node(t, (_, response) => {
    response.end('<html>Unavailable</html>')
  })
  await assert.rejects(Verification.getVerificationInfo([html], id))
  const invalidStatus = await node(t, (_, response) =>
    send(response, 403, verified),
  )
  await assert.rejects(Verification.getVerificationInfo([invalidStatus], id))
})

test('application sponsorship data and bulk verified IDs use the same v5 transport', async t => {
  const paths = []
  const failed = await node(t, (_, response) => send(response, 502, {}))
  const healthy = await node(t, (request, response) => {
    paths.push(request.url)
    send(
      response,
      200,
      request.url.includes('/apps/')
        ? app
        : { data: { contextIds: [id], count: 1 } },
    )
  })
  const result = await App.getAppInfo([failed, healthy], 'Discord')
  assert.equal(result.unusedSponsorships, 1)
  assert.equal(result.assignedSponsorships, 2)
  const ids = await Verification.getVerifiedContextIds([failed, healthy])
  assert.deepEqual([...ids], [id])
  assert.deepEqual(paths, [
    '/brightid/v5/apps/Discord',
    '/brightid/v5/verifications/Discord',
  ])
})

test('role removal only recognizes explicit unverified-account errors', () => {
  for (const number of [2, 3, 4])
    assert.equal(Exceptions.isUnverifiedError(apiError(number)), true)
  for (const error of [
    apiError(12, 404),
    apiError(42, 500),
    apiError(4, 500),
    { ...apiError(4), error: false },
  ]) {
    assert.equal(Exceptions.isUnverifiedError(error), false)
  }
})

test('not-verified responses tell users to complete verification, without claiming they need sponsorship', async () => {
  const replies = []
  const interaction = {
    editReply: async options => replies.push(options),
    followUp: async options => replies.push(options),
  }
  await Commands.handleUnverifiedGuildMember(3, interaction, id)
  await Buttons.handleUnverifiedGuildMember(3, interaction)
  assert.equal(replies.length, 2)
  for (const reply of replies) {
    assert.match(reply.content, /not completed the required verification/)
    assert.equal(reply.ephemeral, true)
    assert.doesNotMatch(reply.content, /sybil|sponsor/i)
  }
})

test('rate limits fall back without becoming an unverified-account response', async t => {
  const limited = await node(t, (_, response) =>
    send(response, 429, apiError(4, 429)),
  )
  const healthy = await node(t, (_, response) => send(response, 200, verified))
  const result = await Verification.getVerificationInfo([limited, healthy], id)
  assert.equal(result._0.unique, true)
})

test('a server-error envelope in HTTP 200 stays an infrastructure failure', async t => {
  const source = await node(t, (_, response) =>
    send(response, 200, apiError(4, 500)),
  )
  await assert.rejects(
    Verification.getVerificationInfo([source], id),
    error => error.RE_EXN_ID !== Exceptions.BrightIdError,
  )
})

for (const [name, data] of [
  ['wrong app', { ...app.data, id: 'other' }],
  ['wrong context', { ...app.data, context: 'other' }],
  ['missing sponsorship count', { ...app.data, unusedSponsorships: undefined }],
  ['wrong sponsorship type', { ...app.data, unusedSponsorships: '1' }],
  ['null sponsorship count', { ...app.data, unusedSponsorships: null }],
]) {
  test(`${name} application data is rejected`, async t => {
    const source = await node(t, (_, response) => send(response, 200, { data }))
    await assert.rejects(App.getAppInfo([source], 'Discord'))
  })
}

test('an explicit unlinked v5 response remains unverified with an empty account list', async t => {
  const source = await node(t, (_, response) =>
    send(response, 200, { data: { ...unverified.data, contextIds: [] } }),
  )
  const result = await Verification.getVerificationInfo([source], id)
  assert.equal(result._0.unique, false)
  assert.deepEqual(result._0.contextIds, [])
})
