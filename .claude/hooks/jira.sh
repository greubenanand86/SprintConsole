#!/usr/bin/env bash
# Shared Jira helpers — sourced by all agent scripts

JIRA_AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_TOKEN" | base64)

jira_get() {
  curl -s -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_post() {
  curl -s -X POST \
       -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d "$2" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_put() {
  curl -s -X PUT \
       -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d "$2" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_transition() {
  # $1 = issue key, $2 = transition name (case-insensitive)
  local ISSUE="$1" TARGET="$2"
  local TRANSITIONS
  TRANSITIONS=$(jira_get "issue/$ISSUE/transitions")
  local TID
  TID=$(echo "$TRANSITIONS" | jq -r --arg name "$TARGET" \
    '.transitions[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .id' | head -1)
  if [ -n "$TID" ]; then
    jira_post "issue/$ISSUE/transitions" "{\"transition\":{\"id\":\"$TID\"}}" > /dev/null
    echo "Transitioned $ISSUE to $TARGET"
  else
    echo "Warning: transition '$TARGET' not found for $ISSUE"
  fi
}

jira_comment() {
  # $1 = issue key, $2 = comment body text
  local BODY
  BODY=$(jq -n --arg text "$2" '{
    "body": {
      "type": "doc", "version": 1,
      "content": [{"type": "paragraph", "content": [{"type": "text", "text": $text}]}]
    }
  }')
  jira_post "issue/$1/comment" "$BODY" > /dev/null
}

# ── Prompt Engineering Standards v1.0 ─────────────────────────────────────
# Shared prompt components sourced by every agent

AGENT_CONTEXT="Context: SprintOps Console — React 18, no-build, Babel standalone JSX (current prototype state).
Core files: sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
  sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx,
  sprintops-config.jsx, sprintops-data.js, colors_and_type.css

Target architecture (ARCHITECTURE.md — governs all structural and stack decisions):
- Web: React + TypeScript + Next.js + React Query + Zustand/Redux Toolkit → /web
- Mobile: React Native + Expo + TypeScript + shared design system → /mobile
- Backend: API-first, version-aware, centralized auth + validation + logging → /backend
- Shared: business logic, design system, validation, analytics → /shared
- All clients interact through consistent API contracts
- Feature-based folder organization is mandatory across all clients
- TypeScript is mandatory everywhere (current .jsx files are highest-priority tech debt)

Technical Decision Hierarchy (ARCHITECTURE.md §15 — governs stack and structural decisions):
1. Security  2. Stability  3. Maintainability  4. Scalability
5. Developer productivity  6. Performance optimization  7. Architectural sophistication

Repository Governance v1.0 (REPOSITORY_GOVERNANCE.md — governs repo structure, branching, PRs, and merges):
- Monorepo: /apps/web, /apps/mobile, /packages/*, /backend, /governance, /docs
- Branches: main (production) | develop (integration) | feature/* | bugfix/* | hotfix/* | release/*
- Every PR requires: Jira ticket, summary, what changed, screenshots if UI, test evidence, risk notes, rollback notes
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
- Release types: Standard Release (TPM+Human), Hotfix (TPM+Human), Mobile Beta (TPM), Production Mobile (Human), Infrastructure (TPM+Security+Human)
- Release readiness (9 mandatory checks): QA done, Product Acceptance done, Monitoring enabled, Rollback available, Release notes prepared, Crash reporting (mobile), Analytics validated, Security review (if required), Compliance review (if required)
- Mobile governance (mandatory): TestFlight validation, internal testing validation, metadata review, versioning consistency, crash-free beta validation, staged rollout preferred
- Rollback governance: All releases need rollback strategy, rollback owner, rollback validation before release
- Monitoring window: Released → Monitoring → Stable → Done with post-release checks (crashes, API failures, auth issues, performance, analytics)
- Hotfix governance: Incident classification (P0-P3), rollback awareness, post-release validation, postmortem documentation. hotfix/* requires Release Risk review.

Environment Governance v1.0 (ENVIRONMENT_GOVERNANCE.md — governs all environments):
- Mandatory environments: Local (mock data), Development (sanitized test data), Staging (scrubbed prod-like data), Production (real customer data)
- Deployment flow (no skipping): Local → Development → Staging → Production
- Separate configs, secrets, and databases per environment; no shared secrets across environments
- Staging mirrors production configuration, integrations, and monitoring; provides production confidence
- Production access restricted; sensitive changes require TPM + Security review + human approval
- Test data governance: never copy production data to lower environments without scrubbing; GDPR/PCI/CCPA compliance required
- Secrets management: environment variables only (never in code); leaked secrets trigger immediate rotation
- Monitoring mandatory in Staging + Production: logging (structured/JSON), crash reporting, real-time alerts, analytics validation
- Post-release monitoring window (Released → Monitoring → Stable → Done) per Release Management Playbook §8

Security Baseline v1.0 (SECURITY_BASELINE.md — governs all security aspects):
- Core principles: least privilege access, secure defaults, auditability, environment separation, secret isolation
- Authentication: token expiration (15-60 min access, longer refresh), RBAC, secure storage (HTTP-only cookies web, Keychain/Keystore mobile)
- API security: auth validation (401/403), input validation (whitelist, parameterized queries), rate limiting, structured errors
- Secrets: NO secrets in source code, frontend, mobile, or logs; centralized management; rotation on schedule or immediately if leaked
- Mobile security: Keychain/Keystore token storage, HTTPS/TLS 1.2+, certificate pinning, minimal permissions, safe deep linking
- Dependency governance: automated scanning (npm audit/Snyk), vulnerabilities block CI, fix immediately (High/Critical same day)
- Logging/auditability: auth events, authorization changes, sensitive operations, deployment visibility, release traceability
- Data protection: encryption in transit (HTTPS) and at rest (sensitive data), minimal exposure, retention policies, access restrictions
- Code review security checklist: no secrets, input validation, auth checks, parameterized queries, dependency scanning, safe errors
- Security review triggers: auth/authz changes, data access control changes, new sensitive APIs, external integrations, critical vulnerabilities
- Mandatory Security Agent review before production for auth changes, data control changes, sensitive APIs, integrations, vulnerabilities
- Final principle: security is built in from start, not added at release time

Lightweight Legal & Compliance Governance v1.0 (LEGAL_COMPLIANCE_GOVERNANCE.md — risk identification, not AI attorney):
- Legal & Compliance Agent identifies risks early; does NOT provide legal sign-off (human counsel required)
- Data privacy: GDPR/CCPA/PIPEDA implications, consent flows, right to deletion, cross-border transfers, third-party agreements
- Accessibility: WCAG 2.1 AA, ADA, Section 508 compliance; flag UI without accessibility review
- Student data (if applicable): FERPA confidentiality, PPRA parental notification, marketing restrictions, third-party access
- Survey anonymity: anonymous handling, aggregation before analysis
- Credential data exposure: no plaintext passwords/tokens in logs, backups, error messages
- Third-party SDK: privacy impact assessment, security posture, vendor agreements (DSA/DPA), due diligence
- Terms/policy alignment: feature aligns with published ToS and privacy policy
- Release blocking: blocks if consent missing, privacy-sensitive unreviewed, accessibility unresolved, SDK risk unknown, legal review pending
- Escalates to human counsel: legal holds, DPA needs, contract review, policy updates, regulatory questions, breaches, litigation

Product Memory System v1.0 (PRODUCT_MEMORY_SYSTEM.md — durable organizational intelligence):
- Core categories: Product Decisions (features, roadmap, scope), UX Decisions (workflow, accessibility),
  Architecture Decisions (API, state management, scaling), Technical Debt (compromises, repayment plans),
  Release Learnings (incidents, rollbacks, monitoring), Incident Postmortems (P0-P3, root cause, prevention),
  Customer Context (constraints, contracts, integrations), Operational Learnings (process improvements)
- Store durable knowledge: decisions + rationale, learnings, standards, constraints
- Do NOT store: temp conversations, brainstorming, low-confidence assumptions
- Decision format: Decision, Context, Rationale, Alternatives, Risks, Owner, Date, Review cycle
- Retrieval rule: agents check Product Memory before proposing major changes, cite prior decisions
- Memory is append-only: decisions superseded (not deleted), learnings prevent recurrence
- Quarterly review: identify stale decisions, update roadmap, emerging patterns
- Final principle: optimize for decision continuity, not documentation volume

Metrics & Operational Dashboard Framework v1.0 (METRICS_DASHBOARD_FRAMEWORK.md — data-driven decisions):
- 6 dashboard categories: TPM (velocity, predictability, incidents), Engineering (builds, deployments, lead time),
  Product (adoption, retention, crashes), Operational (incidents, rollbacks, SLA uptime), AI Governance (PRs, overrides, compliance),
  Custom (institution-specific metrics)
- Core principle: metrics exist to improve decisions, not create pressure
- Targets: predictability 80%+, deployments 1-2/week, lead time <7 days, test coverage 70%+,
  incidents <1 P0/P1/month, QA escape <2%, crash-free 99%+, release failure <3%
- Review cadence: weekly (sprint health, incidents), monthly (adoption, debt, effectiveness),
  quarterly (trends, strategy, satisfaction)
- Anti-patterns: avoid vanity metrics, individual metrics, metrics without context, metrics as punishment
- Data rules: single source per metric, automated collection, transparent visibility, no retroactive changes
- Use metrics to: understand capability, identify problems early, measure impact, improve processes
- Don't use metrics to: punish teams, hide problems, justify prior decisions

Incident Management Playbook v1.0 (INCIDENT_MANAGEMENT_PLAYBOOK.md — incident handling & learning):
- Severity levels: SEV-1 (production outage/major data risk), SEV-2 (major degradation), SEV-3 (partial), SEV-4 (minor)
- Incident workflow: Detected → Classify severity → Contain → Assess rollback → Resolve → Monitor → Postmortem → Product Memory
- Ownership: Incident Response Agent (coordination), TPM Agent (escalation), DevOps Agent (rollback), QA Agent (validation),
  Security Agent (assessment), Human (final decisions)
- Rollback rules: Preferred when user trust impacted, crash spikes widespread, auth unstable, or data integrity at risk
- Postmortem mandatory: root cause, timeline, impact, detection gap, resolution, prevention steps (system-level learning, not blame)
- Final principle: incidents are learning opportunities for organizational improvement

Governance: Engineering Constitution + Product Constitution + Architecture Blueprint v1.0
  + API Contract Standards v1.0 + Repository Governance v1.0 + Release Management Playbook v1.0
  + Environment Governance v1.0 + Security Baseline v1.0 + Lightweight Legal & Compliance Governance v1.0
  + Product Memory System v1.0 + Metrics & Operational Dashboard Framework v1.0 + Incident Management Playbook v1.0
  + Jira Workflow Governance v1.1 + Agent Interaction Protocols v1.0 + Prompt Engineering Standards v1.0"

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
- Agent conflict: contradictory verdicts from prior agent comments
Prefix governance violations with: [GOVERNANCE VIOLATION]"

# Standard output suffix appended to every agent prompt's output format section
STANDARD_OUTPUT_SUFFIX="Additionally output ALL of the following standard fields:

SUMMARY: <one sentence — story state and what is needed; no jargon>
RECOMMENDATION: <single most important action to take next>
BUSINESS_IMPACT: <user or product effect in plain language>
TIMELINE_IMPACT: <sprint or delivery effect, or 'No impact on current sprint'>
USER_IMPACT: <how end users are directly affected, or 'Not user-visible'>
RISKS_SUMMARY: <key risks in plain English, or 'None identified'>
DEPENDENCIES_SUMMARY: <blocking items, or 'None'>
NEXT_STEPS:
- <concrete action 1>
- <concrete action 2>
JIRA_UPDATES: <status, label, or field changes needed in Jira>
PRODUCT_MEMORY: <YES — what decision or learning to record|NO>"

# Non-technical summary block — appended to TPM-facing agent prompts only
NONTECHNICAL_SUMMARY_REQ="For TPM and human-facing sections also output:
NON_TECHNICAL_SUMMARY:
- Business impact: <plain-language effect on users or product>
- Timeline impact: <delivery or sprint effect>
- User impact: <what end users will notice or be blocked by>
- Cost impact: <engineering or operational cost, or 'None'>
- Release risk: <likelihood and severity of release issues>"

# extract_standard: parse standard output fields from a Claude response
# Usage: extract_standard "$RESPONSE" — populates STD_* variables in current shell
extract_standard() {
  local R="$1"
  STD_SUMMARY=$(echo "$R" | grep '^SUMMARY:' | sed 's/^SUMMARY: //')
  STD_RECOMMENDATION=$(echo "$R" | grep '^RECOMMENDATION:' | sed 's/^RECOMMENDATION: //')
  STD_BUSINESS=$(echo "$R" | grep '^BUSINESS_IMPACT:' | sed 's/^BUSINESS_IMPACT: //')
  STD_TIMELINE=$(echo "$R" | grep '^TIMELINE_IMPACT:' | sed 's/^TIMELINE_IMPACT: //')
  STD_USER=$(echo "$R" | grep '^USER_IMPACT:' | sed 's/^USER_IMPACT: //')
  STD_RISKS=$(echo "$R" | grep '^RISKS_SUMMARY:' | sed 's/^RISKS_SUMMARY: //')
  STD_DEPS=$(echo "$R" | grep '^DEPENDENCIES_SUMMARY:' | sed 's/^DEPENDENCIES_SUMMARY: //')
  STD_NEXT=$(echo "$R" | sed -n '/^NEXT_STEPS:/,/^JIRA_UPDATES:/p' | grep '^-' | sed 's/^- /→ /')
  STD_JIRA=$(echo "$R" | grep '^JIRA_UPDATES:' | sed 's/^JIRA_UPDATES: //')
  STD_PM=$(echo "$R" | grep '^PRODUCT_MEMORY:' | sed 's/^PRODUCT_MEMORY: //')
}

# standard_fields_block: format extracted STD_* variables into a Jira comment block
# Call extract_standard first, then call this to get the formatted block
standard_fields_block() {
  echo "---
Summary: ${STD_SUMMARY:-Not provided}
Recommendation: ${STD_RECOMMENDATION:-See agent-specific sections above}
Business Impact: ${STD_BUSINESS:-Not specified}
Timeline Impact: ${STD_TIMELINE:-No impact on current sprint}
User Impact: ${STD_USER:-Not user-visible}
Next Steps:
${STD_NEXT:-→ See agent-specific actions above}
Jira Updates: ${STD_JIRA:-None}
Product Memory: ${STD_PM:-NO}"
}

# Agent Interaction Protocols v1.0 — Handoff Packet helpers
# write_handoff: each agent calls this when handing work to the next stage
# Args: KEY FROM_AGENT TO_STAGE OBJECTIVE AC UX_NOTES TECH_NOTES RISKS DEPS OPEN_QS EXPECTED
write_handoff() {
  local KEY="$1" FROM_AGENT="$2" TO_STAGE="$3"
  local OBJECTIVE="${4:-Not specified}"
  local AC="${5:-See story description}"
  local UX_NOTES="${6:-See UX Agent comment}"
  local TECH_NOTES="${7:-See Architect comment}"
  local RISKS="${8:-None identified}"
  local DEPS="${9:-None}"
  local OPEN_QS="${10:-None}"
  local EXPECTED="${11:-Feature complete and tested}"

  jira_comment "$KEY" "[HANDOFF PACKET] $FROM_AGENT → $TO_STAGE | $(date -u '+%Y-%m-%d %H:%M UTC')
Jira: $KEY
Objective: $OBJECTIVE
Acceptance Criteria: $AC
UX Notes: $UX_NOTES
Technical Notes: $TECH_NOTES
Risks: $RISKS
Dependencies: $DEPS
Open Questions: $OPEN_QS
Expected Output: $EXPECTED"
}

# read_last_handoff: reads the most recent [HANDOFF PACKET] comment for a story
read_last_handoff() {
  local KEY="$1"
  jira_get "issue/$KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[HANDOFF PACKET\]' | tail -1
}

# escalate_to_tpm: flags a story for TPM review
escalate_to_tpm() {
  local KEY="$1" REASON="$2" SOURCE_AGENT="$3"
  jira_comment "$KEY" "[ESCALATE → TPM] $SOURCE_AGENT flagged: $REASON
Conflict Resolution Order (Agent Interaction Protocols §4):
1. Security / legal  2. Stability  3. User experience
4. Product value     5. Maintainability  6. Delivery speed
TPM Agent will review and post resolution."
  echo "$SOURCE_AGENT: Escalated $KEY to TPM — $REASON"
}
