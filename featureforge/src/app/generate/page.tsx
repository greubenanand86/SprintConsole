'use client'

import { Suspense, useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import AppShell from '@/components/layout/AppShell'
import GenerateForm from '@/components/generate/GenerateForm'
import OutputViewer from '@/components/generate/OutputViewer'
import { GenerationType, GenerationResult, CreditBalance } from '@/types'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faWandMagicSparkles } from '@fortawesome/free-solid-svg-icons'

function GenerateContent() {
  const { data: session, status } = useSession()
  const router = useRouter()
  const searchParams = useSearchParams()
  const presetType = searchParams.get('type') as GenerationType | null

  const [result, setResult] = useState<GenerationResult | null>(null)
  const [balance, setBalance] = useState<CreditBalance | null>(null)

  useEffect(() => {
    if (status === 'unauthenticated') router.push('/')
  }, [status, router])

  useEffect(() => {
    if (!session) return
    fetch('/api/credits')
      .then((r) => r.json())
      .then(setBalance)
      .catch(() => null)
  }, [session, result])

  if (status === 'loading' || !session) {
    return (
      <div className="flex items-center justify-center h-48">
        <div className="w-8 h-8 border-4 border-[var(--ff-brand)] border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <AppShell>
      <div className="max-w-3xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[var(--ff-brand-light)] rounded-xl flex items-center justify-center">
            <FontAwesomeIcon icon={faWandMagicSparkles} className="w-5 h-5 text-[var(--ff-brand)]" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-[var(--ff-text)]">Generate</h1>
            <p className="text-sm text-[var(--ff-text-muted)]">
              Describe your feature idea. FeatureForge handles the rest.
            </p>
          </div>
        </div>

        {/* Form or output */}
        <div className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl p-6">
          {result ? (
            <OutputViewer result={result} onClear={() => setResult(null)} />
          ) : (
            <GenerateForm
              onResult={(r) => setResult(r)}
              creditsRemaining={balance?.remaining ?? 10}
            />
          )}
        </div>

        {/* FinOps note */}
        {!result && (
          <p className="text-xs text-center text-[var(--ff-text-muted)]">
            Generations consume credits. Regenerating costs the same as the original generation.
            Credits are tied to your account and do not expire within the billing period.
          </p>
        )}
      </div>
    </AppShell>
  )
}

export default function GeneratePage() {
  return (
    <Suspense>
      <GenerateContent />
    </Suspense>
  )
}
