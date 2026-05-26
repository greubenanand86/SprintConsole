# Jira Mapping — {Product Name}

| Field | Value |
|---|---|
| Jira project key | `{JIRA_PREFIX}` |
| WIP limit | {N} |
| Sprint length | 2 weeks |
| Owner | {owner@example.com} |

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

| Epic | Jira key | Status |
|---|---|---|
| {Epic name} | {JIRA_PREFIX}-{N} | Planned / Active / Done |
