# Roadmap — SprintConsole

> Roadmap items are aspirational. Nothing here is committed until a story is Refined and in a sprint. See Jira `SC` board for committed work.

## Horizon 1 — Now (current sprint + next)

| Item | Type | Driver |
|---|---|---|
| TypeScript migration kickoff (spike + plan) | Tech Debt | Engineering Constitution §2 |
| Accessibility audit on existing prototype | Tech Debt | Legal & Compliance Governance |
| Formalize Definition of Ready enforcement in Readiness Tracker | Feature | PM / QA request |

## Horizon 2 — Next (1–3 sprints out)

| Item | Type | Driver |
|---|---|---|
| Migrate to Next.js + TypeScript (`apps/sprintconsole/web/`) | Tech Debt | Architecture Blueprint §3 |
| Introduce unit test suite (Jest + React Testing Library) | Tech Debt | Engineering Constitution §6 |
| CI pipeline (GitHub Actions — lint, test, build) | Tech Debt | Architecture Blueprint §11 |
| Backend API skeleton (auth, story CRUD) | Feature | Architecture Blueprint §5 |

## Horizon 3 — Later (4–8 sprints out)

| Item | Type | Driver |
|---|---|---|
| React Native + Expo mobile client | Feature | Architecture Blueprint §4 |
| Persistent data layer (replace mock data) | Feature | Architecture Blueprint §5 |
| Real-time sprint board (WebSocket or polling) | Feature | User feedback |
| Analytics instrumentation | Feature | Metrics Dashboard Framework |
| Shared `/packages/ui` extraction | Tech Debt | Shared Package Strategy |

## Graduated (shipped)

| Item | Release | Notes |
|---|---|---|
| Readiness Tracker prototype | v0.1 | Babel/JSX, mock data |
| Estimation Planner prototype | v0.1 | Babel/JSX, mock data |
| Release Readiness prototype | v0.1 | Babel/JSX, mock data |
| Multi-product repo structure | infra | Governance + agent org proposal |

## Constraints and dependencies

- Horizon 2 items blocked on TypeScript migration (Architecture Blueprint §3 prerequisite)
- Mobile client blocked on shared `/packages/ui` extraction and backend API
- Backend API requires environment governance decision (hosting, secrets management)
- No Horizon 3 item ships without QA + Product Acceptance gate (Governance §6)

## What is not on this roadmap

- Full project management / Jira replacement
- Time tracking
- HR or OKR features
- Cross-org portfolio views (Portfolio TPM domain)
