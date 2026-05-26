#!/usr/bin/env bash

# Architecture Agent
# Mission: Ensure technical decisions are simple, scalable, maintainable, secure,
#          and aligned with the Architecture Blueprint
# Governs: TIER_1_AGENT_PROMPTS.md §4, Agent Role Specifications v1.0 §4
# Authority: Recommend approval/revision/block; cannot approve production release;
#            cannot override Security or Human decisions
# Advisory-first: recommends transitions; humans execute them

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

TARGET_KEY="${1:-}"

# ── Multi-story scan mode (no key provided) ────────────────────────────────
if [ -z "$TARGET_KEY" ]; then
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22To+Do%22,%22Triage%22,%22Ready+for+Refinement%22)&maxResults=20&fields=summary,status")
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  COUNT=${COUNT:-0}
  [ "$COUNT" -eq 0 ] && exit 0
  echo "Architect Agent: $COUNT stories ready for review"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    bash "$0" "$KEY"
  done
  exit 0
fi

ISSUE=$(jira_get "issue/$TARGET_KEY?fields=summary,status,description,labels,issuetype")
SUMMARY=$(echo "$ISSUE" | jq -r '.fields.summary // ""')
STATUS=$(echo "$ISSUE" | jq -r '.fields.status.name // ""')
LABELS=$(echo "$ISSUE" | jq -r '[.fields.labels[]?] | join(",")' 2>/dev/null || echo "")
ISSUE_TYPE=$(echo "$ISSUE" | jq -r '.fields.issuetype.name // ""')

echo "Architect Agent: Reviewing $TARGET_KEY ($STATUS)"

