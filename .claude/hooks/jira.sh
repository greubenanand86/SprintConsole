#!/usr/bin/env bash
# workspace.sh — Shared task and context library for all agents
# (filename kept as jira.sh so existing agent scripts need no changes)
#
# Advisory-first: agents observe, analyze, and recommend.
# TASK_WRITE_ENABLED defaults to false — write functions print advisory output
# to stdout instead of modifying files.
#
# To enable actual file writes:
#   TASK_WRITE_ENABLED=true source jira.sh

TASK_WRITE_ENABLED="${TASK_WRITE_ENABLED:-false}"

_JIRA_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_REPO_ROOT="$(cd "$_JIRA_SH_DIR/../.." && pwd)"
_PRODUCTS_DIR="$_REPO_ROOT/products"
_REGISTRY="$_PRODUCTS_DIR/registry.json"

# ── Task operations ────────────────────────────────────────────────────────────

task_create() {
  # Create a new task markdown file in the product's tasks/ directory
  # $1 = title, $2 = type (Feature/Bug/Debt/Spike), $3 = description
  local TITLE="$1" TYPE="${2:-Feature}" DESC="${3:-}"

  if [ "${TASK_WRITE_ENABLED}" = "true" ]; then
    local TASKS_DIR="$_PRODUCTS_DIR/${PRODUCT_ID:-sprintconsole}/tasks"
    mkdir -p "$TASKS_DIR"

    local COUNT
    COUNT=$(find "$TASKS_DIR" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
    local PREFIX="${TASK_PREFIX:-TSK}"
    local ID="${PREFIX}-$(printf '%03d' $((COUNT + 1)))"
    local SLUG
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40)
    local FILE="$TASKS_DIR/${ID}-${SLUG}.md"

    cat > "$FILE" <<EOF
---
id: $ID
product: ${PRODUCT_ID:-sprintconsole}
status: Backlog
type: $TYPE
priority: P2
created: $(date +%Y-%m-%d)
tags: []
---

# $TITLE

## Description
$DESC

## Acceptance Criteria
- [ ]

## Agent Notes

EOF
    # Add to kanban backlog
    local KANBAN="$_PRODUCTS_DIR/${PRODUCT_ID:-sprintconsole}/kanban.md"
    if [ -f "$KANBAN" ]; then
      sed -i "/^## Backlog/a - [ ] [[$ID-$SLUG|$TITLE]]" "$KANBAN"
    fi
    echo "[TASK CREATED] $ID — $FILE"
  else
    echo "[ADVISORY] Suggested new task: $TITLE (type: $TYPE)"
    echo "           Create it in Obsidian or run with TASK_WRITE_ENABLED=true"
  fi
}

task_log() {
  # Append an agent note to a task file
  # $1 = task ID or file path, $2 = agent name, $3 = note text
  local TASK="$1" AGENT="$2" NOTE="$3"

  if [ "${TASK_WRITE_ENABLED}" = "true" ]; then
    local FILE
    if [ -f "$TASK" ]; then
      FILE="$TASK"
    else
      FILE=$(find "$_PRODUCTS_DIR" -name "${TASK}-*.md" 2>/dev/null | head -1)
    fi

    if [ -n "$FILE" ] && [ -f "$FILE" ]; then
      printf '\n### [%s] %s\n%s\n' "$AGENT" "$(date +%Y-%m-%d)" "$NOTE" >> "$FILE"
      echo "[LOGGED] Note added to $FILE"
    else
      echo "[WARN] Task file not found for: $TASK — note printed to stdout only"
    fi
  fi
  # In advisory mode: agent stdout is the deliverable — no file write needed
}

task_move() {
  # Recommend a status/column change on the Kanban board
  # $1 = task ID, $2 = target column
  echo "[ADVISORY] Move task ${1} → ${2}"
  echo "           Drag the card in Obsidian Kanban, or run with TASK_WRITE_ENABLED=true"
}

# ── Backward-compatible aliases ────────────────────────────────────────────────
# Agent scripts that call jira_comment / jira_transition / jira_post
# continue to work without modification.

