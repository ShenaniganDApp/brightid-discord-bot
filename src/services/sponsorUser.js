const nacl = require('tweetnacl')
nacl.util = require('tweetnacl-util');
const stringify = require('fast-json-stable-stringify')

const constants = require( '../constants')
const endpoints = require( '../endpoints') 
const responseCodes = require( './responseCodes')

module.exports = async function sponsorUser(messageAuthor) {
  try {
    const privateKey =  process.env.NODE_PK

    if (!privateKey) {
      return { error: 'No private key found for the node' }
    }

    const timestamp = Date.now()
    const op = {
      v: 5,
      name: 'Sponsor',
      app: constants.CONTEXT_ID,
      timestamp,
      contextId: messageAuthor,
    }

    const message = getMessage(op)
    const messageUint8Array = Buffer.from(message)

    const privateKeyUint8Array = nacl.util.decodeBase64(privateKey)
    console.log('privateKeyUint8Array: ', privateKeyUint8Array);

    const signedMessageUint8Array = nacl.sign.detached(
      messageUint8Array,
      privateKeyUint8Array
    )

    op.sig = nacl.util.encodeBase64(signedMessageUint8Array)

    const endpoint = `${endpoints.BRIGHTID_SUBSCRIPTION_ENDPOINT}`
    const rawResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(op),
    })

    if (rawResponse.ok) {
      return {
        error: null,
      }
    }

    const response = await rawResponse.json()

    if (response.code === responseCodes.NO_CONTENT) {
      return {
        error: null,
      }
    }

    return {
      error: response.errorMessage,
    }
  } catch (err) {
    console.error(err)
    return { error: err }
  }
}

function getMessage(op) {
  const signedOp = {}
  for (const k in op) {
    if (['sig', 'sig1', 'sig2', 'hash'].includes(k)) {
      continue
    }
    signedOp[k] = op[k]
  }
  return stringify(signedOp)
}