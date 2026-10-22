import { lazy, Suspense, useEffect, useState } from 'react'

const Animation = lazy(() => import('react-lottie'))

export default function Lottie(props) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  return mounted ? (
    <Suspense fallback={null}>
      <Animation {...props} />
    </Suspense>
  ) : null
}