# Run Claude architecture analysis
ANALYSIS=$(claude --print \
"Role: You are the Architecture Agent for SprintOps Console — technical design authority.
$AGENT_CONTEXT

Task: Review this story for architecture compliance, simplicity, scalability, API design, and security considerations.

Inputs:
- Story: $SUMMARY ($TARGET_KEY)
- Type: $ISSUE_TYPE
- Status: $STATUS
- Labels: $LABELS
- Source files readable via Read tool

Architecture Blueprint v1.0 — governs all structural decisions:
§3 Web: React + TypeScript mandatory; Next.js preferred; feature-based folders.
§4 Mobile: React Native + Expo + TypeScript mandatory; shared design system.
§5 Backend: API-first, version-aware (/api/v1/...), centralized auth + validation + logging.
§15 Decision Hierarchy: Security > Stability > Maintainability > Scalability > Dev productivity > Performance > Sophistication.
Boring architecture scales better than clever architecture.

Shared Package Strategy v1.0: Cross-client logic belongs in /packages. Flag [SHARED PACKAGE VIOLATION] if duplicated.
API Contract Standards v1.0: Endpoints must be named, versioned, validated, authenticated, with { errorCode, message, details } errors.
Repository Governance v1.0: Target layout /apps/web, /apps/mobile, /packages/*, /backend. Flag misplaced files.
Security Baseline v1.0: Auth, PII, secrets, and dependency risks require Security Agent coordination.

Engineering Constitution §1: Prefer simplest solution. Flag over-engineering.
Engineering Constitution §2: TypeScript mandatory — any .jsx files are tech debt to flag.

Output EXACTLY this format:

ARCH_SUMMARY: <one-line architecture assessment>
PROPOSED_APPROACH: <recommended technical implementation — concise>
SIMPLICITY_REVIEW: <is this the simplest viable approach? Y/N; if N, what is simpler>
SCALABILITY_REVIEW: <does the approach scale? bottlenecks or concerns>
API_DATA_IMPACT: <N/A if no API|else: API surface, data model, contract implications>
SECURITY_CONSIDERATIONS: <auth, PII, secrets, dependency risks; or 'None identified'>
RISKS:
- <risk 1>
- <risk 2>
RECOMMENDATION: <Approve | Revise | Block — with reason>
PRODUCT_MEMORY_NEEDED: <Yes — reason|No>

Also flag these violations inline if present:
ARCHITECTURE_DRIFT: <YES — describe|NO>
API_CONTRACT_VIOLATION: <YES — describe|NO>
SHARED_PACKAGE_VIOLATION: <YES — describe|NO>
SECURITY_ESCALATION: <YES — why Security Agent must review|NO>

$AGENT_CONSTRAINTS
$AGENT_ESCALATION_RULES
$STANDARD_OUTPUT_SUFFIX" \
  --allowedTools "Read" \
  --no-conversation 2>/dev/null)

extract_standard "$ANALYSIS"

# Parse output sections
ARCH_SUMMARY=$(echo "$ANALYSIS" | grep '^ARCH_SUMMARY:' | sed 's/^ARCH_SUMMARY: //')
PROPOSED=$(echo "$ANALYSIS" | grep '^PROPOSED_APPROACH:' | sed 's/^PROPOSED_APPROACH: //')
SIMPLICITY=$(echo "$ANALYSIS" | grep '^SIMPLICITY_REVIEW:' | sed 's/^SIMPLICITY_REVIEW: //')
SCALABILITY=$(echo "$ANALYSIS" | grep '^SCALABILITY_REVIEW:' | sed 's/^SCALABILITY_REVIEW: //')
API_IMPACT=$(echo "$ANALYSIS" | grep '^API_DATA_IMPACT:' | sed 's/^API_DATA_IMPACT: //')
SECURITY=$(echo "$ANALYSIS" | grep '^SECURITY_CONSIDERATIONS:' | sed 's/^SECURITY_CONSIDERATIONS: //')
RISKS=$(echo "$ANALYSIS" | sed -n '/^RISKS:/,/^RECOMMENDATION:/p' | grep '^-' | sed 's/^- /- /')
RECOMMENDATION=$(echo "$ANALYSIS" | grep '^RECOMMENDATION:' | sed 's/^RECOMMENDATION: //')
PM_NEEDED=$(echo "$ANALYSIS" | grep '^PRODUCT_MEMORY_NEEDED:' | sed 's/^PRODUCT_MEMORY_NEEDED: //')

# Violation flags
DRIFT=$(echo "$ANALYSIS" | grep '^ARCHITECTURE_DRIFT:' | grep -i 'YES' | wc -l | tr -d ' ')
DRIFT_NOTE=$(echo "$ANALYSIS" | grep '^ARCHITECTURE_DRIFT:' | sed 's/^ARCHITECTURE_DRIFT: YES — //')
API_VIOL=$(echo "$ANALYSIS" | grep '^API_CONTRACT_VIOLATION:' | grep -i 'YES' | wc -l | tr -d ' ')
API_NOTE=$(echo "$ANALYSIS" | grep '^API_CONTRACT_VIOLATION:' | sed 's/^API_CONTRACT_VIOLATION: YES — //')
PKG_VIOL=$(echo "$ANALYSIS" | grep '^SHARED_PACKAGE_VIOLATION:' | grep -i 'YES' | wc -l | tr -d ' ')
PKG_NOTE=$(echo "$ANALYSIS" | grep '^SHARED_PACKAGE_VIOLATION:' | sed 's/^SHARED_PACKAGE_VIOLATION: YES — //')
SEC_ESC=$(echo "$ANALYSIS" | grep '^SECURITY_ESCALATION:' | grep -i 'YES' | wc -l | tr -d ' ')
SEC_NOTE=$(echo "$ANALYSIS" | grep '^SECURITY_ESCALATION:' | sed 's/^SECURITY_ESCALATION: YES — //')

# Determine verdict icon
VERDICT_ICON="✅"
VERDICT_TAG="APPROVE"
echo "$RECOMMENDATION" | grep -qi "revise" && VERDICT_ICON="⚠️" && VERDICT_TAG="REVISE"
echo "$RECOMMENDATION" | grep -qi "block" && VERDICT_ICON="❌" && VERDICT_TAG="BLOCK"

# Build Jira comment
COMMENT="[ARCHITECT] $VERDICT_ICON Architecture Review

Story: $SUMMARY ($TARGET_KEY)
Status: $STATUS

## Architecture Summary
$ARCH_SUMMARY

## Proposed Technical Approach
$PROPOSED

## Simplicity Review
$SIMPLICITY

## Scalability Review
$SCALABILITY

## API / Data Impact
$API_IMPACT

## Security Considerations
$SECURITY

## Risks
$([ -z "$RISKS" ] && echo "- None identified" || echo "$RISKS")

## Recommendation
$RECOMMENDATION

## Product Memory Entry Needed?
$PM_NEEDED"

# Append violation flags
if [ "$DRIFT" -gt 0 ]; then
  COMMENT="$COMMENT

[ARCHITECTURE DRIFT] Moving away from target architecture:
$DRIFT_NOTE
→ Align with Architecture Blueprint before merging. Record decision in PRODUCT_MEMORY.md."
fi

if [ "$API_VIOL" -gt 0 ]; then
  COMMENT="$COMMENT

[API CONTRACT VIOLATION] Does not meet API Contract Standards v1.0:
$API_NOTE
→ Required: endpoint naming, versioned routes (/api/v1/...), auth, validation, { errorCode, message, details } errors.
→ Breaking changes: [ESCALATE → TPM] for Architecture review + Release Risk + migration plan."
fi

if [ "$PKG_VIOL" -gt 0 ]; then
  COMMENT="$COMMENT

[SHARED PACKAGE VIOLATION] Cross-client logic duplicated instead of living in /packages:
$PKG_NOTE
→ Move to: /packages/ui, /api-client, /validation, /utils, /config, or /analytics."
fi

if [ "$SEC_ESC" -gt 0 ]; then
  COMMENT="$COMMENT

⚠️ SECURITY ESCALATION REQUIRED: $SEC_NOTE
→ Security Agent review mandatory before story advances to Code Review."
fi

COMMENT="$COMMENT
$(standard_fields_block)"

echo "$COMMENT"
jira_comment "$TARGET_KEY" "$COMMENT" 2>/dev/null || true

# Write handoff packet to next stage
if echo "$RECOMMENDATION" | grep -qi "Approve"; then
  RISK_SUMMARY=$(echo "$RISKS" | head -2 | tr '\n' '; ')
  OPEN_Q=$([ "$SEC_ESC" -gt 0 ] && echo "Security Agent review required" || echo "None")

  write_handoff "$TARGET_KEY" \
    "ARCHITECT" \
    "Development → Code Review" \
    "$SUMMARY" \
    "See story description" \
    "See [UX AGENT] comment" \
    "$PROPOSED" \
    "${RISK_SUMMARY:-Low}" \
    "See story description" \
    "$OPEN_Q" \
    "Feature implemented per AC; Security Agent reviewed (if flagged); QA verified" 2>/dev/null || true
fi

echo "Architect Agent: $TARGET_KEY [$VERDICT_TAG]"
exit 0
