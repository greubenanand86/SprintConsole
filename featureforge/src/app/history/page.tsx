import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import AppShell from '@/components/layout/AppShell'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faClockRotateLeft, faWandMagicSparkles } from '@fortawesome/free-solid-svg-icons'
import Link from 'next/link'

export default async function HistoryPage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/')

  return (
    <AppShell>
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[var(--ff-surface-alt)] rounded-xl flex items-center justify-center">
            <FontAwesomeIcon icon={faClockRotateLeft} className="w-5 h-5 text-[var(--ff-text-muted)]" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-[var(--ff-text)]">Generation History</h1>
            <p className="text-sm text-[var(--ff-text-muted)]">Your past generations.</p>
          </div>
        </div>

        {/* Empty state — history persistence requires a database (post-MVP) */}
        <div className="
          bg-[var(--ff-surface)] border border-[var(--ff-border)] rounded-2xl
          p-12 flex flex-col items-center text-center space-y-4
        ">
          <div className="w-16 h-16 bg-[var(--ff-surface-alt)] rounded-2xl flex items-center justify-center">
            <FontAwesomeIcon icon={faClockRotateLeft} className="w-8 h-8 text-[var(--ff-text-muted)]" />
          </div>
          <div>
            <h3 className="font-semibold text-[var(--ff-text)]">No history yet</h3>
            <p className="text-sm text-[var(--ff-text-muted)] mt-1 max-w-xs">
              Generation history will be persisted here once database storage is connected.
              For now, use copy or export immediately after generating.
            </p>
          </div>
          <Link
            href="/generate"
            className="
              inline-flex items-center gap-2 px-5 py-2.5 rounded-xl
              bg-[var(--ff-brand)] text-white font-semibold text-sm
              hover:bg-[var(--ff-brand-dark)] transition-colors
            "
          >
            <FontAwesomeIcon icon={faWandMagicSparkles} className="w-4 h-4" />
            Generate your first spec
          </Link>
        </div>
      </div>
    </AppShell>
  )
}
