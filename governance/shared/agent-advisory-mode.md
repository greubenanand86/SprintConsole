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
| Summarize | Sprint health, story status, blocker analysis, release readiness |
| Create checklists | Definition of Ready, Definition of Done, QA test plans, release gates |
| Create draft files | Architecture notes, product memory entries, release notes, ADRs |
| Create PRs for review | Code, documentation, governance changes — all require human merge |
| Propose Jira updates | Story creation, status transitions, comments — printed to stdout as advisory output |

---

## What agents may not do

| Action | Why prohibited |
|---|---|
| Auto-transition Jira tickets | Status transitions change sprint state visible to the whole team — human intent required |
| Auto-approve releases | Release approval is a human governance gate per Release Management Playbook v1.0 |
| Auto-deploy to production | Production changes require human approval per Engineering Constitution §9 and AI Governance §3 |
| Override governance | No agent output supersedes shared governance documents without a human-authored change |
| Mix product context | An agent running against `SC-` tickets must not read, write, or reference another product's memory or board without explicit product context switch |
| Apply one product's decision to another | Decisions in `products/sprintconsole/product-memory/` are not portable to other products without explicit review |

---

## How it is enforced

A single flag in `.claude/hooks/jira.sh` controls all write behavior across every agent:

```bash
JIRA_WRITE_ENABLED="${JIRA_WRITE_ENABLED:-false}"
```

Default is `false`. Every write function checks this flag before acting:

| Function | When `JIRA_WRITE_ENABLED=false` | When `true` |
|---|---|---|
| `jira_post()` | Returns `"{}"` — no HTTP call made | Posts to Jira REST API |
| `jira_put()` | No-op | PUTs to Jira REST API |
| `jira_transition()` | Prints `[ADVISORY] Recommended transition: KEY → status` | Executes the transition |
| `jira_comment()` | Silent — stdout is the deliverable | Posts comment to Jira |
| `escalate_to_tpm()` | Prints structured escalation block to stdout | Prints + posts to Jira |
| `write_handoff()` | Prints handoff packet to stdout | Prints + posts to Jira |

No agent calls the Jira API directly. All writes go through these wrapper functions. Adding a new agent that bypasses the wrappers violates this governance.

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

Write mode is not a phase upgrade — it is a per-run opt-in for specific, human-authorized operations.

```bash
JIRA_WRITE_ENABLED=true .claude/hooks/pm-agent.sh SC-42
```

Before enabling write mode for any agent:
- Confirm the operation has been reviewed in advisory output first
- Confirm human approval has been given for the specific action
- Do not set `JIRA_WRITE_ENABLED=true` as a permanent environment variable

Write mode does not change what an agent is allowed to do — it only allows the advisory recommendations to be executed. The governance constraints above apply regardless of flag value.
