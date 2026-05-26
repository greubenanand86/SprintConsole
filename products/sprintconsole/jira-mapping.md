# Jira Mapping — SprintConsole

| Field | Value |
|---|---|
| Jira project key | `SC` |
| WIP limit | 6 |
| Sprint length | 2 weeks |
| Owner | greubenanand@gmail.com |

## Workflow → agent ownership

| Status | Agent |
|---|---|
| Idea / Request → Triage | PM Agent |
| Product Discovery | PM Agent + UX Agent |
| Ready for Refinement → Refined | Architect Agent |
| Ready for Development | Delivery Coordinator |
| In Development | Dev |
| Code Review | Security Agent + Architect Agent |
| Ready for QA → QA In Progress | QA Lead Agent |
| Product Acceptance | Product Acceptance Agent |
| Ready for Release | Release Risk Agent |
| Released → Monitoring → Done | Monitoring Agent |
| Blocked | Delivery Coordinator → TPM Agent |

## Priority → severity

| Jira | Severity | Meaning |
|---|---|---|
| P0 | SEV-1 | Production down / data loss / security breach |
| P1 | SEV-2 | Major feature broken, significant user impact |
| P2 | SEV-3 | Partial degradation, workaround exists |
| P3 | SEV-4 | Minor / cosmetic, no user impact |

## Active epics

| Epic | Description | Status |
|---|---|---|
| TypeScript Migration | Babel/JSX → TS + Next.js | Planned |
| Mobile Client | React Native + Expo initial build | Planned |
| Backend API | API-first backend, auth, data model | Planned |
| Test Infrastructure | Unit + integration test suite | Planned |
