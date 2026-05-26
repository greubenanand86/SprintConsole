'use client'

import { SessionProvider } from 'next-auth/react'
import { ThemeProvider } from 'next-themes'
import { PrimeReactProvider } from 'primereact/api'
import PrimeReactThemeSwitcher from '../theme/PrimeReactThemeSwitcher'

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider>
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange={false}>
        <PrimeReactProvider value={{ ripple: true, inputStyle: 'outlined' }}>
          <PrimeReactThemeSwitcher />
          {children}
        </PrimeReactProvider>
      </ThemeProvider>
    </SessionProvider>
  )
}
