import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { getOrCreateBalance } from '@/lib/credits'

export async function GET() {
  const session = await getServerSession(authOptions)
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const userId = (session.user as { id?: string }).id ?? session.user.email ?? 'unknown'
  const balance = getOrCreateBalance(userId)

  return NextResponse.json(balance)
}
