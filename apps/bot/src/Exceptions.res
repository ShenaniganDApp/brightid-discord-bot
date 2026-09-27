exception BrightIdError(Shared.BrightId.Error.t)
exception VerifyCommandError(string)
exception InviteCommandError(string)
exception ButtonVerifyHandlerError(string)
exception SponsorButtonError(string)
exception PremiumSponsorButtonError(string)

let isUnverifiedError = (error: Shared.BrightId.Error.t) =>
  error.error &&
  ((error.code === 403 && (error.errorNum === 2 || error.errorNum === 3 || error.errorNum === 4)) ||
    (error.code === 404 && error.errorNum === 2))
