const constants = require('../constants')
const endpoints = require('../endpoints')
const responseCodes = require('../services/responseCodes')

const VERIFICATION_POLLING_EVERY = 3000
const REQUEST_TIMEOUT = 60000

const VERIFICATION_INFO_DEFAULT = {
  authorExist: false,
  authorUnique: false,
  signature: null,
  timestamp: 0,
  userAddresses: [],
  userSponsored: false,
  userVerified: false,
  error: null,
  fetching: true,
}

export function getBrightIdVerification(messageAuthor) {
  const verificationInfo = VERIFICATION_INFO_DEFAULT

  let cancelled = false
  let retryTimer

  if (!messageAuthor) {
    return setVerificationInfo(info => ({ ...info, fetching: false }))
  }

  const fetchVerificationInfo = async () => {
    const endpoint = `${endpoints.BRIGHTID_VERIFICATION_ENDPOINT}/${constants.CONTEXT_ID}/${messageAuthor}?signed=nacl&timestamp=seconds`
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
            setVerificationInfo({
              error: response.errorMessage,
              fetching: false,
            })
            break

          case responseCodes.NOT_FOUND_CODE:
            // If the users didn't link their address to the their BrightId account or cannot be verified for the context (meaning is unverified on the BrightId app)
            verificationInfo = {
              addressExist:
                response.errorNum === responseCodes.CAN_NOT_BE_VERIFIED,
              addressUnique: false,
              timestamp: 0,
              userAddresses: [],
              userSponsored:
                response.errorNum === responseCodes.CAN_NOT_BE_VERIFIED,
              userVerified: false,
              fetching: false,
            }
            break

          case responseCodes.NOT_SPONSORED_CODE:
            verificationInfo = {
              addressExist: true,
              addressUnique: false,
              timestamp: 0,
              userAddresses: [],
              userSponsored: false,
              userVerified: false,
              fetching: false,
            }
            break

          default:
            verificationInfo = {
              authorExist: true,
              authorUnique: response.data?.unique,
              signature: { ...response.data?.sig },
              timestamp: response.data?.timestamp,
              userAddresses: response.data?.contextIds,
              userSponsored: true,
              userVerified: true,
              fetching: false,
            }
            break
        }
      }
    } catch (err) {
      console.error(`Could not fetch verification info `, err)
    }

    if (!cancelled) {
      retryTimer = setTimeout(fetchVerificationInfo, VERIFICATION_POLLING_EVERY)
    }

    try {
      fetchVerificationInfo()
    } catch (err) {}
    cancelled = true
    clearTimeout(retryTimer)
  }

  return verificationInfo
}
