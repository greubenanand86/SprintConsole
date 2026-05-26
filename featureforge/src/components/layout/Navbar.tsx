'use client'

import { useSession, signOut } from 'next-auth/react'
import Image from 'next/image'
import ThemeToggle from '@/components/theme/ThemeToggle'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faChevronDown, faRightFromBracket } from '@fortawesome/free-solid-svg-icons'
import { faBolt } from '@fortawesome/free-solid-svg-icons'
import { useState } from 'react'
import CreditBadge from '@/components/generate/CreditBadge'

export default function Navbar() {
  const { data: session } = useSession()
  const [open, setOpen] = useState(false)

  return (
    <header className="
      h-14 flex items-center justify-between px-6
      bg-[var(--ff-surface)] border-b border-[var(--ff-border)]
      sticky top-0 z-40
    ">
      {/* Logo */}
      <div className="flex items-center gap-2">
        <div className="w-7 h-7 bg-[var(--ff-brand)] rounded-lg flex items-center justify-center">
          <FontAwesomeIcon icon={faBolt} className="text-white w-3.5 h-3.5" />
        </div>
        <span className="font-bold text-[var(--ff-text)] tracking-tight text-lg">
          Feature<span className="text-[var(--ff-brand)]">Forge</span>
        </span>
      </div>

      {/* Right */}
      <div className="flex items-center gap-3">
        <CreditBadge />
        <ThemeToggle />

        {/* User menu */}
        {session?.user && (
          <div className="relative">
            <button
              onClick={() => setOpen((o) => !o)}
              aria-label="User menu"
              aria-expanded={open}
              className="
                flex items-center gap-2 px-2.5 py-1.5 rounded-lg
                bg-[var(--ff-surface-alt)] border border-[var(--ff-border)]
                hover:border-[var(--ff-brand)] transition-all duration-150
                focus:outline-none focus:ring-2 focus:ring-[var(--ff-brand)]
              "
            >
              {session.user.image ? (
                <Image
                  src={session.user.image}
                  alt={session.user.name ?? 'User'}
                  width={24}
                  height={24}
                  className="rounded-full"
                />
              ) : (
                <div className="w-6 h-6 rounded-full bg-[var(--ff-brand)] flex items-center justify-center text-white text-xs font-bold">
                  {session.user.name?.[0] ?? 'U'}
                </div>
              )}
              <span className="text-sm font-medium text-[var(--ff-text)] hidden sm:block max-w-28 truncate">
                {session.user.name}
              </span>
              <FontAwesomeIcon icon={faChevronDown} className="w-3 h-3 text-[var(--ff-text-muted)]" />
            </button>

            {open && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
                <div className="
                  absolute right-0 top-full mt-2 w-52 z-20
                  bg-[var(--ff-surface)] border border-[var(--ff-border)]
                  rounded-xl shadow-lg overflow-hidden animate-fade-in
                ">
                  <div className="px-4 py-3 border-b border-[var(--ff-border)]">
                    <p className="text-sm font-semibold text-[var(--ff-text)] truncate">{session.user.name}</p>
                    <p className="text-xs text-[var(--ff-text-muted)] truncate">{session.user.email}</p>
                  </div>
                  <button
                    onClick={() => signOut({ callbackUrl: '/' })}
                    className="
                      w-full flex items-center gap-3 px-4 py-3 text-sm
                      text-[var(--ff-text-muted)] hover:text-[var(--ff-danger)]
                      hover:bg-[var(--ff-surface-alt)] transition-colors text-left
                    "
                  >
                    <FontAwesomeIcon icon={faRightFromBracket} className="w-4 h-4" />
                    Sign out
                  </button>
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </header>
  )
}
