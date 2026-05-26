import { GoogleGenerativeAI } from '@google/generative-ai'
import { GenerationType, FAST_GENERATION_TYPES, PROVIDER_CONFIGS } from '@/types'
import { getOutputMaxTokens } from '@/lib/prompts'

let client: GoogleGenerativeAI | null = null

function getClient(): GoogleGenerativeAI {
  if (!client) {
    const apiKey = process.env.GOOGLE_AI_API_KEY
    if (!apiKey) throw new Error('GOOGLE_AI_API_KEY is not configured.')
    client = new GoogleGenerativeAI(apiKey)
  }
  return client
}

export async function generateWithGemini(
  type: GenerationType,
  prompt: string,
): Promise<{ text: string; tokensIn: number; tokensOut: number }> {
  const genai = getClient()
  const isFast = FAST_GENERATION_TYPES.includes(type)
  const modelName = isFast
    ? PROVIDER_CONFIGS.gemini.fastModel
    : PROVIDER_CONFIGS.gemini.powerfulModel

  const model = genai.getGenerativeModel({
    model: modelName,
    generationConfig: { maxOutputTokens: getOutputMaxTokens(type) },
  })

  const result = await model.generateContent(prompt)
  const response = result.response
  const text = response.text()

  const usage = response.usageMetadata
  return {
    text,
    tokensIn: usage?.promptTokenCount ?? 0,
    tokensOut: usage?.candidatesTokenCount ?? 0,
  }
}
