import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import AppShell from '@/components/layout/AppShell'
import { getOrCreateBalance } from '@/lib/credits'
import { getAvailableProviders } from '@/lib/ai'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faGear, faCheck, faXmark } from '@fortawesome/free-solid-svg-icons'
import { PLAN_LABELS, PLAN_CREDITS } from '@/types'

export default async function SettingsPage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/')

  const userId = (session.user as { id?: string }).id ?? session.user.email ?? 'unknown'
  const balance = getOrCreateBalance(userId)
  const providers = getAvailableProviders()

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[var(--ff-surface-alt)] rounded-xl flex items-center justify-center">
            <FontAwesomeIcon icon={faGear} className="w-5 h-5 text-[var(--ff-text-muted)]" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-[var(--ff-text)]">Settings</h1>
            <p className="text-sm text-[var(--ff-text-muted)]">Account, plan, and provider configuration.</p>
          </div>
        </div>

        {/* Account */}
        <section className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl p-6 space-y-4">
          <h2 className="font-semibold text-[var(--ff-text)]">Account</h2>
          <div className="flex items-center gap-4">
            {session.user.image && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={session.user.image} alt="" className="w-12 h-12 rounded-full" />
            )}
            <div>
              <p className="font-medium text-[var(--ff-text)]">{session.user.name}</p>
              <p className="text-sm text-[var(--ff-text-muted)]">{session.user.email}</p>
            </div>
          </div>
        </section>

        {/* Plan */}
        <section className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl p-6 space-y-4">
          <h2 className="font-semibold text-[var(--ff-text)]">Plan & Credits</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {(['free', 'starter', 'pro', 'team'] as const).map((plan) => (
              <div
                key={plan}
                className={`
                  p-4 rounded-xl border text-center
                  ${balance.plan === plan
                    ? 'border-[var(--ff-brand)] bg-[var(--ff-brand-light)]'
                    : 'border-[var(--ff-border)] bg-[var(--ff-surface-alt)]'
                  }
                `}
              >
                <p className={`text-sm font-bold ${balance.plan === plan ? 'text-[var(--ff-brand)]' : 'text-[var(--ff-text)]'}`}>
                  {PLAN_LABELS[plan]}
                </p>
                <p className="text-xs text-[var(--ff-text-muted)] mt-1">{PLAN_CREDITS[plan]} credits</p>
                {balance.plan === plan && (
                  <span className="text-xs text-[var(--ff-brand)] font-semibold">Current</span>
                )}
              </div>
            ))}
          </div>
          <p className="text-xs text-[var(--ff-text-muted)]">
            Billing and plan upgrades will be available in a future release. Credits are managed server-side.
          </p>
        </section>

        {/* Providers */}
        <section className="bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl p-6 space-y-4">
          <h2 className="font-semibold text-[var(--ff-text)]">AI Providers</h2>
          <p className="text-sm text-[var(--ff-text-muted)]">
            Providers are configured via server environment variables. Contact your administrator to enable additional providers.
          </p>
          <div className="space-y-3">
            {providers.map((p) => (
              <div
                key={p.id}
                className="flex items-center justify-between py-3 border-b border-[var(--ff-border)] last:border-0"
              >
                <div>
                  <p className="text-sm font-medium text-[var(--ff-text)]">{p.label}</p>
                  <p className="text-xs text-[var(--ff-text-muted)]">{p.description}</p>
                </div>
                <div className={`flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
                  p.available
                    ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
                    : 'bg-[var(--ff-surface-alt)] text-[var(--ff-text-muted)]'
                }`}>
                  <FontAwesomeIcon icon={p.available ? faCheck : faXmark} className="w-3 h-3" />
                  {p.available ? 'Active' : 'Not configured'}
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </AppShell>
  )
}
