'use client'

import { signIn } from 'next-auth/react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faBolt, faWandMagicSparkles, faCheckCircle, faBoltLightning } from '@fortawesome/free-solid-svg-icons'
import { faGoogle } from '@fortawesome/free-brands-svg-icons'
import ThemeToggle from '@/components/theme/ThemeToggle'

const FEATURES = [
  "Gap checks that identify what's missing before you start building",
  'Full PRDs written in seconds, not hours',
  'Jira-style tickets ready to paste into your board',
  'QA test cases your team will actually use',
  'Multi-provider AI: Claude, GPT-4, and Gemini',
]

export default function SignInPage() {
  return (
    <div className="min-h-screen bg-[var(--ff-bg)] flex flex-col">
      {/* Top bar */}
      <header className="h-14 flex items-center justify-between px-6 border-b border-[var(--ff-border)] bg-[var(--ff-surface)]">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 bg-[var(--ff-brand)] rounded-lg flex items-center justify-center">
            <FontAwesomeIcon icon={faBolt} className="text-white w-3.5 h-3.5" />
          </div>
          <span className="font-bold text-[var(--ff-text)] tracking-tight text-lg">
            Feature<span className="text-[var(--ff-brand)]">Forge</span>
          </span>
        </div>
        <ThemeToggle />
      </header>

      {/* Main */}
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">

          {/* Left — value prop */}
          <div className="space-y-6">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-[var(--ff-brand-light)] border border-[var(--ff-brand)] text-[var(--ff-brand)] text-xs font-semibold">
                <FontAwesomeIcon icon={faBoltLightning} className="w-3 h-3" />
                AI-powered spec generation
              </div>
              <h1 className="text-4xl font-bold text-[var(--ff-text)] leading-tight">
                Turn messy ideas into{' '}
                <span className="text-[var(--ff-brand)]">production-ready specs</span>
              </h1>
              <p className="text-lg text-[var(--ff-text-muted)] leading-relaxed">
                FeatureForge converts rough feature descriptions into PRDs, Jira tickets,
                acceptance criteria, edge cases, and QA test cases — in seconds.
              </p>
            </div>

            <ul className="space-y-3">
              {FEATURES.map((f) => (
                <li key={f} className="flex items-start gap-3">
                  <FontAwesomeIcon icon={faCheckCircle} className="w-4 h-4 text-green-500 shrink-0 mt-0.5" />
                  <span className="text-sm text-[var(--ff-text-muted)]">{f}</span>
                </li>
              ))}
            </ul>

            <div className="flex flex-wrap gap-6 text-center">
              {[['10', 'free credits to start'], ['7', 'output types'], ['3', 'AI providers']].map(([n, l]) => (
                <div key={l}>
                  <p className="text-2xl font-bold text-[var(--ff-brand)]">{n}</p>
                  <p className="text-xs text-[var(--ff-text-muted)]">{l}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Right — sign in card */}
          <div className="
            bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl
            p-8 shadow-lg space-y-6
          ">
            <div className="text-center space-y-1">
              <div className="w-14 h-14 bg-[var(--ff-brand-light)] rounded-2xl flex items-center justify-center mx-auto mb-4">
                <FontAwesomeIcon icon={faWandMagicSparkles} className="w-7 h-7 text-[var(--ff-brand)]" />
              </div>
              <h2 className="text-xl font-bold text-[var(--ff-text)]">Get started free</h2>
              <p className="text-sm text-[var(--ff-text-muted)]">
                10 credits included · No credit card required
              </p>
            </div>

            <button
              onClick={() => signIn('google', { callbackUrl: '/dashboard' })}
              className="
                w-full flex items-center justify-center gap-3 px-5 py-3.5 rounded-xl
                bg-white dark:bg-[var(--ff-surface-alt)]
                border border-[var(--ff-border)] shadow-sm
                text-[var(--ff-text)] font-semibold text-sm
                hover:border-[var(--ff-brand)] hover:shadow-md transition-all duration-200
                focus:outline-none focus:ring-2 focus:ring-[var(--ff-brand)]
              "
            >
              <FontAwesomeIcon icon={faGoogle} className="w-4 h-4 text-[#4285F4]" />
              Continue with Google
            </button>

            <div className="space-y-3 pt-2 border-t border-[var(--ff-border)]">
              <p className="text-xs font-semibold text-[var(--ff-text-muted)] uppercase tracking-wide">Pricing</p>
              <div className="space-y-2 text-sm">
                {[
                  ['Free', '10 credits', '$0'],
                  ['Starter', '50 credits', '$9 one-time'],
                  ['Pro', '150 credits/mo', '$19/mo'],
                  ['Team', '500 credits/mo', '$49/mo'],
                ].map(([plan, credits, price]) => (
                  <div key={plan} className="flex items-center justify-between text-[var(--ff-text-muted)]">
                    <span className="font-medium text-[var(--ff-text)]">{plan}</span>
                    <span>{credits}</span>
                    <span className="font-semibold text-[var(--ff-brand)]">{price}</span>
                  </div>
                ))}
              </div>
            </div>

            <p className="text-xs text-center text-[var(--ff-text-muted)]">
              By signing in you agree to our terms of service and privacy policy.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
