'use client'

import { useSession } from 'next-auth/react'
import SignInPage from './SignInPage'

export default function AuthGuard({ children }: { children: React.ReactNode }) {
  const { status } = useSession()

  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--ff-bg)]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-4 border-[var(--ff-brand)] border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-[var(--ff-text-muted)]">Loading FeatureForge…</p>
        </div>
      </div>
    )
  }

  if (status === 'unauthenticated') {
    return <SignInPage />
  }

  return <>{children}</>
}
