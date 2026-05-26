'use client'

import { useState, useEffect } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faWandMagicSparkles, faBoltLightning, faChevronDown,
  faCircleInfo, faTriangleExclamation,
} from '@fortawesome/free-solid-svg-icons'
import {
  GenerationType, AIProvider, GENERATION_LABELS, CREDIT_COSTS,
  GENERATION_DESCRIPTIONS, ProviderConfig, GENERATION_COST_RISK,
} from '@/types'
import type { GenerationResult } from '@/types'
import clsx from 'clsx'

const GENERATION_TYPES: GenerationType[] = [
  'gap-check', 'prd', 'tickets', 'acceptance-criteria',
  'edge-cases', 'qa-tests', 'full-package',
]

const COST_RISK_COLORS = {
  low:    'text-green-600 dark:text-green-400',
  medium: 'text-amber-600 dark:text-amber-400',
  high:   'text-red-600 dark:text-red-400',
}

interface Props {
  onResult: (result: GenerationResult) => void
  creditsRemaining: number
}

export default function GenerateForm({ onResult, creditsRemaining }: Props) {
  const [type, setType] = useState<GenerationType>('gap-check')
  const [provider, setProvider] = useState<AIProvider>('anthropic')
  const [idea, setIdea] = useState('')
  const [context, setContext] = useState('')
  const [providers, setProviders] = useState<ProviderConfig[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [showContext, setShowContext] = useState(false)

  useEffect(() => {
    fetch('/api/providers')
      .then((r) => r.json())
      .then((data: ProviderConfig[]) => {
        setProviders(data)
        const first = data.find((p) => p.available)
        if (first) setProvider(first.id)
      })
      .catch(() => null)
  }, [])

  const cost = CREDIT_COSTS[type]
  const canGenerate = creditsRemaining >= cost && idea.trim().length >= 10 && !loading

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const res = await fetch('/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type, provider, idea: idea.trim(), context: context.trim() }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? 'Generation failed. Please try again.')
        return
      }

      onResult(data as GenerationResult)
    } catch {
      setError('Network error. Please check your connection and try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {/* Generation type */}
      <fieldset>
        <legend className="block text-sm font-semibold text-[var(--ff-text)] mb-2">
          What do you want to generate?
        </legend>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
          {GENERATION_TYPES.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setType(t)}
              aria-pressed={type === t}
              className={clsx(
                'relative flex flex-col gap-1 px-3 py-2.5 rounded-xl border text-left transition-all duration-150 text-sm',
                type === t
                  ? 'border-[var(--ff-brand)] bg-[var(--ff-brand-light)] text-[var(--ff-brand)]'
                  : 'border-[var(--ff-border)] bg-[var(--ff-surface)] text-[var(--ff-text)] hover:border-[var(--ff-brand)]',
              )}
            >
              <span className="font-semibold">{GENERATION_LABELS[t]}</span>
              <span className={clsx('text-xs font-medium', COST_RISK_COLORS[GENERATION_COST_RISK[t]])}>
                {CREDIT_COSTS[t]} credit{CREDIT_COSTS[t] !== 1 ? 's' : ''}
              </span>
              {t === 'full-package' && (
                <span className="absolute -top-1.5 -right-1.5 bg-[var(--ff-brand)] text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                  ALL
                </span>
              )}
            </button>
          ))}
        </div>
        <p className="mt-2 text-xs text-[var(--ff-text-muted)]">
          {GENERATION_DESCRIPTIONS[type]}
        </p>
      </fieldset>

      {/* AI Provider */}
      <div>
        <label className="block text-sm font-semibold text-[var(--ff-text)] mb-2">
          AI Provider
        </label>
        <div className="flex flex-wrap gap-2">
          {providers.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => p.available && setProvider(p.id)}
              disabled={!p.available}
              aria-pressed={provider === p.id}
              title={p.available ? p.description : 'Not configured — add API key to .env'}
              className={clsx(
                'px-3 py-2 rounded-lg border text-sm font-medium transition-all duration-150',
                !p.available && 'opacity-40 cursor-not-allowed',
                p.available && provider === p.id
                  ? 'border-[var(--ff-brand)] bg-[var(--ff-brand-light)] text-[var(--ff-brand)]'
                  : p.available
                    ? 'border-[var(--ff-border)] bg-[var(--ff-surface)] text-[var(--ff-text)] hover:border-[var(--ff-brand)]'
                    : 'border-[var(--ff-border)] bg-[var(--ff-surface-alt)] text-[var(--ff-text-muted)]',
              )}
            >
              {p.label}
              {!p.available && <span className="ml-1.5 text-xs opacity-60">(not configured)</span>}
            </button>
          ))}
        </div>
      </div>

      {/* Idea input */}
      <div>
        <label htmlFor="idea" className="block text-sm font-semibold text-[var(--ff-text)] mb-2">
          Feature idea <span className="text-[var(--ff-danger)]">*</span>
        </label>
        <textarea
          id="idea"
          value={idea}
          onChange={(e) => setIdea(e.target.value)}
          placeholder="Describe your feature idea in plain language. The more detail you provide, the better the output.&#10;&#10;Example: I want users to be able to invite teammates by email, set their role (viewer/editor/admin), and have the invitee receive an email with a signup link."
          rows={5}
          maxLength={3000}
          required
          className="
            w-full px-4 py-3 rounded-xl text-sm
            bg-[var(--ff-surface)] border border-[var(--ff-border)]
            text-[var(--ff-text)] placeholder:text-[var(--ff-text-muted)]
            focus:outline-none focus:ring-2 focus:ring-[var(--ff-brand)] focus:border-[var(--ff-brand)]
            resize-none transition-all
          "
        />
        <div className="flex justify-between mt-1">
          <span className="text-xs text-[var(--ff-text-muted)]">Min 10 characters</span>
          <span className={clsx('text-xs', idea.length > 2700 ? 'text-amber-500' : 'text-[var(--ff-text-muted)]')}>
            {idea.length}/3000
          </span>
        </div>
      </div>

      {/* Optional context */}
      <div>
        <button
          type="button"
          onClick={() => setShowContext((s) => !s)}
          className="flex items-center gap-1.5 text-xs text-[var(--ff-text-muted)] hover:text-[var(--ff-brand)] transition-colors"
        >
          <FontAwesomeIcon icon={faChevronDown} className={clsx('w-3 h-3 transition-transform', showContext && 'rotate-180')} />
          {showContext ? 'Hide' : 'Add'} additional context (optional)
        </button>

        {showContext && (
          <textarea
            value={context}
            onChange={(e) => setContext(e.target.value)}
            placeholder="Tech stack, existing constraints, target users, any decisions already made..."
            rows={3}
            maxLength={1000}
            className="
              mt-2 w-full px-4 py-3 rounded-xl text-sm
              bg-[var(--ff-surface)] border border-[var(--ff-border)]
              text-[var(--ff-text)] placeholder:text-[var(--ff-text-muted)]
              focus:outline-none focus:ring-2 focus:ring-[var(--ff-brand)] focus:border-[var(--ff-brand)]
              resize-none transition-all
            "
          />
        )}
      </div>

      {/* Credit summary */}
      <div className="flex items-center gap-2 p-3 rounded-lg bg-[var(--ff-surface-alt)] border border-[var(--ff-border)]">
        <FontAwesomeIcon icon={faCircleInfo} className="w-4 h-4 text-[var(--ff-text-muted)] shrink-0" />
        <span className="text-sm text-[var(--ff-text-muted)]">
          This generation costs{' '}
          <strong className="text-[var(--ff-text)]">{cost} credit{cost !== 1 ? 's' : ''}</strong>
          {' '}· You have{' '}
          <strong className={creditsRemaining <= 2 ? 'text-red-500' : 'text-[var(--ff-brand)]'}>
            {creditsRemaining}
          </strong>{' '}remaining
        </span>
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-start gap-2 p-3 rounded-lg bg-red-50 border border-red-200 dark:bg-red-950 dark:border-red-800">
          <FontAwesomeIcon icon={faTriangleExclamation} className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}

      {/* Submit */}
      <button
        type="submit"
        disabled={!canGenerate}
        className={clsx(
          'w-full flex items-center justify-center gap-2.5 px-6 py-3 rounded-xl font-semibold text-sm transition-all duration-200',
          canGenerate
            ? 'bg-[var(--ff-brand)] hover:bg-[var(--ff-brand-dark)] text-white shadow-md hover:shadow-lg'
            : 'bg-[var(--ff-surface-alt)] text-[var(--ff-text-muted)] cursor-not-allowed border border-[var(--ff-border)]',
        )}
      >
        {loading ? (
          <>
            <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
            </svg>
            Generating…
          </>
        ) : (
          <>
            <FontAwesomeIcon icon={faWandMagicSparkles} className="w-4 h-4" />
            Generate {GENERATION_LABELS[type]}
            <span className="flex items-center gap-1 text-xs opacity-80">
              <FontAwesomeIcon icon={faBoltLightning} className="w-3 h-3" />
              {cost}
            </span>
          </>
        )}
      </button>
    </form>
  )
}
