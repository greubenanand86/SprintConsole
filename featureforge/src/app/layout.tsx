import type { Metadata } from 'next'
import './globals.css'
import 'primeicons/primeicons.css'
import Providers from '@/components/providers/Providers'
import { config } from '@fortawesome/fontawesome-svg-core'
import '@fortawesome/fontawesome-svg-core/styles.css'
config.autoAddCss = false

export const metadata: Metadata = {
  title: 'FeatureForge — AI Spec Generator',
  description: 'Turn rough feature ideas into PRDs, tickets, acceptance criteria, and QA test cases in seconds.',
  icons: { icon: '/favicon.ico' },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
