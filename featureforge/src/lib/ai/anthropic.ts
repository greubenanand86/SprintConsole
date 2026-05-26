import Anthropic from '@anthropic-ai/sdk'
import { GenerationType, FAST_GENERATION_TYPES, PROVIDER_CONFIGS } from '@/types'
import { getOutputMaxTokens } from '@/lib/prompts'

let client: Anthropic | null = null

function getClient(): Anthropic {
  if (!client) {
    const apiKey = process.env.ANTHROPIC_API_KEY
    if (!apiKey) throw new Error('ANTHROPIC_API_KEY is not configured.')
    client = new Anthropic({ apiKey })
  }
  return client
}

export async function generateWithAnthropic(
  type: GenerationType,
  prompt: string,
): Promise<{ text: string; tokensIn: number; tokensOut: number }> {
  const anthropic = getClient()
  const isFast = FAST_GENERATION_TYPES.includes(type)
  const model = isFast
    ? PROVIDER_CONFIGS.anthropic.fastModel
    : PROVIDER_CONFIGS.anthropic.powerfulModel

  const response = await anthropic.messages.create({
    model,
    max_tokens: getOutputMaxTokens(type),
    messages: [{ role: 'user', content: prompt }],
  })

  const text = response.content
    .filter((b) => b.type === 'text')
    .map((b) => (b as { type: 'text'; text: string }).text)
    .join('\n')

  return {
    text,
    tokensIn: response.usage.input_tokens,
    tokensOut: response.usage.output_tokens,
  }
}
