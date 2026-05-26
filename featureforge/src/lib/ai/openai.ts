import OpenAI from 'openai'
import { GenerationType, FAST_GENERATION_TYPES, PROVIDER_CONFIGS } from '@/types'
import { getOutputMaxTokens } from '@/lib/prompts'

let client: OpenAI | null = null

function getClient(): OpenAI {
  if (!client) {
    const apiKey = process.env.OPENAI_API_KEY
    if (!apiKey) throw new Error('OPENAI_API_KEY is not configured.')
    client = new OpenAI({ apiKey })
  }
  return client
}

export async function generateWithOpenAI(
  type: GenerationType,
  prompt: string,
): Promise<{ text: string; tokensIn: number; tokensOut: number }> {
  const openai = getClient()
  const isFast = FAST_GENERATION_TYPES.includes(type)
  const model = isFast
    ? PROVIDER_CONFIGS.openai.fastModel
    : PROVIDER_CONFIGS.openai.powerfulModel

  const response = await openai.chat.completions.create({
    model,
    max_tokens: getOutputMaxTokens(type),
    messages: [{ role: 'user', content: prompt }],
  })

  const text = response.choices[0]?.message?.content ?? ''

  return {
    text,
    tokensIn: response.usage?.prompt_tokens ?? 0,
    tokensOut: response.usage?.completion_tokens ?? 0,
  }
}
