#!/usr/bin/env bash
# Tech Architect + QA Refinement Agent — Engineering Constitution §1 §2 §3 §10 | Security Baseline v1.0
# Picks up "To Do" stories, adds technical notes, architecture standards compliance,
# tech stack compliance (§2), component standards (§3), security design review per Baseline,
# documentation requirements (§10), plus explainability fields per governance §2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Fetch unrefined stories ────────────────────────────────────────────────
STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22To+Do%22,%22Idea+%2F+Request%22,%22Triage%22,%22Ready+for+Refinement%22)&maxResults=20&fields=summary,description,status")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -eq 0 ]; then
  exit 0
fi

echo "Architect Agent: $COUNT stories to refine"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  REFINEMENT=$(claude --print \
"Role: You are the Tech Architect Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Refine this story technically — assess architecture compliance, define implementation approach, flag risks and documentation requirements.

Inputs:
- Story: $SUMMARY
- Source files readable via Read tool

Architecture Blueprint v1.0 (ARCHITECTURE.md) — governs all structural decisions:
§3 Web: React + TypeScript mandatory; Next.js + React Query + Zustand preferred; feature-based folders.
§4 Mobile: React Native + Expo + TypeScript mandatory; shared design system; native code requires Architecture review.
§5 Backend: API-first, version-aware, centralized auth + validation + logging.
§15 Technical Decision Hierarchy: Security > Stability > Maintainability > Scalability > Dev productivity > Performance > Sophistication.
Boring architecture scales better than clever architecture.

Engineering Constitution requirements:
§1 Simplicity: Prefer simplest solution. Flag over-engineering risk.
§2 Tech Standards: TypeScript is mandatory — flag any .jsx file as tech debt and recommend TS migration path.
§3 Architecture: Components handle loading/error/empty states; no business logic in UI; local state stays local; use CSS design tokens.
§10 Documentation: Major decisions need rationale, alternatives, risks, rollback.
Governance §2: Rationale, impact summary, risk awareness, affected systems, rollback awareness required.

Shared Package Strategy v1.0 (SHARED_PACKAGE_STRATEGY.md) — enforce on any story that touches logic used by more than one client:
- Cross-client validation, API clients, utilities, analytics, and UI primitives belong in /packages
- Shared packages must not contain platform-specific logic or production config
- Flag [SHARED PACKAGE VIOLATION] if a story duplicates code that should live in /packages

API Contract Standards v1.0 (API_CONTRACT_STANDARDS.md) — enforce on any story touching an API:
- Endpoint must have clear naming, consistent request/response shape, validation, auth declaration, error format
- Error responses must use: { errorCode, message, details }
- Routes must be versioned: /api/v1/...
- Breaking API changes require [ESCALATE → TPM] — Architecture review + Release Risk + migration plan required
- Flag [API CONTRACT VIOLATION] if a story proposes an API that skips any of the above

Repository Governance v1.0 (REPOSITORY_GOVERNANCE.md) — enforce structure and branching:
- Target monorepo: /apps/web, /apps/mobile, /packages/*, /backend, /governance, /docs
- New files should land in the correct directory — not at root or in wrong app
- hotfix/* branches require Release Risk review before merging to main
- Flag [REPO STRUCTURE VIOLATION] if a story places files outside the target layout

Flag [ARCHITECTURE DRIFT] if the story's implementation would move away from the target architecture (e.g., adding a new .jsx file instead of .tsx, introducing client-side business logic that should be in a backend service, bypassing the shared design system).

For auth, destructive migrations, or native mobile additions: output [ESCALATE → TPM] — these require Security Agent + Release Risk review per Architecture Blueprint §6 §10.

Output format — output EXACTLY these sections:

TECH_NOTES:
- <implementation note 1>
- <implementation note 2>
- <implementation note 3>

ARCHITECTURE_COMPLIANCE:
- §1 Simplicity: <assessment>
- §3 Component states: <loading/error/empty required and how to implement>
- §3 State management: <what state is needed and where it lives>
- §3 Design tokens: <which CSS variables to use>

TECH_STACK_NOTES:
- <React pattern to follow>
- <TypeScript debt note if applicable>

DOCUMENTATION_REQUIRED:
- <architecture decision to document, or 'Standard implementation — no ADR needed'>

RATIONALE:
- <why this technical approach>

IMPACT_SUMMARY:
- <what changes and what is affected>

RISK_AWARENESS:
- <potential risk>

AFFECTED_SYSTEMS:
- <component or file>

ROLLBACK_AWARENESS:
- <how to revert>

TEST_SCENARIOS:
- <test scenario 1>
- <test scenario 2>
- <test scenario 3>

SENSITIVE_AREAS: <YES|NO>

ARCHITECTURE_DRIFT: <YES — describe drift from target architecture|NO>

API_CONTRACT_COMPLIANCE: <N/A — no API surface|PASS — meets all standards|VIOLATION — describe gap>

SHARED_PACKAGE_COMPLIANCE: <N/A — no cross-client code|PASS — correctly uses /packages|VIOLATION — describe duplication>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  SENSITIVE=$(echo "$REFINEMENT" | grep '^SENSITIVE_AREAS:' | grep -i 'YES' | wc -l | tr -d ' ')
  DRIFT=$(echo "$REFINEMENT" | grep '^ARCHITECTURE_DRIFT:' | grep -i 'YES' | wc -l | tr -d ' ')
  DRIFT_NOTE=$(echo "$REFINEMENT" | grep '^ARCHITECTURE_DRIFT:' | sed 's/^ARCHITECTURE_DRIFT: YES — //')
  API_VIOLATION=$(echo "$REFINEMENT" | grep '^API_CONTRACT_COMPLIANCE:' | grep -i 'VIOLATION' | wc -l | tr -d ' ')
  API_NOTE=$(echo "$REFINEMENT" | grep '^API_CONTRACT_COMPLIANCE:' | sed 's/^API_CONTRACT_COMPLIANCE: VIOLATION — //')
  PKG_VIOLATION=$(echo "$REFINEMENT" | grep '^SHARED_PACKAGE_COMPLIANCE:' | grep -i 'VIOLATION' | wc -l | tr -d ' ')
  PKG_NOTE=$(echo "$REFINEMENT" | grep '^SHARED_PACKAGE_COMPLIANCE:' | sed 's/^SHARED_PACKAGE_COMPLIANCE: VIOLATION — //')
  ADR=$(echo "$REFINEMENT" | sed -n '/^DOCUMENTATION_REQUIRED:/,/^RATIONALE:/p' | grep '^-' | sed 's/^- //' | head -1)

  COMMENT="[ARCHITECT] Technical Refinement — §1 §2 §3 §10

Technical Notes:
$(echo "$REFINEMENT" | sed -n '/^TECH_NOTES:/,/^ARCHITECTURE_COMPLIANCE:/p' | grep '^-' | sed 's/^- /• /')

Architecture Compliance:
$(echo "$REFINEMENT" | sed -n '/^ARCHITECTURE_COMPLIANCE:/,/^TECH_STACK_NOTES:/p' | grep '^-' | sed 's/^- /✓ /')

Tech Stack Notes:
$(echo "$REFINEMENT" | sed -n '/^TECH_STACK_NOTES:/,/^DOCUMENTATION_REQUIRED:/p' | grep '^-' | sed 's/^- /🔧 /')

Documentation Required:
$(echo "$REFINEMENT" | sed -n '/^DOCUMENTATION_REQUIRED:/,/^RATIONALE:/p' | grep '^-' | sed 's/^- /📄 /')

Rationale:
$(echo "$REFINEMENT" | sed -n '/^RATIONALE:/,/^IMPACT_SUMMARY:/p' | grep '^-' | sed 's/^- /→ /')

Impact Summary:
$(echo "$REFINEMENT" | sed -n '/^IMPACT_SUMMARY:/,/^RISK_AWARENESS:/p' | grep '^-' | sed 's/^- /📋 /')

Risk Awareness:
$(echo "$REFINEMENT" | sed -n '/^RISK_AWARENESS:/,/^AFFECTED_SYSTEMS:/p' | grep '^-' | sed 's/^- /⚠ /')

Affected Systems:
$(echo "$REFINEMENT" | sed -n '/^AFFECTED_SYSTEMS:/,/^ROLLBACK_AWARENESS:/p' | grep '^-' | sed 's/^- /🔧 /')

Rollback Awareness:
$(echo "$REFINEMENT" | sed -n '/^ROLLBACK_AWARENESS:/,/^TEST_SCENARIOS:/p' | grep '^-' | sed 's/^- /↩ /')

[QA LEAD] Test Scenarios:
$(echo "$REFINEMENT" | sed -n '/^TEST_SCENARIOS:/,/^SENSITIVE_AREAS:/p' | grep '^-' | sed 's/^- /✓ /')"

  if [ "$SENSITIVE" -gt 0 ]; then
    COMMENT="$COMMENT

⚠ SECURITY FLAG: Touches sensitive areas. Security Agent review mandatory per §4."
  fi

  if [ "$DRIFT" -gt 0 ]; then
    COMMENT="$COMMENT

[ARCHITECTURE DRIFT] This story moves away from the target architecture (ARCHITECTURE.md):
$DRIFT_NOTE
Recommend aligning with target before merging. Record drift decision in PRODUCT_MEMORY.md."
  fi

  if [ "$PKG_VIOLATION" -gt 0 ]; then
    COMMENT="$COMMENT

[SHARED PACKAGE VIOLATION] Story duplicates logic that should live in /packages (Shared Package Strategy v1.0):
$PKG_NOTE
Move to the appropriate shared package: /packages/ui, /api-client, /validation, /utils, /config, or /analytics."
  fi

  if [ "$API_VIOLATION" -gt 0 ]; then
    COMMENT="$COMMENT

[API CONTRACT VIOLATION] Story does not meet API Contract Standards v1.0:
$API_NOTE
Required: endpoint naming, request/response shape, validation, auth, error format ({ errorCode, message, details }), /api/v1/... versioning.
Breaking changes require [ESCALATE → TPM] — Architecture review + Release Risk review + migration plan."
  fi

  if [ -n "$ADR" ] && ! echo "$ADR" | grep -qi "no adr needed"; then
    COMMENT="$COMMENT

📄 ADR REQUIRED: $ADR — Document in PRODUCT_MEMORY.md per §10."
  fi

  extract_standard "$REFINEMENT"
  COMMENT="$COMMENT
$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"

  # Transition to "Refined" per §3 lifecycle
  jira_transition "$KEY" "Refined"
  jira_transition "$KEY" "Ready for Refinement"  # fallback no-op if already there

  # Write handoff packet for Delivery Coordinator / Dev (Agent Interaction Protocols §2)
  TECH_SUMMARY=$(echo "$REFINEMENT" | sed -n '/^TECH_NOTES:/,/^ARCHITECTURE_COMPLIANCE:/p' | grep '^-' | head -3 | sed 's/^- //' | tr '\n' '; ')
  RISK_SUMMARY=$(echo "$REFINEMENT" | sed -n '/^RISK_AWARENESS:/,/^AFFECTED_SYSTEMS:/p' | grep '^-' | head -2 | sed 's/^- //' | tr '\n' '; ')
  OPEN_Q=$([ "$SENSITIVE" -gt 0 ] && echo "Security Agent review required — touches sensitive areas" || echo "None")

  write_handoff "$KEY" \
    "ARCHITECT" \
    "Delivery Coordinator → In Development → Code Review" \
    "$SUMMARY" \
    "See story description" \
    "See [UX DESIGNER] comment" \
    "${TECH_SUMMARY:-Standard React implementation}" \
    "${RISK_SUMMARY:-Low}" \
    "See story description" \
    "$OPEN_Q" \
    "Feature implemented per AC; passes QA checks; accessibility verified (§5)"

  echo "Architect Agent: Refined $KEY — $SUMMARY"

done

echo "Architect Agent: Refinement complete"
exit 2
