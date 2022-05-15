type code =
  | NoContent(int)
  | NotSponsoredCode(int)
  | NotFoundCode(int)
  | ErrorCode(int)
  | ContextNotFound(int)
  | ContextIdNotFound(int)
  | CanNotBeVerified(int)
  | NotSponsored(int)

// let noContent = NoContent(204)
// let notSponsoredCode = NotSponsoredCode(403)
// let notFoundCode = NotFoundCode(404)
// let errorCode = ErrorCode(500)

// let contextNotFound = ContextNotFound(1)
// let contextidNotFound = ContextIdNotFound(2)
// let canNotBeVerified = CanNotBeVerified(3)
// let notSponsored = NotSponsored(4)
let noContent = 204
let notSponsoredCode = 403
let notFoundCode = 404
let errorCode = 500

let contextNotFound = 1
let contextidNotFound = 2
let canNotBeVerified = 3
let notSponsored = 4