jira_comment() { task_log "$1" "Agent" "$2"; }
jira_transition() { task_move "$1" "$2"; }
jira_post() {
  # Simplified: treat as task_create advisory. Agents passing JSON payloads
  # will see an advisory recommendation instead of a Jira issue creation.
  if [ "${TASK_WRITE_ENABLED}" = "true" ]; then
    echo "[TASK WRITE] jira_post called — use task_create for file-based task creation"
  else
    echo "[ADVISORY] Task creation suggested (use task_create for Obsidian integration)"
  fi
  echo "{}"  # return empty JSON so jq calls in callers don't error
}
jira_put()  { :; }  # no-op
jira_get()  { echo "{}"; }  # no-op — no Jira to read from

# ── Prompt Engineering Standards v1.0 ─────────────────────────────────────────

_DEFAULT_PRODUCT_HEADER="Context: SprintConsole — React 18, Babel standalone JSX, CSS design tokens (prototype phase)
Core files: sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
  sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx,
  sprintops-config.jsx, sprintops-data.js, colors_and_type.css"

_GOVERNANCE_CONTEXT="Target architecture (ARCHITECTURE.md — governs all structural and stack decisions):
- Web: React + TypeScript + Next.js + React Query + Zustand/Redux Toolkit → /web
- Mobile: React Native + Expo + TypeScript + shared design system → /mobile
- Backend: API-first, version-aware, centralized auth + validation + logging → /backend
- Shared: business logic, design system, validation, analytics → /shared
- All clients interact through consistent API contracts
- Feature-based folder organisation is mandatory across all clients
- TypeScript is mandatory everywhere (current .jsx files are highest-priority tech debt)

Technical Decision Hierarchy (ARCHITECTURE.md §15 — governs stack and structural decisions):
1. Security  2. Stability  3. Maintainability  4. Scalability
5. Developer productivity  6. Performance optimisation  7. Architectural sophistication

