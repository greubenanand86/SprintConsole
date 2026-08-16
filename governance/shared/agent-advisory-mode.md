# Agent Advisory Mode

All agents in this organization operate in advisory-first mode during the current phase. This document defines what that means, what is and is not permitted, how it is enforced, and what changes when the phase ends.

---

## What advisory-first means

Agents observe, analyze, and recommend. They do not act on external systems autonomously. Every output is something a human can read, evaluate, and choose to act on — or not.

The agent's deliverable is its stdout: structured recommendations, checklists, draft files, and proposed changes. Nothing outside the local environment changes unless a human explicitly enables write mode.

---

## What agents may do

| Action | Notes |
|---|---|
| Recommend | Verdicts, options, risk assessments, prioritization suggestions |
| Summarize | Sprint health, task status, blocker analysis, release readiness |
| Create checklists | Definition of Ready, Definition of Done, QA test plans, release gates |
| Create draft files | Architecture notes, product memory entries, release notes, ADRs |
| Create PRs for review | Code, documentation, governance changes — all require human merge |
| Propose task updates | Task creation, status moves, notes — printed to stdout as advisory output |

---

## What agents may not do

| Action | Why prohibited |
|---|---|
| Auto-move Kanban tasks | Status changes are human intent — drag the card in Obsidian |
| Auto-approve releases | Release approval is a human governance gate per Release Management Playbook v1.0 |
| Auto-deploy to production | Production changes require human approval per Engineering Constitution §9 and AI Governance §3 |
| Override governance | No agent output supersedes shared governance documents without a human-authored change |
| Mix product context | An agent running against `SC-` tasks must not read, write, or reference another product's memory or board without explicit product context switch |
| Apply one product's decision to another | Decisions in `products/sprintconsole/product-memory/` are not portable to other products without explicit review |

---

## How it is enforced

A single flag in `.claude/hooks/jira.sh` controls all write behavior across every agent:

```bash
TASK_WRITE_ENABLED="${TASK_WRITE_ENABLED:-false}"
```

Default is `false`. Every write function checks this flag before acting:

| Function | When `TASK_WRITE_ENABLED=false` | When `true` |
|---|---|---|
| `task_create()` | Prints advisory suggestion to stdout | Creates a `.md` file in `products/{id}/tasks/` |
| `task_log()` | No-op — stdout is the deliverable | Appends note to the task file |
| `task_move()` | Prints `[ADVISORY] Move task → column` | Advisory only (drag in Obsidian) |
| `jira_comment()` | Alias for `task_log()` — same behaviour | Same |
| `jira_transition()` | Alias for `task_move()` — same behaviour | Same |
| `escalate_to_tpm()` | Prints structured escalation block to stdout | Prints + logs to task file |
| `write_handoff()` | Prints handoff packet to stdout | Prints + logs to task file |

No agent calls any external API. All writes go through these wrapper functions. Adding a new agent that bypasses the wrappers violates this governance.

---

## Agent inventory — advisory-first status

All 22 agents have been verified. Each sources `jira.sh` at startup. None calls `curl` directly.

### Portfolio tier

| Agent | Hook | Write calls | Advisory-first |
|---|---|---|---|
| Portfolio TPM | prompt-only (no hook) | n/a | ✅ |

### Product tier

| Agent | Hook | Write calls | Advisory-first |
|---|---|---|---|
| PM Agent | `pm-agent.sh` | `jira_post` (story create), `jira_transition` | ✅ guarded |
| UX Agent | `ux-agent.sh` | `jira_comment` | ✅ guarded |
| Architecture Agent | `architect-agent.sh` | `jira_comment` | ✅ guarded |
| Delivery Coordinator | `delivery-coordinator-agent.sh` | `jira_comment` | ✅ guarded |
| Web Frontend Agent | `ui-agent.sh` | `jira_comment` | ✅ guarded |
| React Native Mobile Agent | `mobile-agent.sh` | `jira_comment` | ✅ guarded |
| Backend & API Agent | `backend-api-agent.sh` | `jira_comment` | ✅ guarded |
| QA Lead Agent | `qa-agent.sh` | `jira_transition`, `jira_comment` | ✅ guarded |
| Deploy Specialist | `deploy-agent.sh` | `jira_comment` | ✅ guarded |
| Release Readiness & Risk | `release-risk-agent.sh` | `jira_comment` | ✅ guarded |
| Security Agent | `security-agent.sh` | `jira_comment` | ✅ guarded |
| Legal & Compliance Agent | `legal-compliance-agent.sh` | `jira_comment` | ✅ guarded |
| Monitoring Agent | `monitoring-agent.sh` | `jira_transition`, `jira_comment` | ✅ guarded |
| Incident Response Agent | `incident-agent.sh` | `jira_comment` | ✅ guarded |
| Analytics Agent | `analytics-agent.sh` | `jira_post`, `jira_comment` | ✅ guarded |
| FinOps Agent | `finops-agent.sh` | `jira_comment` | ✅ guarded |
| Product Memory Agent | `product-memory-agent.sh` | `jira_comment` | ✅ guarded |
| Product Acceptance Agent | `product-acceptance-agent.sh` | `jira_transition`, `jira_post` | ✅ guarded |
| Product Governance Agent | `product-governance-agent.sh` | `jira_comment` | ✅ guarded |
| Tech Debt Agent | `tech-debt-agent.sh` | `jira_post`, `jira_comment` | ✅ guarded |
| TPM Agent | `tpm-agent.sh` | `jira_comment` | ✅ guarded |
| Observability Agent | `observability-agent.sh` | `jira_comment` | ✅ guarded |

---

## Product context isolation

Each agent run loads product context from `products/registry.json` via `load_product_context()` in `jira.sh`. This sets `JIRA_PROJECT`, `PRODUCT_MEMORY_FILE`, `PRODUCT_WIP_LIMIT`, and `AGENT_CONTEXT` for the current product only.

**Agents must not:**
- Reference `$PRODUCT_MEMORY_FILE` from a different product
- Read or write to another product's Jira project
- Carry a decision from one product's memory into another without an explicit `PRODUCT=` switch and human review

If an agent detects that a request spans multiple products, it outputs an advisory flag and stops — it does not attempt to act on both products in a single run.

---

## Adding a new agent

Any new agent must:

1. Source `jira.sh` as its first action: `source "$SCRIPT_DIR/jira.sh"`
2. Use only `jira_post`, `jira_put`, `jira_transition`, `jira_comment`, `escalate_to_tpm`, `write_handoff` for all external writes
3. Never call `curl`, `gh`, or any external API directly for write operations
4. Be added to the agent inventory table above before it is activated

An agent that bypasses the write wrappers is non-compliant with this governance and must not be merged.

---

## Enabling write mode

Write mode is a per-run opt-in for specific, human-authorized file operations. It creates task files and appends notes — it does not post to any external service.

```bash
TASK_WRITE_ENABLED=true .claude/hooks/pm-agent.sh SC-001
```

Before enabling write mode:
- Review the advisory output first to confirm the operation is correct
- Do not set `TASK_WRITE_ENABLED=true` as a permanent environment variable

Write mode does not change what an agent is allowed to do — it only allows advisory recommendations to be written to local markdown files. The governance constraints above apply regardless of flag value.
