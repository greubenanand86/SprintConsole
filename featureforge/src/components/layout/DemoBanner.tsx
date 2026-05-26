'use client'

import { useSession } from 'next-auth/react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faFlask } from '@fortawesome/free-solid-svg-icons'

export default function DemoBanner() {
  const { data: session } = useSession()
  const isDemo = (session?.user as { isDemo?: boolean })?.isDemo

  if (!isDemo) return null

  return (
    <div className="bg-amber-500 text-white px-4 py-2 flex items-center justify-center gap-2 text-xs font-semibold">
      <FontAwesomeIcon icon={faFlask} className="w-3.5 h-3.5" />
      Demo mode — AI generation is live but credits reset on reload. Sign in with Google for a persistent account.
    </div>
  )
}
