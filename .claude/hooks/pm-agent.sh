#!/usr/bin/env bash

# PM Agent — Product Manager
# Mission: Own product clarity, backlog quality, story readiness, prioritization, and Product Acceptance
# Governs: TIER_1_AGENT_PROMPTS.md §2, Agent Role Specifications v1.0 §2
# Authority: Approve normal stories/bugs for Product Acceptance
# Cannot approve: production releases, security/legal/billing/destructive data/major strategy changes
# Advisory-first: recommends transitions; humans execute them

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Mode detection ─────────────────────────────────────────────────────────
# Usage:
#   pm-agent.sh                          — gap analysis + story creation
#   pm-agent.sh product_acceptance KEY   — Product Acceptance review for a specific story
MODE="${1:-story_creation}"
TARGET_KEY="${2:-}"

# ── Shared output format ───────────────────────────────────────────────────
pm_output() {
  local objective="$1" problem="$2" scope="$3" ac="$4"
  local out_of_scope="$5" risks="$6" jira_updates="$7" recommendation="$8"
  cat <<EOF
[PRODUCT MANAGER]

## Product Objective
$objective

## User Problem
$problem

## Scope
$scope

## Acceptance Criteria
$ac

## Out of Scope
$out_of_scope

## Risks
$risks

## Jira Updates Needed
$jira_updates

## Product Acceptance Recommendation
$recommendation
EOF
}

# ══════════════════════════════════════════════════════════════════════════
# MODE: product_acceptance
# Validates a story against product intent after QA has passed
# ══════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "product_acceptance" ]; then
  [ -z "$TARGET_KEY" ] && echo "Usage: pm-agent.sh product_acceptance <JIRA-KEY>" && exit 1

  ISSUE=$(jira_get "issue/$TARGET_KEY?fields=summary,status,description,labels,issuetype")
  SUMMARY=$(echo "$ISSUE" | jq -r '.fields.summary // ""')
  STATUS=$(echo "$ISSUE" | jq -r '.fields.status.name // ""')
  LABELS=$(echo "$ISSUE" | jq -r '[.fields.labels[]?] | join(",")' 2>/dev/null || echo "")
  ISSUE_TYPE=$(echo "$ISSUE" | jq -r '.fields.issuetype.name // ""')

  echo "PM Agent: Product Acceptance review — $TARGET_KEY ($STATUS)"

  # Governance gate: QA must pass before PM can approve
  COMMENTS=$(jira_get "issue/$TARGET_KEY/comments?maxResults=100" 2>/dev/null || echo '{"comments":[]}')
  COMMENT_TEXTS=$(echo "$COMMENTS" | jq -r '[.comments[]?.body // ""] | join("\n")' 2>/dev/null || echo "")

  QA_PASSED=$(echo "$COMMENT_TEXTS" | grep -c '\[QA LEAD\].*✅\|QA.*PASS\|PASS.*QA' || true)
  QA_FAILED=$(echo "$COMMENT_TEXTS" | grep -c '\[QA LEAD\].*❌\|QA.*FAIL' || true)

  # Authority check: identify restricted categories PM cannot approve
  RESTRICTED=""
  echo "$LABELS $SUMMARY $ISSUE_TYPE" | grep -qi "security\|auth\|credential" && RESTRICTED="security/auth"
  echo "$LABELS $SUMMARY $ISSUE_TYPE" | grep -qi "billing\|payment\|subscription" && RESTRICTED="billing"
  echo "$LABELS $SUMMARY $ISSUE_TYPE" | grep -qi "legal\|compliance\|gdpr\|ferpa" && RESTRICTED="legal/compliance"
  echo "$LABELS $SUMMARY $ISSUE_TYPE" | grep -qi "delete.*all\|drop.*table\|destructive\|migration" && RESTRICTED="destructive data"
  echo "$LABELS $SUMMARY $ISSUE_TYPE" | grep -qi "strategy\|roadmap\|pivot\|major" && RESTRICTED="major strategy"

  # Build verdict
  if [ -n "$RESTRICTED" ]; then
    VERDICT="⛔ CANNOT APPROVE — $RESTRICTED change requires human review, not PM Agent"
    VERDICT_TAG="ESCALATE"
  elif [ "$QA_PASSED" -eq 0 ] && [ "$QA_FAILED" -eq 0 ]; then
    VERDICT="❌ HOLD — QA Lead has not yet reviewed this story. Product Acceptance requires QA sign-off first."
    VERDICT_TAG="HOLD"
  elif [ "$QA_FAILED" -gt 0 ] && [ "$QA_PASSED" -eq 0 ]; then
    VERDICT="❌ BLOCKED — QA has failed this story. Resolve QA failures before Product Acceptance."
    VERDICT_TAG="BLOCKED"
  else
    VERDICT="✅ RECOMMENDED — QA passed. Story validated for product intent. Recommend advancing to Ready for Release."
    VERDICT_TAG="PASS"
  fi

  COMMENT=$(pm_output \
    "Validate that '$SUMMARY' delivers the intended product value" \
    "Users need: $(echo "$SUMMARY" | sed 's/^[A-Z-]*[0-9]*[: ]*//')" \
    "- Story: $SUMMARY\n- Type: $ISSUE_TYPE\n- Status: $STATUS" \
    "- QA validation: $([ "$QA_PASSED" -gt 0 ] && echo "✅ Passed" || echo "❌ Not yet passed")\n- Acceptance criteria verified by QA Lead" \
    "- Production deployment (requires separate human approval)\n- Security/legal/billing/destructive changes (out of PM authority)" \
    "$([ -n "$RESTRICTED" ] && echo "- ⚠ Restricted category detected: $RESTRICTED" || echo "- None identified")" \
    "- Advisory only — humans execute Jira transitions\n- If PASS: recommend moving story to Ready for Release\n- If HOLD/BLOCKED: story remains in Product Acceptance" \
    "$VERDICT")

  echo "$COMMENT"
  jira_comment "$TARGET_KEY" "$COMMENT" 2>/dev/null || true

  echo "PM Agent: Product Acceptance — $TARGET_KEY [$VERDICT_TAG]"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════
