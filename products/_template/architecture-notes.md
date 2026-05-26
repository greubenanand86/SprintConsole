# Architecture Notes — {Product Name}

> Product-specific decisions only. Shared standards live in `governance/shared/` and take precedence.

## Current state

{Stack, phase, key files, known gaps — one paragraph.}

## Target structure

```
apps/{product-id}/
  web/       ← {target web stack}
  mobile/    ← {target mobile stack, if applicable}

packages/    ← shared packages from /packages
backend/     ← {API layer, if applicable}
```

## Decisions

### ADR-001 — {Title} ({YYYY-MM-DD})

**Decision**: {What was decided.}
**Why**: {Why this over the alternatives.}
**Consequence**: {What this locks in or constrains.}
**Revisit when**: {Trigger condition.}

---

## Open questions

| Question | Owner | Status |
|---|---|---|
| {Question} | {Agent or human} | Open / In progress |

## Anti-patterns

- {Pattern to avoid and why}
