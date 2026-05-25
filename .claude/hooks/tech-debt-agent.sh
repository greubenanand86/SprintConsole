#!/usr/bin/env bash
# Tech Debt Agent — Engineering Constitution §12
# Scans codebase for technical debt; creates/updates Jira tasks to track it
# §12: Debt must be visible, prioritized, and tracked in Jira

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Tech Debt Agent: Scanning codebase for technical debt"

# ── Check if we've already run today ──────────────────────────────────────
DEBT_MARKER="/tmp/sprintops-tech-debt-$(date +%Y%m%d).marker"
[ -f "$DEBT_MARKER" ] && exit 0

# ── Static scan: TODOs, FIXMEs, hardcoded values ──────────────────────────
TODO_COUNT=$(grep -rn 'TODO\|FIXME\|HACK\|XXX' "$REPO_ROOT" \
  --include="*.jsx" --include="*.js" --include="*.css" \
  --exclude-dir=vendor 2>/dev/null | wc -l | tr -d ' ')

HARDCODED_HEX=$(grep -rn '#[0-9a-fA-F]\{3,6\}' "$REPO_ROOT" \
  --include="*.jsx" --include="*.js" \
  --exclude-dir=vendor 2>/dev/null | grep -v 'colors_and_type' | wc -l | tr -d ' ')

# ── AI architectural debt analysis ────────────────────────────────────────
DEBT_ANALYSIS=$(claude --print \
"Role: You are the Tech Debt Analyst Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Scan the codebase and identify technical debt items. Produce structured findings for Jira tracking.

Inputs: Source files readable via Read, Glob, Grep, and Bash tools.

Engineering Constitution §12: Debt must be visible, prioritized, and tracked in Jira. Each sprint should reserve 15-20% capacity for debt reduction (§9).

Debt categories to scan:
1. Missing TypeScript (§2 mandates TS — app uses .jsx only)
2. Missing test suite (§6 mandates unit + integration tests)
3. Missing CI/CD pipeline (§8)
4. Components without loading/error/empty states (§3)
5. Business logic inside UI components (§3)
6. Duplicated logic or components (§1 Shared Architecture)
7. Missing accessibility attributes (§5)
8. Missing structured logging / error boundaries (§7)
9. Hardcoded values that should use design tokens
10. Oversized components (>300 lines without clear separation)

Output format: For each debt item output EXACTLY one pipe-separated line:
DEBT|<category>|<severity: HIGH|MEDIUM|LOW>|<specific finding>|<recommended fix>

Output up to 15 DEBT lines. Then output all standard fields.

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
  --allowedTools "Read,Glob,Grep,Bash" \
  --no-conversation 2>/dev/null)

extract_standard "$DEBT_ANALYSIS"
[ -n "$STD_SUMMARY" ] && echo "Tech Debt Agent: $STD_SUMMARY"

# ── Get existing tech debt issues to avoid duplicates ────────────────────
EXISTING_DEBT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+labels=tech-debt&maxResults=50&fields=summary")
EXISTING_SUMMARIES=$(echo "$EXISTING_DEBT" | jq -r '.issues[].fields.summary' 2>/dev/null | tr '[:upper:]' '[:lower:]')

TASK_TYPE_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Task") | .id' | head -1)
STORY_TYPE_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Story") | .id' | head -1)
FALLBACK_TYPE="${TASK_TYPE_ID:-$STORY_TYPE_ID}"

CREATED=0
SKIPPED=0

while IFS='|' read -r TYPE CATEGORY SEVERITY FINDING RECOMMENDED_FIX; do
  [ "$TYPE" != "DEBT" ] && continue
  [ -z "$FINDING" ] && continue

  SUMMARY="[Tech Debt] [$SEVERITY] $CATEGORY — $(echo "$FINDING" | cut -c1-60)"
  SUMMARY_LOWER=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]')

  if echo "$EXISTING_SUMMARIES" | grep -qi "$(echo "$CATEGORY" | cut -c1-20)"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  PAYLOAD=$(jq -n \
    --arg proj "$JIRA_PROJECT" \
    --arg typeid "$FALLBACK_TYPE" \
    --arg summary "$SUMMARY" \
    --arg finding "$FINDING" \
    --arg fix "$RECOMMENDED_FIX" \
    --arg severity "$SEVERITY" \
    --arg category "$CATEGORY" \
    '{
      "fields": {
        "project": {"key": $proj},
        "issuetype": {"id": $typeid},
        "summary": $summary,
        "labels": ["tech-debt"],
        "description": {
          "type": "doc", "version": 1,
          "content": [
            {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Tech Debt Finding"}]},
            {"type":"paragraph","content":[{"type":"text","text":"Category: ","marks":[{"type":"strong"}]},{"type":"text","text":$category}]},
            {"type":"paragraph","content":[{"type":"text","text":"Severity: ","marks":[{"type":"strong"}]},{"type":"text","text":$severity}]},
            {"type":"paragraph","content":[{"type":"text","text":"Finding: ","marks":[{"type":"strong"}]},{"type":"text","text":$finding}]},
            {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Recommended Fix"}]},
            {"type":"paragraph","content":[{"type":"text","text":$fix}]},
            {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Governance"}]},
            {"type":"paragraph","content":[{"type":"text","text":"Engineering Constitution §12: Technical debt must be visible, prioritized, and tracked. Each sprint should reserve capacity for debt reduction."}]}
          ]
        }
      }
    }')

  RESULT=$(jira_post "issue" "$PAYLOAD")
  KEY=$(echo "$RESULT" | jq -r '.key // "ERROR"')

  if [ "$KEY" != "ERROR" ] && [ "$KEY" != "null" ]; then
    echo "Tech Debt Agent: Created $KEY — [$SEVERITY] $CATEGORY"
    CREATED=$((CREATED + 1))
  fi

done <<< "$DEBT_ANALYSIS"

# ── Summary comment on known static findings ──────────────────────────────
if [ "$TODO_COUNT" -gt 0 ] || [ "$HARDCODED_HEX" -gt 0 ]; then
  echo "Tech Debt Agent: Static scan — $TODO_COUNT TODO/FIXME comments, $HARDCODED_HEX hardcoded hex values found"
fi

touch "$DEBT_MARKER"
echo "Tech Debt Agent: $CREATED new debt items created, $SKIPPED already tracked"
exit 0
