const { CONTEXT_ID } = require('../constants')
const { BRIGHTID_VERIFICATION_ENDPOINT } = require('../endpoints')
const {
  NOT_FOUND_CODE,
  ERROR_CODE,
  CAN_NOT_BE_VERIFIED,
} = require('../services/responseCodes')
const UUID = require('uuid')
const fetch = require('node-fetch')

const { VerificationError } = require('../error-utils')

const VERIFICATION_POLLING_EVERY = 3000
const REQUEST_TIMEOUT = 60000

const VERIFICATION_INFO_DEFAULT = {
  authorExist: false,
  authorUnique: false,
  signature: null,
  timestamp: 0,
  userAddresses: [],
  userVerified: false,
  error: null,
  fetching: true,
}

module.exports = async function getBrightIdVerification(member) {
  let verificationInfo = VERIFICATION_INFO_DEFAULT
  let cancelled = false
  let retryTimer

  if (!member.id) {
    return (verificationInfo = { ...verificatioInfo, fetching: false })
  }

  const fetchVerificationInfo = async () => {
    const ID = UUID.v5(member.id, process.env.UUID_NAMESPACE)
    const endpoint = `${BRIGHTID_VERIFICATION_ENDPOINT}/${CONTEXT_ID}/${ID}?timestamp=seconds`
    try {
      const rawResponse = await fetch(endpoint, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        timeout: REQUEST_TIMEOUT,
      })
      const response = await rawResponse.json()
      if (!cancelled) {
        switch (response.code) {
          case ERROR_CODE:
            verificationInfo = {
              error: response.errorMessage,
              fetching: false,
            }
            break

          case NOT_FOUND_CODE:
            // If the users didn't link their address to the their BrightId account or cannot be verified for the context (meaning is unverified on the BrightId app)
            verificationInfo = {
              authorExist: response.errorNum === CAN_NOT_BE_VERIFIED,
              authorUnique: false,
              timestamp: 0,
              userAddresses: [],
              userVerified: false,
              fetching: false,
            }
            break

          default:
            verificationInfo = {
              authorExist: true,
              authorUnique: response.data.unique,
              timestamp: response.data.timestamp,
              userAddresses: response.data.contextIds,
              userVerified: true,
              fetching: false,
            }
            break
        }
      }
    } catch (err) {
      console.log('err: ', err)
      throw new VerificationError(
        `Verification Info could not be fetched from BrightID`,
      )
    }

    if (!cancelled) {
      retryTimer = setTimeout(fetchVerificationInfo, VERIFICATION_POLLING_EVERY)
    }
  }
  try {
    await fetchVerificationInfo()
  } catch (err) {
    throw new Error(err)
  }
  cancelled = true
  clearTimeout(retryTimer)

  return verificationInfo
}
