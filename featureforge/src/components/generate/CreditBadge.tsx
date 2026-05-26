'use client'

import { useEffect, useState } from 'react'
import { useSession } from 'next-auth/react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faBoltLightning } from '@fortawesome/free-solid-svg-icons'
import type { CreditBalance } from '@/types'

export default function CreditBadge() {
  const { data: session } = useSession()
  const [balance, setBalance] = useState<CreditBalance | null>(null)

  useEffect(() => {
    if (!session) return
    fetch('/api/credits')
      .then((r) => r.json())
      .then(setBalance)
      .catch(() => null)
  }, [session])

  if (!session || !balance) return null

  const pct = (balance.remaining / balance.total) * 100
  const low = balance.remaining <= 2

  return (
    <div
      className={`
        flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold
        border transition-colors
        ${low
          ? 'bg-red-50 border-red-200 text-red-600 dark:bg-red-950 dark:border-red-800 dark:text-red-400'
          : 'bg-[var(--ff-brand-light)] border-[var(--ff-brand)] text-[var(--ff-brand)]'
        }
      `}
      title={`${balance.remaining} of ${balance.total} credits remaining`}
    >
      <FontAwesomeIcon icon={faBoltLightning} className="w-3 h-3" />
      <span>{balance.remaining} credits</span>
      {pct < 30 && <span className="opacity-60">· {balance.plan}</span>}
    </div>
  )
}
