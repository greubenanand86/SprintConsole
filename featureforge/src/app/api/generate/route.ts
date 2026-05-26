import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { v4 as uuidv4 } from 'uuid'
import { authOptions } from '@/lib/auth'
import { generate } from '@/lib/ai'
import { buildPrompt } from '@/lib/prompts'
import { checkCredits, deductCredits } from '@/lib/credits'
import { GenerationRequest, AIProvider, GenerationType } from '@/types'

const VALID_PROVIDERS: AIProvider[] = ['anthropic', 'openai', 'gemini']
const VALID_TYPES: GenerationType[] = [
  'gap-check', 'prd', 'tickets', 'acceptance-criteria',
  'edge-cases', 'qa-tests', 'full-package',
]

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const userId = (session.user as { id?: string }).id ?? session.user.email ?? 'unknown'

  let body: GenerationRequest
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request body.' }, { status: 400 })
  }

  const { type, provider, idea, context } = body

  if (!VALID_TYPES.includes(type)) {
    return NextResponse.json({ error: 'Invalid generation type.' }, { status: 400 })
  }
  if (!VALID_PROVIDERS.includes(provider)) {
    return NextResponse.json({ error: 'Invalid provider.' }, { status: 400 })
  }
  if (!idea || typeof idea !== 'string' || idea.trim().length < 10) {
    return NextResponse.json({ error: 'Feature idea is too short. Please provide more detail.' }, { status: 400 })
  }
  if (idea.length > 3000) {
    return NextResponse.json({ error: 'Feature idea exceeds 3000 character limit.' }, { status: 400 })
  }

  if (!checkCredits(userId, type)) {
    return NextResponse.json({ error: 'Insufficient credits. Please upgrade your plan.' }, { status: 402 })
  }

  const prompt = buildPrompt(type, idea.trim(), context?.trim())

  const start = Date.now()
  let result: Awaited<ReturnType<typeof generate>>
  try {
    result = await generate(provider, type, prompt)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'AI generation failed.'
    return NextResponse.json({ error: message }, { status: 502 })
  }

  const durationMs = Date.now() - start
  const balance = deductCredits(userId, type)

  return NextResponse.json({
    generationId: uuidv4(),
    output: result.text,
    tokensIn: result.tokensIn,
    tokensOut: result.tokensOut,
    durationMs,
    creditsUsed: balance.used,
    creditsRemaining: balance.remaining,
    provider,
    type,
  })
}
