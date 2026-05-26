# Architecture Notes — {Product Name}

> Product-specific decisions only. Shared standards live in `governance/shared/`. When in doubt, the shared document wins.

## Current state

{One paragraph describing the current technical state of this product — stack, phase, key files, known gaps.}

## Target architecture

```
{Describe the target structure. Example:}

apps/{product-id}/
  web/           ← React + TypeScript + Next.js
  mobile/        ← React Native + Expo + TypeScript (if applicable)

packages/        ← Shared packages consumed from /packages
backend/         ← API layer (if applicable)
```

## Decisions

### ADR-001: {Decision title} ({date})
**Decision**: {What was decided.}
**Rationale**: {Why this option was chosen over alternatives.}
**Consequence**: {What this means going forward — constraints, obligations, expected trade-offs.}
**Revisit trigger**: {What event or condition would warrant revisiting this decision.}

{Add more ADRs as decisions are made. Prefix with ADR-NNN in sequence.}

## Open questions

| Question | Status | Owner |
|---|---|---|
| {Question} | Open / In progress / Resolved | {Agent or human} |

## Anti-patterns (do not do these)

- {Specific pattern that must not appear in this product's code}
- {Known pitfall from past experience — see Product Memory for context}
