'use client'

import { useState } from 'react'
import ReactMarkdown from 'react-markdown'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faCopy, faCheck, faDownload, faChartBar,
  faWandMagicSparkles,
} from '@fortawesome/free-solid-svg-icons'
import { GenerationResult, GENERATION_LABELS } from '@/types'
import clsx from 'clsx'

interface Props {
  result: GenerationResult
  onClear: () => void
}

export default function OutputViewer({ result, onClear }: Props) {
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    await navigator.clipboard.writeText(result.output)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  function handleDownload(format: 'md' | 'txt') {
    const blob = new Blob([result.output], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `featureforge-${result.provider}-${Date.now()}.${format}`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-4 animate-slide-up">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
            <FontAwesomeIcon icon={faWandMagicSparkles} className="w-4 h-4 text-green-600 dark:text-green-400" />
          </div>
          <div>
            <h3 className="text-sm font-semibold text-[var(--ff-text)]">
              {GENERATION_LABELS[result.type as keyof typeof GENERATION_LABELS]} Generated
            </h3>
            <p className="text-xs text-[var(--ff-text-muted)]">
              via {result.provider} · {(result.durationMs / 1000).toFixed(1)}s
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleCopy}
            className="
              flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium
              bg-[var(--ff-surface-alt)] border border-[var(--ff-border)]
              text-[var(--ff-text-muted)] hover:text-[var(--ff-brand)] hover:border-[var(--ff-brand)]
              transition-all duration-150
            "
          >
            <FontAwesomeIcon icon={copied ? faCheck : faCopy} className="w-3.5 h-3.5" />
            {copied ? 'Copied!' : 'Copy'}
          </button>

          <div className="relative group">
            <button
              className="
                flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium
                bg-[var(--ff-surface-alt)] border border-[var(--ff-border)]
                text-[var(--ff-text-muted)] hover:text-[var(--ff-brand)] hover:border-[var(--ff-brand)]
                transition-all duration-150
              "
            >
              <FontAwesomeIcon icon={faDownload} className="w-3.5 h-3.5" />
              Export
            </button>
            <div className="
              absolute right-0 top-full mt-1 w-32 hidden group-hover:block
              bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-lg shadow-lg z-10
            ">
              <button
                onClick={() => handleDownload('md')}
                className="w-full px-3 py-2 text-xs text-left text-[var(--ff-text-muted)] hover:bg-[var(--ff-surface-alt)] hover:text-[var(--ff-text)] transition-colors"
              >
                Markdown (.md)
              </button>
              <button
                onClick={() => handleDownload('txt')}
                className="w-full px-3 py-2 text-xs text-left text-[var(--ff-text-muted)] hover:bg-[var(--ff-surface-alt)] hover:text-[var(--ff-text)] transition-colors"
              >
                Plain text (.txt)
              </button>
            </div>
          </div>

          <button
            onClick={onClear}
            className="
              px-3 py-1.5 rounded-lg text-xs font-medium
              border border-[var(--ff-border)] text-[var(--ff-text-muted)]
              hover:bg-[var(--ff-surface-alt)] transition-all duration-150
            "
          >
            New generation
          </button>
        </div>
      </div>

      {/* Stats bar */}
      <div className="flex flex-wrap gap-4 px-4 py-2.5 bg-[var(--ff-surface-alt)] border border-[var(--ff-border)] rounded-xl text-xs text-[var(--ff-text-muted)]">
        <span className="flex items-center gap-1.5">
          <FontAwesomeIcon icon={faChartBar} className="w-3.5 h-3.5" />
          <strong className="text-[var(--ff-text)]">{result.tokensIn.toLocaleString()}</strong> input tokens
        </span>
        <span>
          <strong className="text-[var(--ff-text)]">{result.tokensOut.toLocaleString()}</strong> output tokens
        </span>
        <span>
          <strong className="text-[var(--ff-text)]">{result.creditsUsed}</strong> credits used
        </span>
        <span>
          <strong className="text-[var(--ff-text)]">{(result.durationMs / 1000).toFixed(2)}s</strong> generation time
        </span>
      </div>

      {/* Output */}
      <div className="
        bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-xl
        p-6 overflow-auto max-h-[60vh]
      ">
        <article className="ff-output">
          <ReactMarkdown>{result.output}</ReactMarkdown>
        </article>
      </div>
    </div>
  )
}
