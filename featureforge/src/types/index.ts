export type AIProvider = 'anthropic' | 'openai' | 'gemini'

export type GenerationType =
  | 'gap-check'
  | 'prd'
  | 'tickets'
  | 'acceptance-criteria'
  | 'edge-cases'
  | 'qa-tests'
  | 'full-package'

export const GENERATION_LABELS: Record<GenerationType, string> = {
  'gap-check': 'Gap Check',
  'prd': 'PRD',
  'tickets': 'Jira Tickets',
  'acceptance-criteria': 'Acceptance Criteria',
  'edge-cases': 'Edge Cases',
  'qa-tests': 'QA Test Cases',
  'full-package': 'Full Package',
}

export const CREDIT_COSTS: Record<GenerationType, number> = {
  'gap-check': 1,
  'prd': 3,
  'tickets': 3,
  'acceptance-criteria': 2,
  'edge-cases': 2,
  'qa-tests': 2,
  'full-package': 10,
}

export const GENERATION_DESCRIPTIONS: Record<GenerationType, string> = {
  'gap-check': "Identifies what's missing or unclear in your feature idea before you invest more time.",
  'prd': 'Produces a structured Product Requirements Document covering goals, scope, user stories, and constraints.',
  'tickets': 'Generates Jira-style tickets ready to paste into your project board.',
  'acceptance-criteria': 'Produces a clear definition-of-done checklist for your feature.',
  'edge-cases': 'Surfaces the edge cases and failure modes your team should plan for.',
  'qa-tests': 'Generates a QA test case suite covering happy paths, failures, and boundaries.',
  'full-package': 'Generates everything: PRD + tickets + AC + edge cases + QA tests in one pass.',
}

export const GENERATION_COST_RISK: Record<GenerationType, 'low' | 'medium' | 'high'> = {
  'gap-check': 'low',
  'prd': 'medium',
  'tickets': 'medium',
  'acceptance-criteria': 'low',
  'edge-cases': 'medium',
  'qa-tests': 'medium',
  'full-package': 'high',
}

export type ModelTier = 'fast' | 'powerful'

export interface GenerationRequest {
  type: GenerationType
  provider: AIProvider
  idea: string
  context?: string
  sessionId: string
}

export interface GenerationRecord {
  id: string
  userId: string
  type: GenerationType
  provider: AIProvider
  idea: string
  output: string
  creditsUsed: number
  createdAt: string
  tokensIn?: number
  tokensOut?: number
  durationMs?: number
}

export interface CreditBalance {
  userId: string
  total: number
  used: number
  remaining: number
  plan: PlanType
}

export type PlanType = 'free' | 'starter' | 'pro' | 'team'

export const PLAN_CREDITS: Record<PlanType, number> = {
  free: 10,
  starter: 50,
  pro: 150,
  team: 500,
}

export const PLAN_LABELS: Record<PlanType, string> = {
  free: 'Free',
  starter: 'Starter',
  pro: 'Pro',
  team: 'Team',
}

export interface GenerationResult {
  output: string
  creditsUsed: number
  creditsRemaining: number
  tokensIn: number
  tokensOut: number
  durationMs: number
  provider: AIProvider
  type: GenerationType
  generationId: string
}

export interface ProviderConfig {
  id: AIProvider
  label: string
  description: string
  available: boolean
  fastModel: string
  powerfulModel: string
}

export const PROVIDER_CONFIGS: Record<AIProvider, Omit<ProviderConfig, 'available'>> = {
  anthropic: {
    id: 'anthropic',
    label: 'Claude (Anthropic)',
    description: 'Best for structured documents and nuanced reasoning.',
    fastModel: 'claude-haiku-4-5-20251001',
    powerfulModel: 'claude-sonnet-4-6',
  },
  openai: {
    id: 'openai',
    label: 'GPT-4 (OpenAI)',
    description: 'Excellent at following complex formatting instructions.',
    fastModel: 'gpt-4o-mini',
    powerfulModel: 'gpt-4o',
  },
  gemini: {
    id: 'gemini',
    label: 'Gemini (Google)',
    description: 'Strong at long-context reasoning and multi-part outputs.',
    fastModel: 'gemini-1.5-flash',
    powerfulModel: 'gemini-1.5-pro',
  },
}

export const FAST_GENERATION_TYPES: GenerationType[] = [
  'gap-check',
  'acceptance-criteria',
]
