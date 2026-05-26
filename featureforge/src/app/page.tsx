import AuthGuard from '@/components/auth/AuthGuard'
import { redirect } from 'next/navigation'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export default async function HomePage() {
  const session = await getServerSession(authOptions)
  if (session) redirect('/dashboard')

  return <AuthGuard><div /></AuthGuard>
}
