import { Links, Meta, Scripts } from '@remix-run/react'

export { default, links, loader, meta } from './root.mjs'

export function ErrorBoundary({ error }) {
  console.error(error)
  return (
    <html>
      <head>
        <title>Oh no!</title>
        <Meta />
        <Links />
      </head>
      <body>
        <p className="text-center">Something went wrong!</p>
        <p className="text-center">
          BrightID command center is still in Beta. Try reloading the page!
        </p>
        <Scripts />
      </body>
    </html>
  )
}
