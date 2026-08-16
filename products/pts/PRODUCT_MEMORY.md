# Product Memory — PTS

Durable decisions, learnings, and constraints. Written once, never deleted — mark entries SUPERSEDED and add a forward reference instead.

## Architecture decisions

| Date | Decision | Rationale | Status |
|---|---|---|---|
| 2026-08-16 | Expo managed workflow | Faster iteration, OTA updates, no native toolchain overhead | Active |
| 2026-08-16 | TypeScript strict from day one | Shared governance requirement; avoids migration cost later | Active |

## Rejected approaches

| Date | Approach | Why rejected | Alternative |
|---|---|---|---|
| — | — | — | — |

## Constraints

| Type | Constraint | Source |
|---|---|---|
| Technical | Expo managed workflow — no bare eject without Architect review | ADR-001 |
| Technical | TypeScript only — no JS files | ADR-002 + shared governance |
| Compliance | WCAG 2.1 AA — VoiceOver + TalkBack required | Legal & Compliance Governance |
| Security | No secrets in source — env vars or secrets manager only | Security Baseline v1.0 |

## Incidents and learnings

| Date | Severity | Summary | Postmortem |
|---|---|---|---|
| — | — | — | — |

## Sprint retrospective learnings

| Sprint | Date | Learning | Action |
|---|---|---|---|
| — | — | — | — |