# MODE: story_creation (default)
# Gap analysis + backlog story creation per §5 Definition of Ready
# ══════════════════════════════════════════════════════════════════════════
EXISTING=$(jira_get "search?jql=project=$JIRA_PROJECT+ORDER+BY+created+DESC&maxResults=100&fields=summary,status,issuetype")
EXISTING_TITLES=$(echo "$EXISTING" | jq -r '.issues[].fields.summary' 2>/dev/null | tr '[:upper:]' '[:lower:]')
ISSUE_COUNT=$(echo "$EXISTING" | jq '.total // 0')

echo "PM Agent: Found $ISSUE_COUNT existing issues in $JIRA_PROJECT — running gap analysis"

ANALYSIS=$(claude --print \
"Role: You are the Product Manager Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Perform a gap analysis on the existing Jira backlog against the product spec. Create stories for missing features that satisfy the §5 Definition of Ready.

Governance §5 + Product Constitution §4 §8: Each story must include business purpose, AC, UX considerations, edge cases, QA notes, release impact, analytics event, priority, dependencies, and API considerations.

EXISTING JIRA ISSUES (do NOT duplicate):
$(echo "$EXISTING" | jq -r '.issues[] | "- [\(.fields.issuetype.name)] \(.key): \(.fields.summary)"' 2>/dev/null || echo 'None yet')

Product spec — 4 pages:
1. Readiness Tracker — work items grid, TaskCell, ReadinessMeter, filters, dropdowns
2. Estimation Planner — hour estimates (QA=25% UAT=15% of Dev), override/reset, Save to ADO
3. Release Readiness — release task cards, badges, Generate Scope, Create Post-Deploy
4. Configuration — ADO Connection, Iteration, Field Mapping, Task/Readiness/Estimation Rules

Output format: For each missing story output EXACTLY this pipe-separated line:
STORY|<title>|<business purpose>|<user story: as a user I want...>|<ac1>;<ac2>;<ac3>|<ux note>|<edge case>|<qa note>|<release impact>|<analytics event>|<priority>|<dependencies>|<api considerations>

Output 8-12 STORY lines. Then output all standard fields.

$AGENT_CONSTRAINTS
$AGENT_ESCALATION_RULES
$STANDARD_OUTPUT_SUFFIX" \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

extract_standard "$ANALYSIS"
[ -n "$STD_SUMMARY" ] && echo "PM Agent: $STD_SUMMARY"

# ── Get issue type IDs ─────────────────────────────────────────────────────
ISSUE_TYPES=$(jira_get "project/$JIRA_PROJECT" | jq '.issueTypes // []')
STORY_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[] | select(.name=="Story") | .id' | head -1)
EPIC_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[] | select(.name=="Epic") | .id' | head -1)
[ -z "$STORY_TYPE_ID" ] && STORY_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[0].id' | head -1)

# ── Create Epic if missing ─────────────────────────────────────────────────
EPIC_EXISTS=$(echo "$EXISTING" | jq -r '.issues[] | select(.fields.issuetype.name=="Epic") | .key' | head -1)

if [ -z "$EPIC_EXISTS" ] && [ -n "$EPIC_TYPE_ID" ]; then
  EPIC_PAYLOAD=$(jq -n \
    --arg proj "$JIRA_PROJECT" \
    --arg typeid "$EPIC_TYPE_ID" \
    '{
      "fields": {
        "project": {"key": $proj},
        "issuetype": {"id": $typeid},
        "summary": "SprintOps Console — Full Application",
        "description": {
          "type": "doc", "version": 1,
          "content": [{"type": "paragraph", "content": [{"type": "text",
            "text": "End-to-end implementation of the SprintOps Console: Readiness Tracker, Estimation Planner, Release Readiness, and Configuration pages integrated with Azure DevOps."}]}]
        }
      }
    }')
  EPIC_RESULT=$(jira_post "issue" "$EPIC_PAYLOAD")
  EPIC_KEY=$(echo "$EPIC_RESULT" | jq -r '.key // ""')
  echo "PM Agent: Created Epic $EPIC_KEY"
fi

# ── Parse and create each Story ────────────────────────────────────────────
CREATED=0
SKIPPED=0

while IFS='|' read -r TYPE TITLE BIZ_PURPOSE USER_STORY AC_RAW UX_NOTE EDGE_CASE QA_NOTE RELEASE_IMPACT ANALYTICS_EVENT PRIORITY DEPENDENCIES API_NOTES; do
  [ "$TYPE" != "STORY" ] && continue
  [ -z "$TITLE" ] && continue

  if echo "$EXISTING_TITLES" | grep -qi "$(echo "$TITLE" | cut -c1-30)"; then
    echo "PM Agent: Skipping (exists): $TITLE"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  AC_CONTENT=$(echo "$AC_RAW" | tr ';' '\n' | grep -v '^$' | while IFS= read -r ac; do
    jq -n --arg text "✓ $ac" \
      '{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":$text}]}]}'
  done | jq -s '.')

  DESCRIPTION=$(jq -n \
    --arg biz "${BIZ_PURPOSE:-Not specified}" \
    --arg story "$USER_STORY" \
    --argjson ac "$AC_CONTENT" \
    --arg ux "${UX_NOTE:-Not specified}" \
    --arg edge "${EDGE_CASE:-Not specified}" \
    --arg qa "${QA_NOTE:-Not specified}" \
    --arg impact "${RELEASE_IMPACT:-Low}" \
    --arg analytics "${ANALYTICS_EVENT:-Not specified}" \
    --arg deps "${DEPENDENCIES:-None}" \
    --arg api "${API_NOTES:-None}" \
    '{
      "type": "doc", "version": 1,
      "content": [
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Business Purpose"}]},
        {"type":"paragraph","content":[{"type":"text","text":$biz}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"User Story"}]},
        {"type":"paragraph","content":[{"type":"text","text":$story}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Acceptance Criteria"}]},
        {"type":"bulletList","content":$ac},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"UX Considerations"}]},
        {"type":"paragraph","content":[{"type":"text","text":$ux}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Edge Cases"}]},
        {"type":"paragraph","content":[{"type":"text","text":$edge}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"QA Notes"}]},
        {"type":"paragraph","content":[{"type":"text","text":$qa}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Release Impact"}]},
        {"type":"paragraph","content":[{"type":"text","text":$impact}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Analytics Event (§8)"}]},
        {"type":"paragraph","content":[{"type":"text","text":$analytics}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Dependencies (§5 DoR)"}]},
        {"type":"paragraph","content":[{"type":"text","text":$deps}]},
        {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"API Considerations (§5 DoR)"}]},
        {"type":"paragraph","content":[{"type":"text","text":$api}]}
      ]
    }')

  case "${PRIORITY:-Medium}" in
    Critical) JIRA_PRIORITY="Highest" ;;
    High)     JIRA_PRIORITY="High" ;;
    Low)      JIRA_PRIORITY="Low" ;;
    *)        JIRA_PRIORITY="Medium" ;;
  esac

  PAYLOAD=$(jq -n \
    --arg proj "$JIRA_PROJECT" \
    --arg typeid "$STORY_TYPE_ID" \
    --arg summary "$TITLE" \
    --argjson desc "$DESCRIPTION" \
    --arg priority "$JIRA_PRIORITY" \
    '{
      "fields": {
        "project": {"key": $proj},
        "issuetype": {"id": $typeid},
        "summary": $summary,
        "description": $desc,
        "priority": {"name": $priority}
      }
    }')

  RESULT=$(jira_post "issue" "$PAYLOAD")
  KEY=$(echo "$RESULT" | jq -r '.key // "ERROR"')

  if [ "$KEY" != "ERROR" ] && [ "$KEY" != "null" ]; then
    echo "PM Agent: Created $KEY [${JIRA_PRIORITY}] — $TITLE"

    # Write PM output block as Jira comment for traceability
    PM_COMMENT=$(pm_output \
      "Deliver: $TITLE" \
      "$USER_STORY" \
      "- Story: $TITLE\n- Priority: $JIRA_PRIORITY\n- Dependencies: ${DEPENDENCIES:-None}" \
      "$(echo "$AC_RAW" | tr ';' '\n' | grep -v '^$' | sed 's/^/- ✓ /')" \
      "- Production deployment (separate human approval required)\n- Security/auth/billing changes (out of PM scope)" \
      "- Release impact: ${RELEASE_IMPACT:-Low}\n- Edge case: ${EDGE_CASE:-None noted}" \
      "- Story created at Triage status\n- Advisory: recommend UX review, then Architecture review before development" \
      "Advisory: Story meets §5 DoR. Ready for UX and Architecture review pipeline.")

    jira_comment "$KEY" "$PM_COMMENT" 2>/dev/null || true
    jira_transition "$KEY" "Triage" 2>/dev/null || true
    CREATED=$((CREATED + 1))
  else
    echo "PM Agent: Failed to create — $TITLE"
    echo "  Response: $(echo "$RESULT" | jq -r '.errors // .errorMessages // .')"
  fi

done <<< "$ANALYSIS"

echo ""
echo "PM Agent: $CREATED stories created, $SKIPPED skipped"
[ "$CREATED" -gt 0 ] && exit 2
exit 0
