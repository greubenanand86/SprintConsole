#!/usr/bin/env bash
# Product Manager Agent
# 1. Reads existing Jira backlog
# 2. Runs gap analysis
# 3. Creates missing Stories with all governance-required fields (§5)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Fetch existing backlog ──────────────────────────────────────────────────
EXISTING=$(jira_get "search?jql=project=$JIRA_PROJECT+ORDER+BY+created+DESC&maxResults=100&fields=summary,status,issuetype")
EXISTING_TITLES=$(echo "$EXISTING" | jq -r '.issues[].fields.summary' 2>/dev/null | tr '[:upper:]' '[:lower:]')
ISSUE_COUNT=$(echo "$EXISTING" | jq '.total // 0')

echo "PM Agent: Found $ISSUE_COUNT existing issues in $JIRA_PROJECT"

# ── Read design spec from repo ─────────────────────────────────────────────
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESIGN_CONTEXT=$(cat "$REPO_ROOT/chats/chat1.md" 2>/dev/null | head -100)

# ── Ask Claude to do gap analysis and produce stories ─────────────────────
# Governance §5 + Product Constitution §4 §8:
# Stories must include business purpose, AC, UX considerations, edge cases,
# QA notes, release impact, and analytics instrumentation requirements.
ANALYSIS=$(claude --print \
"You are the Product Manager for SprintOps Console.
Governance §5 + Product Constitution §4 §8 apply.

Product Constitution §10 Decision Hierarchy:
1. User trust  2. Accessibility  3. Stability  4. Simplicity
5. Maintainability  6. Speed of delivery  7. Feature expansion

EXISTING JIRA ISSUES (already created — do NOT duplicate these):
$(echo "$EXISTING" | jq -r '.issues[] | "- [\(.fields.issuetype.name)] \(.key): \(.fields.summary)"' 2>/dev/null || echo 'None yet')

DESIGN SPEC CONTEXT:
The SprintOps Console has 4 pages:
1. Readiness Tracker — work items grid, TaskCell (Dev/QA/UAT/Post/Link), ReadinessMeter, tab filters, state/type dropdowns
2. Estimation Planner — Dev/QA/UAT hour estimates, auto-calc (QA=25% UAT=15% of Dev), override/reset, Save to ADO
3. Release Readiness — release task cards, product/type/version badges, Generate Scope, Create Post-Deploy, stat cards
4. Configuration — ADO Connection, Iteration, Field Mapping, Task Rules, Readiness Rules, Estimation Rules, Grouping

TASK: Gap analysis — produce stories for missing features.

Each story MUST include all of:
- Business purpose (§4: why this matters — who benefits, what problem)
- Acceptance criteria
- UX considerations (§2: clarity, recoverability, loading/empty/error states)
- Edge cases
- QA notes
- Release impact
- Analytics event (§8: what metric proves this feature is working?)

For each story output EXACTLY this pipe-separated format (one story per line):
STORY|<title>|<business purpose>|<as a user I want to...>|<ac 1>;<ac 2>;<ac 3>|<ux consideration>|<edge case>|<qa note>|<release impact>|<analytics event to track>

Only output stories NOT already in the existing issues list. Output 8-12 stories. No extra text." \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

# ── Get issue type IDs ─────────────────────────────────────────────────────
ISSUE_TYPES=$(jira_get "project/$JIRA_PROJECT" | jq '.issueTypes // []')
STORY_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[] | select(.name=="Story") | .id' | head -1)
EPIC_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[] | select(.name=="Epic") | .id' | head -1)

if [ -z "$STORY_TYPE_ID" ]; then
  STORY_TYPE_ID=$(echo "$ISSUE_TYPES" | jq -r '.[0].id' | head -1)
fi

# ── Create Epic first ──────────────────────────────────────────────────────
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

while IFS='|' read -r TYPE TITLE BIZ_PURPOSE USER_STORY AC_RAW UX_NOTE EDGE_CASE QA_NOTE RELEASE_IMPACT ANALYTICS_EVENT; do
  [ "$TYPE" != "STORY" ] && continue
  [ -z "$TITLE" ] && continue

  if echo "$EXISTING_TITLES" | grep -qi "$(echo "$TITLE" | cut -c1-30)"; then
    echo "PM Agent: Skipping (exists): $TITLE"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Format acceptance criteria as ADF bullet list
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
        {"type":"paragraph","content":[{"type":"text","text":$analytics}]}
      ]
    }')

  PAYLOAD=$(jq -n \
    --arg proj "$JIRA_PROJECT" \
    --arg typeid "$STORY_TYPE_ID" \
    --arg summary "$TITLE" \
    --argjson desc "$DESCRIPTION" \
    '{
      "fields": {
        "project": {"key": $proj},
        "issuetype": {"id": $typeid},
        "summary": $summary,
        "description": $desc
      }
    }')

  RESULT=$(jira_post "issue" "$PAYLOAD")
  KEY=$(echo "$RESULT" | jq -r '.key // "ERROR"')

  if [ "$KEY" != "ERROR" ] && [ "$KEY" != "null" ]; then
    echo "PM Agent: Created $KEY — $TITLE"
    CREATED=$((CREATED + 1))
  else
    echo "PM Agent: Failed to create — $TITLE"
    echo "  Response: $(echo "$RESULT" | jq -r '.errors // .errorMessages // .')"
  fi

done <<< "$ANALYSIS"

echo ""
echo "PM Agent complete: $CREATED stories created, $SKIPPED skipped (already existed)"

if [ "$CREATED" -gt 0 ]; then
  echo "Gap analysis and story creation done — $CREATED new stories added to $JIRA_PROJECT backlog"
  exit 2
fi
exit 0
