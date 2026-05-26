# Product Memory — SprintConsole

Durable organizational intelligence for SprintConsole. Decisions, rationale, learnings, and constraints that must survive team changes and context resets.

> Root memory file: `products/sprintconsole/PRODUCT_MEMORY.md`
> This directory holds structured memory entries that are too large for inline storage.

## What belongs here

| Entry type | When to write | Who writes |
|---|---|---|
| Architecture Decision Record | Any structural or stack decision | Architect Agent + human sign-off |
| Incident postmortem | Any SEV-1 or SEV-2 incident | Incident Agent |
| Sprint retrospective learnings | Each sprint | TPM Agent |
| Rejected approach | When a significant option was considered and discarded | PM / Architect Agent |
| External constraint | Legal, compliance, or contractual requirement | Legal Agent |

## What does not belong here

- Active sprint state (belongs in Jira)
- Real-time monitoring data (belongs in monitoring dashboards)
- Draft proposals not yet decided (keep in Jira story or PR)
- Roadmap items (belongs in `roadmap.md`)

## Naming convention

```
{YYYY-MM-DD}-{type}-{short-slug}.md

Examples:
  2024-11-15-adr-typescript-migration-plan.md
  2025-03-02-incident-postmortem-auth-outage.md
  2025-04-10-retro-sprint-23-learnings.md
  2025-05-01-rejected-graphql-adoption.md
```

## Index

| File | Type | Date | Summary |
|---|---|---|---|
| (none yet) | — | — | — |

Add entries to this table as files are created. The Product Memory Agent maintains this index automatically when `JIRA_WRITE_ENABLED=true`.

## Related

- Root memory file: `products/sprintconsole/PRODUCT_MEMORY.md`
- Governance: `governance/shared/architecture.md`
- Product Memory System spec: `PRODUCT_MEMORY_SYSTEM.md` (repo root)
- Agent: `claude/agents/product-memory-agent.md`
