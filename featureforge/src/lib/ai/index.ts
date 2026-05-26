import { AIProvider, GenerationType, ProviderConfig, PROVIDER_CONFIGS } from '@/types'
import { generateWithAnthropic } from './anthropic'
import { generateWithOpenAI } from './openai'
import { generateWithGemini } from './gemini'

export interface GenerateOutput {
  text: string
  tokensIn: number
  tokensOut: number
}

export async function generate(
  provider: AIProvider,
  type: GenerationType,
  prompt: string,
): Promise<GenerateOutput> {
  switch (provider) {
    case 'anthropic':
      return generateWithAnthropic(type, prompt)
    case 'openai':
      return generateWithOpenAI(type, prompt)
    case 'gemini':
      return generateWithGemini(type, prompt)
    default:
      throw new Error(`Unknown provider: ${provider}`)
  }
}

export function getAvailableProviders(): ProviderConfig[] {
  const enabled = (process.env.ENABLED_PROVIDERS ?? 'anthropic,openai,gemini')
    .split(',')
    .map((p) => p.trim())

  return (['anthropic', 'openai', 'gemini'] as AIProvider[]).map((id) => ({
    ...PROVIDER_CONFIGS[id],
    available:
      enabled.includes(id) &&
      Boolean(
        id === 'anthropic'
          ? process.env.ANTHROPIC_API_KEY
          : id === 'openai'
            ? process.env.OPENAI_API_KEY
            : process.env.GOOGLE_AI_API_KEY,
      ),
  }))
}
