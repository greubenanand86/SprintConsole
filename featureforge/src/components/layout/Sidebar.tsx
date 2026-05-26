'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faHouse,
  faWandMagicSparkles,
  faClockRotateLeft,
  faGear,
  faChartSimple,
} from '@fortawesome/free-solid-svg-icons'
import { IconDefinition } from '@fortawesome/fontawesome-svg-core'
import clsx from 'clsx'

interface NavItem {
  label: string
  href: string
  icon: IconDefinition
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Dashboard',  href: '/dashboard', icon: faHouse },
  { label: 'Generate',   href: '/generate',  icon: faWandMagicSparkles },
  { label: 'History',    href: '/history',   icon: faClockRotateLeft },
  { label: 'Usage',      href: '/usage',     icon: faChartSimple },
  { label: 'Settings',   href: '/settings',  icon: faGear },
]

export default function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="
      w-[var(--ff-sidebar-width)] shrink-0
      bg-[var(--ff-surface)] border-r border-[var(--ff-border)]
      flex flex-col pt-4 pb-6 sticky top-14 h-[calc(100vh-3.5rem)]
    ">
      <nav className="flex-1 px-3 space-y-1">
        {NAV_ITEMS.map(({ label, href, icon }) => {
          const active = pathname.startsWith(href)
          return (
            <Link
              key={href}
              href={href}
              aria-current={active ? 'page' : undefined}
              className={clsx(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150',
                active
                  ? 'bg-[var(--ff-brand-light)] text-[var(--ff-brand)] dark:bg-[var(--ff-brand-light)]'
                  : 'text-[var(--ff-text-muted)] hover:bg-[var(--ff-surface-alt)] hover:text-[var(--ff-text)]',
              )}
            >
              <FontAwesomeIcon icon={icon} className="w-4 h-4 shrink-0" />
              {label}
            </Link>
          )
        })}
      </nav>

      <div className="px-4 text-xs text-[var(--ff-text-muted)] space-y-0.5">
        <p className="font-semibold text-[var(--ff-text)]">FeatureForge</p>
        <p>v0.1.0 · MVP</p>
      </div>
    </aside>
  )
}