Repository Governance v1.0 (REPOSITORY_GOVERNANCE.md — governs repo structure, branching, PRs, and merges):
- Monorepo: /apps/web, /apps/mobile, /packages/*, /backend, /governance, /docs
- Branches: main (production) | develop (integration) | feature/* | bugfix/* | hotfix/* | release/*
- Every PR requires: task reference, summary, what changed, screenshots if UI, test evidence, risk notes, rollback notes
- Merge gates: CI passes + code review + QA path identified + no unresolved release blockers
- hotfix/* branches from main and requires Release Risk review

Shared Package Strategy v1.0 (SHARED_PACKAGE_STRATEGY.md — governs code sharing across web and mobile):
- Shared packages: /packages/ui, /packages/api-client, /packages/validation,
  /packages/utils, /packages/config, /packages/analytics
- Shared packages must NOT contain: platform-specific logic, business logic duplication, production config
- Any cross-client duplication (validation, API calls, utils, analytics) belongs in /packages
- Flag [SHARED PACKAGE VIOLATION] if a story duplicates logic that should be shared

API Contract Standards v1.0 (API_CONTRACT_STANDARDS.md — governs all API design):
- All APIs: clear endpoint naming, consistent request/response, validation, auth, error format, pagination, version awareness
- Standard error format: { errorCode, message, details }
- Versioned routes: /api/v1/...
- Breaking API changes require Architecture review + Release Risk review + migration plan
- API contracts are shared product infrastructure, not backend implementation details

Release Management Playbook v1.0 (RELEASE_MANAGEMENT_PLAYBOOK.md — governs all releases):
- Core principle: Stability > Speed. All releases must be observable, recoverable, governable.
- Release workflow: Code Complete → Code Review → QA Validation → Product Acceptance → Release Risk Review → Human Approval → Production Release → Monitoring → Done
- Release readiness (9 mandatory checks): QA done, Product Acceptance done, Monitoring enabled, Rollback available, Release notes prepared, Crash reporting (mobile), Analytics validated, Security review (if required), Compliance review (if required)
- Rollback governance: All releases need rollback strategy, rollback owner, rollback validation before release
- Monitoring window: Released → Monitoring → Stable → Done

Environment Governance v1.0 (ENVIRONMENT_GOVERNANCE.md — governs all environments):
- Mandatory environments: Local, Development, Staging, Production
- Deployment flow (no skipping): Local → Development → Staging → Production
- Separate configs, secrets, and databases per environment
- Secrets management: environment variables only (never in source); leaked secrets trigger immediate rotation

Security Baseline v1.0 (SECURITY_BASELINE.md — governs all security aspects):
- Core principles: least privilege, secure defaults, auditability, environment separation, secret isolation
- Authentication: token expiration, RBAC, secure storage (HTTP-only cookies web, Keychain/Keystore mobile)
- API security: auth validation, input validation, rate limiting, structured errors
- Secrets: NO secrets in source code, frontend, mobile, or logs
- Mobile security: Keychain/Keystore token storage, HTTPS/TLS 1.2+, certificate pinning
- Dependency governance: automated scanning, vulnerabilities block CI, fix High/Critical same day
- Mandatory Security Agent review before production for auth changes, sensitive APIs, integrations

Lightweight Legal & Compliance Governance v1.0 (LEGAL_COMPLIANCE_GOVERNANCE.md):
- Legal & Compliance Agent identifies risks early; does NOT provide legal sign-off
- Data privacy: GDPR/CCPA/PIPEDA, consent flows, right to deletion, cross-border transfers
- Accessibility: WCAG 2.1 AA minimum on all UI (VoiceOver + TalkBack for mobile)
- Third-party SDK: privacy impact assessment, security posture, vendor agreements
- Escalates to human counsel: legal holds, DPA needs, contract review, regulatory questions

Product Memory System v1.0 (PRODUCT_MEMORY_SYSTEM.md — durable organisational intelligence):
- Categories: Product Decisions, UX Decisions, Architecture Decisions, Technical Debt,
  Release Learnings, Incidents, Customer Context, Operational Learnings
- Store in: products/{id}/product-memory/{category}/
- Decision format: Decision, Context, Rationale, Alternatives, Risks, Owner, Date
- Agents check Product Memory before proposing major changes; cite prior decisions
- Memory is append-only: decisions superseded (not deleted)

Metrics & Operational Dashboard Framework v1.0 (METRICS_DASHBOARD_FRAMEWORK.md):
- Core principle: metrics exist to improve decisions, not create pressure
- Targets: predictability 80%+, lead time <7 days, test coverage 70%+, crash-free 99%+

Incident Management Playbook v1.0 (INCIDENT_MANAGEMENT_PLAYBOOK.md):
- Severity levels: SEV-1 (production outage), SEV-2 (major degradation), SEV-3 (partial), SEV-4 (minor)
- Incident workflow: Detected → Classify → Contain → Assess rollback → Resolve → Monitor → Postmortem
- Postmortems stored in products/{id}/product-memory/incidents/

Agent Role Specifications v1.0 (AGENT_ROLE_SPECIFICATIONS.md — AI agent governance):
- 22 agents: each has Mission, Authority, Inputs, Outputs, Escalation rules
- Authority rules: agents may escalate, reject (within scope), flag risks
- Agents may NOT: deploy to production, override governance, bypass QA/security/release gates
- Final decisions: always humans

Governance: Engineering Constitution + Product Constitution + Architecture Blueprint v1.0
  + API Contract Standards v1.0 + Repository Governance v1.0 + Release Management Playbook v1.0
  + Environment Governance v1.0 + Security Baseline v1.0 + Legal & Compliance Governance v1.0
  + Product Memory System v1.0 + Metrics Dashboard Framework v1.0 + Incident Management Playbook v1.0
  + Agent Role Specifications v1.0 + Agent Interaction Protocols v1.0"

AGENT_CONTEXT="${_DEFAULT_PRODUCT_HEADER}

${_GOVERNANCE_CONTEXT}"

AGENT_CONSTRAINTS="Constraints:
- Avoid technical jargon in user/business-facing sections
- State uncertainty with explicit confidence level (HIGH / MEDIUM / LOW)
- Explain business impact for every significant finding
- Provide actionable recommendations, not just analysis
- Flag governance violations immediately with [GOVERNANCE VIOLATION]
- Use plain language in SUMMARY, BUSINESS_IMPACT, and USER_IMPACT sections"

AGENT_ESCALATION_RULES="Escalation rules:
Escalate immediately and prefix output with [ESCALATE → TPM] if you detect:
- Production risk: data loss, service disruption, security breach
- Compliance concern: auth, PII, billing, legal, or destructive migration
- Governance bypass: skipping QA, Product Acceptance, or release gates
- Agent conflict: contradictory verdicts from prior agent output
Prefix governance violations with: [GOVERNANCE VIOLATION]"

STANDARD_OUTPUT_SUFFIX="Additionally output ALL of the following standard fields:

SUMMARY: <one sentence — task state and what is needed; no jargon>
RECOMMENDATION: <single most important action to take next>
BUSINESS_IMPACT: <user or product effect in plain language>
TIMELINE_IMPACT: <sprint or delivery effect, or 'No impact on current sprint'>
USER_IMPACT: <how end users are directly affected, or 'Not user-visible'>
RISKS_SUMMARY: <key risks in plain English, or 'None identified'>
DEPENDENCIES_SUMMARY: <blocking items, or 'None'>
NEXT_STEPS:
- <concrete action 1>
- <concrete action 2>
TASK_UPDATES: <status or field changes needed in the task file or Kanban board>
PRODUCT_MEMORY: <YES — what decision or learning to record|NO>"

NONTECHNICAL_SUMMARY_REQ="For TPM and human-facing sections also output:
NON_TECHNICAL_SUMMARY:
- Business impact: <plain-language effect on users or product>
- Timeline impact: <delivery or sprint effect>
- User impact: <what end users will notice or be blocked by>
- Cost impact: <engineering or operational cost, or 'None'>
- Release risk: <likelihood and severity of release issues>"

extract_standard() {
  local R="$1"
  STD_SUMMARY=$(echo "$R"       | grep '^SUMMARY:'              | sed 's/^SUMMARY: //')
  STD_RECOMMENDATION=$(echo "$R"| grep '^RECOMMENDATION:'       | sed 's/^RECOMMENDATION: //')
  STD_BUSINESS=$(echo "$R"      | grep '^BUSINESS_IMPACT:'      | sed 's/^BUSINESS_IMPACT: //')
  STD_TIMELINE=$(echo "$R"      | grep '^TIMELINE_IMPACT:'      | sed 's/^TIMELINE_IMPACT: //')
  STD_USER=$(echo "$R"          | grep '^USER_IMPACT:'          | sed 's/^USER_IMPACT: //')
  STD_RISKS=$(echo "$R"         | grep '^RISKS_SUMMARY:'        | sed 's/^RISKS_SUMMARY: //')
  STD_DEPS=$(echo "$R"          | grep '^DEPENDENCIES_SUMMARY:' | sed 's/^DEPENDENCIES_SUMMARY: //')
  STD_NEXT=$(echo "$R"          | sed -n '/^NEXT_STEPS:/,/^TASK_UPDATES:/p' | grep '^-' | sed 's/^- /→ /')
  STD_TASK=$(echo "$R"          | grep '^TASK_UPDATES:'         | sed 's/^TASK_UPDATES: //')
  STD_PM=$(echo "$R"            | grep '^PRODUCT_MEMORY:'       | sed 's/^PRODUCT_MEMORY: //')
}

standard_fields_block() {
  echo "---
Summary: ${STD_SUMMARY:-Not provided}
Recommendation: ${STD_RECOMMENDATION:-See agent-specific sections above}
Business Impact: ${STD_BUSINESS:-Not specified}
Timeline Impact: ${STD_TIMELINE:-No impact on current sprint}
User Impact: ${STD_USER:-Not user-visible}
Next Steps:
${STD_NEXT:-→ See agent-specific actions above}
Task Updates: ${STD_TASK:-None}
Product Memory: ${STD_PM:-NO}"
}

# ── Handoff and escalation ─────────────────────────────────────────────────────

write_handoff() {
  local KEY="$1" FROM_AGENT="$2" TO_STAGE="$3"
  local OBJECTIVE="${4:-Not specified}"
  local AC="${5:-See task description}"
  local UX_NOTES="${6:-See UX Agent output}"
  local TECH_NOTES="${7:-See Architect output}"
  local RISKS="${8:-None identified}"
  local DEPS="${9:-None}"
  local OPEN_QS="${10:-None}"
  local EXPECTED="${11:-Feature complete and tested}"

  local PACKET="[HANDOFF PACKET] $FROM_AGENT → $TO_STAGE | $(date -u '+%Y-%m-%d %H:%M UTC')
Task: $KEY
Objective: $OBJECTIVE
Acceptance Criteria: $AC
UX Notes: $UX_NOTES
Technical Notes: $TECH_NOTES
Risks: $RISKS
Dependencies: $DEPS
Open Questions: $OPEN_QS
Expected Output: $EXPECTED"

  echo ""
  echo "$PACKET"
  echo ""

  # If write enabled, also log to the task file
  [ "${TASK_WRITE_ENABLED}" = "true" ] && task_log "$KEY" "Handoff" "$PACKET"
}

read_last_handoff() {
  # Read the most recent handoff from a task file
  local KEY="$1"
  local FILE
  FILE=$(find "$_PRODUCTS_DIR" -name "${KEY}-*.md" 2>/dev/null | head -1)
  if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    grep -A20 '\[HANDOFF PACKET\]' "$FILE" | tail -20
  fi
}

escalate_to_tpm() {
  local KEY="$1" REASON="$2" SOURCE_AGENT="$3"
  echo ""
  echo "[ESCALATION RECOMMENDED] ${SOURCE_AGENT} → TPM — ${KEY}"
  echo "  Reason: ${REASON}"
  echo "  Conflict resolution order: Security > Stability > UX > Product value > Maintainability > Speed"
  echo "  Action: Human / TPM Agent should review before proceeding."
  echo ""
  [ "${TASK_WRITE_ENABLED}" = "true" ] && task_log "$KEY" "ESCALATE→TPM" "$SOURCE_AGENT: $REASON"
}

# ── Multi-product support ──────────────────────────────────────────────────────

load_product_context() {
  local KEY_HINT="${1:-}"
  local PID="${PRODUCT:-}"

  # Auto-detect from task key prefix (e.g. "SC-123" → product with task_prefix "SC")
  if [ -z "$PID" ] && [ -n "$KEY_HINT" ] && [ -f "$_REGISTRY" ]; then
    local PREFIX="${KEY_HINT%%-*}"
    PID=$(jq -r --arg p "$PREFIX" \
      '.products[] | select((.task_prefix // .jira_project) == $p) | .id' \
      "$_REGISTRY" 2>/dev/null | head -1)
  fi

  # Fall back to registry default
  if [ -z "$PID" ] && [ -f "$_REGISTRY" ]; then
    PID=$(jq -r '.default // .products[0].id' "$_REGISTRY" 2>/dev/null | head -1)
  fi

  [ -z "$PID" ] && return 0

  local CFG="$_PRODUCTS_DIR/$PID/config.env"
  [ ! -f "$CFG" ] && return 0

  source "$CFG"

  # Support both TASK_PREFIX (new) and JIRA_PROJECT (legacy alias)
  TASK_PREFIX="${TASK_PREFIX:-${JIRA_PROJECT:-TSK}}"
  JIRA_PROJECT="$TASK_PREFIX"  # keep alias so old agent code still works

  local HEADER="Context: ${PRODUCT_NAME} — ${PRODUCT_STACK}
Core files: ${PRODUCT_CORE_FILES}"

  AGENT_CONTEXT="${HEADER}

${_GOVERNANCE_CONTEXT}"

  export TASK_PREFIX JIRA_PROJECT
  export PRODUCT_ID PRODUCT_NAME
  export PRODUCT_MEMORY_FILE="$_PRODUCTS_DIR/$PID/PRODUCT_MEMORY.md"
  export PRODUCT_WIP_LIMIT="${PRODUCT_WIP_LIMIT:-6}"
  export PRODUCT_TEAM_EMAIL="${PRODUCT_TEAM_EMAIL:-}"
  export AGENT_CONTEXT
  export TASKS_DIR="$_PRODUCTS_DIR/$PID/tasks"
}

for_each_product() {
  local FN="$1"; shift
  if [ ! -f "$_REGISTRY" ]; then
    load_product_context
    "$FN" "$@"
    return
  fi
  local IDS
  IDS=$(jq -r '.products[] | select((.status // "active") == "active") | .id' \
        "$_REGISTRY" 2>/dev/null)
  for PID in $IDS; do
    PRODUCT="$PID" load_product_context
    "$FN" "$@"
  done
}

# Load default product context at source time
load_product_context
