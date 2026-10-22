@val external document: Dom.element = "document"

module ReactDOM = {
  @module("react-dom/client")
  external hydrateRoot: (Dom.element, React.element) => unit = "hydrateRoot"
}

@module("react") external startTransition: (unit => unit) => unit = "startTransition"

let hydrate = () =>
  startTransition(() => {
    ReactDOM.hydrateRoot(
      document,
      <React.StrictMode>
        <Remix.RemixBrowser />
      </React.StrictMode>,
    )
  })
