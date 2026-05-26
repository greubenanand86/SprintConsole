# Agent Hook Scripts

Runtime implementations of the agent prompts defined in `claude/agents/`.

## Current location

Hook scripts currently live in `.claude/hooks/` (the Claude Code settings directory). This is their working location. The `claude/hooks/` directory is the proposed target for a future migration that separates Claude Code internal settings from the agent runtime.

**Until migration:** reference `.claude/hooks/` for all running scripts.
**After migration:** scripts will live here and `.claude/settings.json` hook paths will be updated.

## What lives here (target state)

| Script | Agent | Trigger |
|---|---|---|
| `jira.sh` | Shared library | Sourced by all agents |
| `pm-agent.sh` | Product Manager | Stop hook |
| `architect-agent.sh` | Architecture | Stop hook |
| `ux-agent.sh` | UX / Design | Stop hook |
| `tpm-agent.sh` | TPM | Stop hook |
| `delivery-coordinator-agent.sh` | Delivery Coordinator | Stop hook |
| `qa-agent.sh` | QA Lead | Stop hook |
| `security-agent.sh` | Security | Stop hook |
| `legal-compliance-agent.sh` | Legal & Compliance | Stop hook |
| `product-acceptance-agent.sh` | Product Acceptance | Stop hook |
| `product-governance-agent.sh` | Product Governance | Stop hook |
| `release-risk-agent.sh` | Release Readiness & Risk | Stop hook |
| `deploy-agent.sh` | Deploy Specialist | Stop hook |
| `monitoring-agent.sh` | Monitoring | Stop hook |
| `incident-agent.sh` | Incident Response | Stop hook |
| `analytics-agent.sh` | Analytics | Stop hook |
| `finops-agent.sh` | FinOps | Stop hook |
| `tech-debt-agent.sh` | Tech Debt | Stop hook |
| `product-memory-agent.sh` | Product Memory | Stop hook |
| `observability-agent.sh` | Observability | Stop hook |
| `ui-agent.sh` | Web Frontend | Stop hook |
| `mobile-agent.sh` | React Native Mobile | Manual |
| `backend-api-agent.sh` | Backend & API | Manual |

## Advisory-first

All write operations default to advisory mode. Agents read Jira, analyse, and output recommendations to stdout. Nothing posts to Jira unless `JIRA_WRITE_ENABLED=true` is set explicitly.

## Multi-product

Product context is loaded automatically from `products/registry.json` when any agent runs. Pass a Jira key to resolve the product from its prefix (e.g. `SC-42` → `sprintconsole`), or set `PRODUCT=<id>` explicitly.
