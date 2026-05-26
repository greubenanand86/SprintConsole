import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import AppShell from '@/components/layout/AppShell'
import { getOrCreateBalance } from '@/lib/credits'
import { CREDIT_COSTS, GENERATION_LABELS } from '@/types'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faChartSimple, faBoltLightning } from '@fortawesome/free-solid-svg-icons'

export default async function UsagePage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/')

  const userId = (session.user as { id?: string }).id ?? session.user.email ?? 'unknown'
  const balance = getOrCreateBalance(userId)

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[var(--ff-surface-alt)] rounded-xl flex items-center justify-center">
            <FontAwesomeIcon icon={faChartSimple} className="w-5 h-5 text-[var(--ff-text-muted)]" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-[var(--ff-text)]">Usage</h1>
            <p className="text-sm text-[var(--ff-text-muted)]">Credit consumption and pricing reference.</p>
          </div>
        </div>

        {/* Summary */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Total credits', value: balance.total },
            { label: 'Credits used', value: balance.used },
            { label: 'Credits remaining', value: balance.remaining },
          ].map(({ label, value }) => (
            <div key={label} className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-xl p-4 text-center">
              <p className="text-2xl font-bold text-[var(--ff-brand)]">{value}</p>
              <p className="text-xs text-[var(--ff-text-muted)] mt-1">{label}</p>
            </div>
          ))}
        </div>

        {/* Credit cost table */}
        <section className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl overflow-hidden">
          <div className="px-6 py-4 border-b border-[var(--ff-border)]">
            <h2 className="font-semibold text-[var(--ff-text)]">Credit costs per generation</h2>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-[var(--ff-surface-alt)]">
                <th className="px-6 py-3 text-left font-medium text-[var(--ff-text-muted)]">Generation type</th>
                <th className="px-6 py-3 text-right font-medium text-[var(--ff-text-muted)]">Credits</th>
              </tr>
            </thead>
            <tbody>
              {(Object.entries(CREDIT_COSTS) as [keyof typeof CREDIT_COSTS, number][]).map(([type, cost]) => (
                <tr key={type} className="border-t border-[var(--ff-border)] hover:bg-[var(--ff-surface-alt)] transition-colors">
                  <td className="px-6 py-3 text-[var(--ff-text)]">{GENERATION_LABELS[type]}</td>
                  <td className="px-6 py-3 text-right">
                    <span className="inline-flex items-center gap-1 font-semibold text-[var(--ff-brand)]">
                      <FontAwesomeIcon icon={faBoltLightning} className="w-3 h-3" />
                      {cost}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="px-6 py-4 border-t border-[var(--ff-border)] bg-[var(--ff-surface-alt)]">
            <p className="text-xs text-[var(--ff-text-muted)]">
              Regenerating an output costs the same credits as the original generation.
              Full Package includes all output types in a single generation.
            </p>
          </div>
        </section>
      </div>
    </AppShell>
  )
}
