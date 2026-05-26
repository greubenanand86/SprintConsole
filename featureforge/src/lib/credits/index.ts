import { CreditBalance, PlanType, PLAN_CREDITS, CREDIT_COSTS, GenerationType } from '@/types'

// MVP: in-memory store. Replace with database (Prisma/Supabase) in production.
const creditStore = new Map<string, CreditBalance>()

export function getOrCreateBalance(userId: string): CreditBalance {
  if (!creditStore.has(userId)) {
    creditStore.set(userId, {
      userId,
      total: PLAN_CREDITS.free,
      used: 0,
      remaining: PLAN_CREDITS.free,
      plan: 'free',
    })
  }
  return creditStore.get(userId)!
}

export function checkCredits(userId: string, type: GenerationType): boolean {
  const balance = getOrCreateBalance(userId)
  return balance.remaining >= CREDIT_COSTS[type]
}

export function deductCredits(userId: string, type: GenerationType): CreditBalance {
  const balance = getOrCreateBalance(userId)
  const cost = CREDIT_COSTS[type]

  if (balance.remaining < cost) {
    throw new Error(`Insufficient credits. Need ${cost}, have ${balance.remaining}.`)
  }

  balance.used += cost
  balance.remaining -= cost
  creditStore.set(userId, balance)
  return balance
}

export function addCredits(userId: string, amount: number, plan?: PlanType): CreditBalance {
  const balance = getOrCreateBalance(userId)
  balance.total += amount
  balance.remaining += amount
  if (plan) balance.plan = plan
  creditStore.set(userId, balance)
  return balance
}

export function setPlan(userId: string, plan: PlanType): CreditBalance {
  const balance = getOrCreateBalance(userId)
  const addedCredits = PLAN_CREDITS[plan]
  balance.plan = plan
  balance.total = balance.used + addedCredits
  balance.remaining = addedCredits
  creditStore.set(userId, balance)
  return balance
}
