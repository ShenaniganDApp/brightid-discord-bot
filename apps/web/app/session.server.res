// let cookieOptions = Remix.CreateCookieOptions.make(
//   ~sameSite=#lax,
//   ~path="/",
//   ~httpOnly=true,
//   ~secrets=["s3cr3t"],
//   ~secure=Remix.process["env"]["NODE_ENV"] === "production",
//   (),
// )
// let cookie = Remix.createCookieWithOptions("_session", cookieOptions)
// let cookieSessionStorageOptions = Remix.CreateCookieSessionStorageOptions.make(~cookie)

// let sessionStorage = Remix.createCookieSessionStorageWithOptions(cookieSessionStorageOptions)

