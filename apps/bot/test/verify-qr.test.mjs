import assert from 'node:assert/strict'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test, { after } from 'node:test'
import jsQR from 'jsqr'
import { PNG } from 'pngjs'

// Import the command with test configuration, without loading deployment secrets.
const envDirectory = mkdtempSync(join(tmpdir(), 'brightid-qr-test-'))
process.env.ENV_FILE = join(envDirectory, '.env')
writeFileSync(process.env.ENV_FILE, '')
after(() => rmSync(envDirectory, { recursive: true, force: true }))
for (const name of [
  'DISCORD_API_TOKEN',
  'DISCORD_CLIENT_ID',
  'UUID_NAMESPACE',
  'GIST_ID',
  'GITHUB_ACCESS_TOKEN',
  'DISCORD_LOG_CHANNEL_ID',
]) {
  process.env[name] = 'qr-test'
}

const {
  makeLinkOptions,
  beforeSponsorMessageOptions,
  createMessageAttachmentFromUri,
} = await import('../src/commands/Commands_Verify.mjs')

const uuid = '17b91b76-e55d-4eab-b592-3bd5fa2d8c11'
const expectedUri = `brightid://link-verification/https:%2f%2faura-node.brightid.org/Discord/${uuid}`

for (const [name, makeOptions] of [
  ['verification', () => makeLinkOptions(uuid)],
  [
    'sponsorship',
    () => beforeSponsorMessageOptions('before-premium-sponsor', uuid),
  ],
]) {
  test(`${name} attaches a PNG QR code that decodes to the BrightID link`, async () => {
    const options = await makeOptions()
    assert.equal(options.ephemeral, true)
    assert.equal(options.files.length, 1)
    const attachment = options.files[0]
    assert.equal(attachment.name, 'qrcode.png')
    assert.ok(Buffer.isBuffer(attachment.attachment))
    const png = PNG.sync.read(attachment.attachment)
    const decoded = jsQR(new Uint8ClampedArray(png.data), png.width, png.height)
    assert.equal(decoded?.data, expectedUri)
  })
}

test('QR rendering errors reject instead of creating an invalid attachment', async () => {
  await assert.rejects(createMessageAttachmentFromUri(''))
})
