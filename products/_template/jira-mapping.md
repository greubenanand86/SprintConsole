# Jira Mapping — {Product Name}

## Project

| Field | Value |
|---|---|
| Jira project key | `{JIRA_PREFIX}` |
| Project name | {Product Name} |
| Project type | Software (Scrum) |
| Board | {Product Name} Sprint Board |

## Story prefix routing

All Jira keys starting with `{JIRA_PREFIX}-` belong to this product. The `load_product_context()` function in `.claude/hooks/jira.sh` resolves `{JIRA_PREFIX}-*` keys to this product automatically.

## Workflow states

| Jira Status | Workflow Governance §3 Stage | Owner Agent |
|---|---|---|
| Idea / Request | Triage | PM Agent |
| Triage | Triage | PM Agent |
| Product Discovery | Product Discovery | PM Agent + UX Agent |
| Ready for Refinement | Ready for Refinement | Architect Agent |
| Refined | Refined | Architect Agent |
| Ready for Development | Ready for Development | Delivery Coordinator |
| In Development | In Development | Dev |
| Code Review | Code Review | Security Agent + Architect Agent |
| Ready for QA | Ready for QA | QA Lead Agent |
| QA In Progress | QA In Progress | QA Lead Agent |
| Product Acceptance | Product Acceptance | Product Acceptance Agent |
| Ready for Release | Ready for Release | Release Risk Agent |
| Released | Released | Monitoring Agent |
| Monitoring | Monitoring | Monitoring Agent |
| Done | Done | — |
| Blocked | — | Delivery Coordinator → TPM Agent |

## Issue types

| Issue Type | Usage |
|---|---|
| Story | User-facing feature work |
| Bug | Defects found in QA or production |
| Tech Debt | Engineering Constitution §12 tracked items |
| Spike | Time-boxed research or proof-of-concept |
| Task | Non-story operational work |
| Epic | Grouping of related stories |

## Priority mapping

| Jira Priority | Incident Severity | Description |
|---|---|---|
| P0 – Critical | SEV-1 | Production down, data loss, security breach |
| P1 – High | SEV-2 | Major feature broken, significant user impact |
| P2 – Medium | SEV-3 | Partial degradation, workaround available |
| P3 – Low | SEV-4 | Minor issue, cosmetic, no user impact |

## Sprint configuration

| Field | Value |
|---|---|
| Sprint length | 2 weeks |
| WIP limit | {N} (set in `products/{product-id}/config.env`) |
| Sprint allocation | 50-60% features, 15-20% debt, 15-20% bugs (Governance §9) |

## Epic index (active)

| Epic | Description | Status |
|---|---|---|
| {Epic name} | {Description} | Planned / Active / Done |

## Contacts

| Role | Contact |
|---|---|
| Product Owner | {owner@example.com} |
| TPM Agent | Shared agent org (product-level) |
| Portfolio TPM | Shared agent org (portfolio tier) |
