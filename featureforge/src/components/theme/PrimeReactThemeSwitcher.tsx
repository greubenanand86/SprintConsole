'use client'

import { useTheme } from 'next-themes'
import { useEffect } from 'react'

const LIGHT_THEME = '/themes/lara-light-indigo/theme.css'
const DARK_THEME  = '/themes/lara-dark-indigo/theme.css'
const LINK_ID = 'primereact-theme'

export default function PrimeReactThemeSwitcher() {
  const { resolvedTheme } = useTheme()

  useEffect(() => {
    let link = document.getElementById(LINK_ID) as HTMLLinkElement | null
    if (!link) {
      link = document.createElement('link')
      link.id = LINK_ID
      link.rel = 'stylesheet'
      document.head.appendChild(link)
    }
    link.href = resolvedTheme === 'dark' ? DARK_THEME : LIGHT_THEME
  }, [resolvedTheme])

  return null
}
