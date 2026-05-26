'use client'

import { useTheme } from 'next-themes'
import { useEffect, useState } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSun, faMoon } from '@fortawesome/free-solid-svg-icons'

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => setMounted(true), [])

  if (!mounted) {
    return (
      <div className="w-9 h-9 rounded-lg bg-[var(--ff-surface-alt)] animate-pulse" />
    )
  }

  const isDark = theme === 'dark'

  return (
    <button
      onClick={() => setTheme(isDark ? 'light' : 'dark')}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      className="
        w-9 h-9 flex items-center justify-center rounded-lg
        bg-[var(--ff-surface-alt)] border border-[var(--ff-border)]
        text-[var(--ff-text-muted)] hover:text-[var(--ff-brand)]
        hover:border-[var(--ff-brand)] transition-all duration-200
        focus:outline-none focus:ring-2 focus:ring-[var(--ff-brand)] focus:ring-offset-2
      "
    >
      <FontAwesomeIcon icon={isDark ? faSun : faMoon} className="w-4 h-4" />
    </button>
  )
}
