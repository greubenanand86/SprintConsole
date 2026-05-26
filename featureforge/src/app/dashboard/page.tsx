import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import { getOrCreateBalance } from '@/lib/credits'
import AppShell from '@/components/layout/AppShell'
import Link from 'next/link'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faWandMagicSparkles, faBoltLightning, faArrowRight,
  faFileLines, faTicket, faListCheck, faTriangleExclamation,
  faMagnifyingGlass, faBoxOpen,
} from '@fortawesome/free-solid-svg-icons'
import { CREDIT_COSTS, GENERATION_LABELS, PLAN_LABELS } from '@/types'

const QUICK_ACTIONS = [
  { type: 'gap-check',            icon: faMagnifyingGlass,   color: 'text-blue-500',   bg: 'bg-blue-50 dark:bg-blue-950' },
  { type: 'prd',                  icon: faFileLines,         color: 'text-purple-500', bg: 'bg-purple-50 dark:bg-purple-950' },
  { type: 'tickets',              icon: faTicket,            color: 'text-orange-500', bg: 'bg-orange-50 dark:bg-orange-950' },
  { type: 'acceptance-criteria',  icon: faListCheck,         color: 'text-green-500',  bg: 'bg-green-50 dark:bg-green-950' },
  { type: 'edge-cases',           icon: faTriangleExclamation, color: 'text-amber-500', bg: 'bg-amber-50 dark:bg-amber-950' },
  { type: 'full-package',         icon: faBoxOpen,           color: 'text-indigo-500', bg: 'bg-indigo-50 dark:bg-indigo-950' },
] as const

export default async function DashboardPage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/')

  const userId = (session.user as { id?: string }).id ?? session.user.email ?? 'unknown'
  const balance = getOrCreateBalance(userId)

  const pct = Math.round((balance.remaining / balance.total) * 100)

  return (
    <AppShell>
      <div className="max-w-4xl mx-auto space-y-8">
        {/* Welcome */}
        <div>
          <h1 className="text-2xl font-bold text-[var(--ff-text)]">
            Welcome back, {session.user.name?.split(' ')[0]} 👋
          </h1>
          <p className="text-[var(--ff-text-muted)] mt-1">
            Ready to forge some specs? Describe your feature idea and let AI do the heavy lifting.
          </p>
        </div>

        {/* Credit card */}
        <div className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm text-[var(--ff-text-muted)]">Credit balance</p>
              <div className="flex items-baseline gap-2 mt-1">
                <span className="text-3xl font-bold text-[var(--ff-text)]">{balance.remaining}</span>
                <span className="text-[var(--ff-text-muted)] text-sm">of {balance.total} credits</span>
              </div>
            </div>
            <div className="text-right">
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[var(--ff-brand-light)] text-[var(--ff-brand)] text-xs font-semibold">
                <FontAwesomeIcon icon={faBoltLightning} className="w-3 h-3" />
                {PLAN_LABELS[balance.plan]} Plan
              </span>
            </div>
          </div>

          {/* Progress bar */}
          <div className="w-full h-2 bg-[var(--ff-surface-alt)] rounded-full overflow-hidden">
            <div
              className={`h-full rounded-full transition-all duration-500 ${
                pct > 50 ? 'bg-[var(--ff-brand)]' : pct > 20 ? 'bg-amber-500' : 'bg-red-500'
              }`}
              style={{ width: `${pct}%` }}
            />
          </div>
          <p className="text-xs text-[var(--ff-text-muted)] mt-2">{pct}% remaining</p>

          {balance.remaining <= 3 && (
            <div className="mt-4 p-3 rounded-xl bg-amber-50 dark:bg-amber-950 border border-amber-200 dark:border-amber-800 text-sm text-amber-700 dark:text-amber-300">
              Running low. <strong>Upgrade your plan</strong> to keep generating specs.
            </div>
          )}
        </div>

        {/* Quick actions */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-[var(--ff-text)]">Quick generate</h2>
            <Link
              href="/generate"
              className="flex items-center gap-1.5 text-sm text-[var(--ff-brand)] hover:underline"
            >
              Open generator <FontAwesomeIcon icon={faArrowRight} className="w-3 h-3" />
            </Link>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {QUICK_ACTIONS.map(({ type, icon, color, bg }) => (
              <Link
                key={type}
                href={`/generate?type=${type}`}
                className="
                  flex items-center gap-3 p-4 rounded-xl
                  bg-[var(--ff-surface)] border border-[var(--ff-border)]
                  hover:border-[var(--ff-brand)] hover:shadow-sm
                  transition-all duration-150 group
                "
              >
                <div className={`w-9 h-9 rounded-lg ${bg} flex items-center justify-center shrink-0`}>
                  <FontAwesomeIcon icon={icon} className={`w-4 h-4 ${color}`} />
                </div>
                <div>
                  <p className="text-sm font-medium text-[var(--ff-text)] group-hover:text-[var(--ff-brand)] transition-colors">
                    {GENERATION_LABELS[type]}
                  </p>
                  <p className="text-xs text-[var(--ff-text-muted)]">
                    {CREDIT_COSTS[type]} credit{CREDIT_COSTS[type] !== 1 ? 's' : ''}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>

        {/* Start CTA */}
        <div className="
          bg-gradient-to-br from-indigo-600 to-purple-600
          rounded-2xl p-6 text-white text-center space-y-3
        ">
          <FontAwesomeIcon icon={faWandMagicSparkles} className="w-8 h-8 opacity-90" />
          <h3 className="text-xl font-bold">Ready to forge your first spec?</h3>
          <p className="text-indigo-100 text-sm">Describe your feature idea and get a complete spec package in seconds.</p>
          <Link
            href="/generate"
            className="
              inline-flex items-center gap-2 mt-2 px-6 py-2.5 rounded-xl
              bg-white text-indigo-600 font-semibold text-sm
              hover:bg-indigo-50 transition-colors
            "
          >
            Start generating <FontAwesomeIcon icon={faArrowRight} className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>
    </AppShell>
  )
}
