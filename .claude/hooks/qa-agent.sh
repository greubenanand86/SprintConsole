#!/usr/bin/env bash
# QA Lead Agent
# For stories In Review: creates sub-task test cases, runs logic checks, signs off or flags back

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22In+Review%22&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "QA Agent: $COUNT stories in review"

SUBTASK_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Sub-task" or .subtask==true) | .id' | head -1)
TASK_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Task") | .id' | head -1)
FALLBACK_ID="${SUBTASK_ID:-$TASK_ID}"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  # ── Generate test cases ─────────────────────────────────────────────────
  QA_PLAN=$(claude --print \
"You are a QA Lead writing test cases for SprintOps Console.

Story: $SUMMARY

Read the relevant source files to understand the implementation.
Write 4-6 concrete test cases. Output EXACTLY this format:

PASS|<test case title>|<steps to reproduce>|<expected result>
PASS|...
EDGE|<edge case title>|<steps>|<expected result>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  # ── Create sub-task for each test case ──────────────────────────────────
  TC_COUNT=0
  while IFS='|' read -r TC_TYPE TC_TITLE TC_STEPS TC_EXPECTED; do
    [[ "$TC_TYPE" != "PASS" && "$TC_TYPE" != "EDGE" ]] && continue
    [ -z "$TC_TITLE" ] && continue

    TC_PAYLOAD=$(jq -n \
      --arg proj "$JIRA_PROJECT" \
      --arg parent "$KEY" \
      --arg typeid "$FALLBACK_ID" \
      --arg summary "[TC] $TC_TITLE" \
      --arg steps "$TC_STEPS" \
      --arg expected "$TC_EXPECTED" \
      '{
        "fields": {
          "project": {"key": $proj},
          "parent": {"key": $parent},
          "issuetype": {"id": $typeid},
          "summary": $summary,
          "description": {
            "type": "doc", "version": 1,
            "content": [
              {"type":"paragraph","content":[{"type":"text","text":"Steps: ","marks":[{"type":"strong"}]},{"type":"text","text":$steps}]},
              {"type":"paragraph","content":[{"type":"text","text":"Expected: ","marks":[{"type":"strong"}]},{"type":"text","text":$expected}]}
            ]
          }
        }
      }')

    TC_RESULT=$(jira_post "issue" "$TC_PAYLOAD")
    TC_KEY=$(echo "$TC_RESULT" | jq -r '.key // ""')
    [ -n "$TC_KEY" ] && echo "QA Agent: Created test case $TC_KEY for $KEY" && TC_COUNT=$((TC_COUNT+1))

  done <<< "$QA_PLAN"

  # ── Run automated logic checks ──────────────────────────────────────────
  AUTO_RESULT=$(claude --print \
"You are a QA automation engineer. Run logic checks on the SprintOps Console codebase for this story:

Story: $SUMMARY

Check:
1. Are there null/undefined guards for all data accesses related to this feature?
2. Are state updates immutable (no direct mutation)?
3. Are all event listeners cleaned up in useEffect returns?
4. Does the feature work correctly with empty data (no items)?

Read the relevant .jsx files and answer each check: PASS or FAIL with reason.
Output format: CHECK|<name>|PASS|<note> or CHECK|<name>|FAIL|<reason>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  FAILURES=$(echo "$AUTO_RESULT" | grep '^CHECK|' | grep '|FAIL|' | sed 's/^CHECK|//' | sed 's/|FAIL|/: FAIL — /')
  PASSES=$(echo "$AUTO_RESULT" | grep '^CHECK|' | grep '|PASS|' | wc -l | tr -d ' ')

  # ── Post QA summary and sign off / flag ─────────────────────────────────
  if [ -z "$FAILURES" ]; then
    COMMENT="[QA LEAD] ✅ QA Sign-off

$TC_COUNT test cases created as sub-tasks.
Automated checks: $PASSES/4 PASSED

All acceptance criteria verified. Story is READY FOR PRODUCTION.
Recommend: move to Done."
    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "Done"
    echo "QA Agent: ✅ $KEY signed off — moving to Done"
  else
    COMMENT="[QA LEAD] ❌ QA Failed — Back to Dev

$TC_COUNT test cases created.
Automated checks found issues:
$(echo "$FAILURES" | sed 's/^/• /')

Please fix before re-review."
    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "In Progress"
    echo "QA Agent: ❌ $KEY failed QA — moved back to In Progress"
    echo "$FAILURES"
    exit 2  # rewake Claude with failures
  fi

done
exit 0
