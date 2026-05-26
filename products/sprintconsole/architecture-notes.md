# Architecture Notes — SprintConsole

> Product-specific decisions only. Shared standards live in `governance/shared/`. When in doubt, the shared document wins.

## Current state

SprintConsole is a Babel/JSX prototype with no build step, no backend, and no TypeScript. All application files live at the repo root. This is an acknowledged temporary state — see Engineering Constitution §2 and Architecture Blueprint §3.

## Target architecture

```
apps/sprintconsole/
  web/           ← React 18 + TypeScript + Next.js (App Router)
  mobile/        ← React Native + Expo + TypeScript

packages/
  ui/            ← Shared design system (web + mobile)
  api-client/    ← Typed Jira + internal API client
  validation/    ← Zod schemas shared across web, mobile, backend
  utils/         ← Date, string, number utilities

backend/
  api/           ← REST + WebSocket API (Node/TypeScript or Bun)
  db/            ← Schema migrations, seed data
```

## Decisions

### ADR-001: Babel/JSX prototype phase (accepted, 2024)
**Decision**: Ship a working prototype without TypeScript or a build step to validate core UX patterns.
**Rationale**: Fastest path to a usable product for a single-person team. Avoids premature infrastructure investment before product-market fit.
**Consequence**: All new features must be TypeScript-ready in design even if implemented in JSX. TypeScript migration is the first Horizon 2 investment.
**Revisit trigger**: Any new major feature requiring >1 sprint of work — migrate first.

### ADR-002: CSS variables as design tokens (accepted, 2024)
**Decision**: All UI styles reference `--color-*`, `--radius-*`, `--space-*`, `--shadow-*` tokens from `colors_and_type.css`. No hardcoded values in components.
**Rationale**: Enables theme changes and future design system extraction without touching components.
**Consequence**: Any new component that hardcodes a hex or px value fails Engineering Constitution §3.

### ADR-003: Shared components in `sprintops-shared.jsx` (accepted, 2024)
**Decision**: Button, Badge, Card, Modal, StatusIcon are defined once in `sprintops-shared.jsx` and reused everywhere.
**Rationale**: Visual consistency, single point of accessibility maintenance.
**Consequence**: New UI patterns go into shared before being used in more than one feature file.

### ADR-004: Mock data via `window.SPRINTOPS_DATA` (accepted, prototype phase only)
**Decision**: All data is mocked in `sprintops-data.js` and exposed as a global.
**Rationale**: No backend yet. Allows UI development to proceed in parallel.
**Consequence**: No persistence, no multi-user support. Must be replaced in Horizon 2 when backend ships.

### ADR-005: Next.js App Router for web migration (proposed, not yet started)
**Decision**: When migrating to TypeScript, use Next.js with App Router (not Pages Router).
**Rationale**: App Router is the React team's recommended direction; aligns with Server Components for future SSR needs.
**Status**: Proposed. Requires Architecture Agent review before sprint planning.

## Open questions

| Question | Status | Owner |
|---|---|---|
| Hosting platform for backend API (Vercel, Railway, AWS?) | Open | Architect Agent + TPM |
| Real-time mechanism (WebSocket vs Server-Sent Events vs polling) | Open | Architect Agent |
| Auth strategy (Clerk, NextAuth, custom JWT?) | Open | Security Agent + Architect Agent |
| Database choice (Postgres, SQLite, PlanetScale?) | Open | Architect Agent |

## Anti-patterns (do not do these)

- Do not add new features to the Babel/JSX prototype that would need to be rewritten in TypeScript
- Do not copy shared components into feature files — extend `sprintops-shared.jsx` instead
- Do not use `dangerouslySetInnerHTML` without explicit Security Agent sign-off
- Do not hardcode environment URLs — use `config.env` or environment variables
- Do not introduce a new third-party SDK without Legal & Compliance review (Governance §4)
