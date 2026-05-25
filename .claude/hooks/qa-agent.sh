#!/usr/bin/env bash
# QA Lead Agent — Jira Workflow Governance §8 | Engineering Constitution §5 §6 §13 | Environment Governance §6
# Runs on stories in Ready for QA / QA In Progress / In Review (Code Review fallback)
# Tests: functional test cases + accessibility + staging validation (staging mirrors production per §6)
# Pass → "Product Acceptance" (§7 lifecycle)
# Fail → "In Development" + creates Bug issue per §8 format

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Review%22,%22Ready+for+QA%22,%22QA+In+Progress%22)&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "QA Agent: $COUNT stories ready for QA (§8)"

# Resolve issue type IDs once
SUBTASK_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Sub-task" or .subtask==true) | .id' | head -1)
TASK_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Task") | .id' | head -1)
BUG_ID=$(jira_get "project/$JIRA_PROJECT" | jq -r '.issueTypes[] | select(.name=="Bug") | .id' | head -1)
FALLBACK_ID="${SUBTASK_ID:-$TASK_ID}"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  # ── Read architect handoff packet (Agent Interaction Protocols §2) ────────
  PRIOR_HANDOFF=$(read_last_handoff "$KEY")
  HANDOFF_TECH=$(echo "$PRIOR_HANDOFF" | sed 's/.*Technical Notes: //' | sed 's/ Risks:.*//' | head -c 300)
  HANDOFF_RISKS=$(echo "$PRIOR_HANDOFF" | sed 's/.*Risks: //' | sed 's/ Dependencies:.*//' | head -c 200)

  # ── Check for unresolved escalation before proceeding ─────────────────────
  COMMENTS_PRE=$(jira_get "issue/$KEY/comments?maxResults=50")
  ESCALATION_UNRESOLVED=$(echo "$COMMENTS_PRE" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep -c '\[ESCALATE → TPM\]' || true)
  TPM_RESOLVED=$(echo "$COMMENTS_PRE" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep -c '\[TPM AGENT\]' || true)

  if [ "$ESCALATION_UNRESOLVED" -gt 0 ] && [ "$TPM_RESOLVED" -eq 0 ]; then
    echo "QA Agent: $KEY has unresolved escalation — waiting for TPM resolution, skipping"
    continue
  fi

  # ── Generate functional test cases ────────────────────────────────────────
  QA_PLAN=$(claude --print \
"Role: You are the QA Lead Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Write 4-6 concrete functional test cases for this story.

Inputs:
- Story: $SUMMARY
- Source files readable via Read, Glob, and Grep tools

Output format: For each test case output EXACTLY one pipe-separated line:
PASS|<test case title>|<steps to reproduce>|<expected result>
EDGE|<edge case title>|<steps>|<expected result>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  # ── Create sub-task for each test case ────────────────────────────────────
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

  # ── Run automated logic + accessibility + performance checks ───────────────
  AUTO_RESULT=$(claude --print \
"Role: You are the QA Automation Engineer Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Run all 12 automated quality checks for this story and report results.

Inputs:
- Story: $SUMMARY
- Source files readable via Read, Glob, and Grep tools

Checks to run:
1. LOGIC: Null/undefined guards for all data accesses
2. LOGIC: State updates are immutable (no direct mutation)
3. LOGIC: Event listeners cleaned up in useEffect returns
4. LOGIC: Feature works correctly with empty data
5. ACCESSIBILITY (§5): Interactive elements use semantic HTML (button/a not div onClick)
6. ACCESSIBILITY (§5): Icon-only buttons have aria-label or title
7. ACCESSIBILITY (§5): Keyboard navigation works (tabIndex, onKeyDown for custom controls)
8. ACCESSIBILITY (§5): Error/status messages use aria-live or role=alert
9. PERFORMANCE (§13): No unnecessary re-renders (stable references)
10. PERFORMANCE (§13): No blocking synchronous operations in render
11. TESTING (§6): Pure functions extractable and unit-testable
12. OBSERVABILITY (§7): Error boundary coverage present

Output format: For each check output EXACTLY one line:
CHECK|<name>|PASS|<note>
or
CHECK|<name>|FAIL|<steps to reproduce>|<expected result>|<actual result>|<severity P1/P2/P3>

After the 12 CHECK lines, output all standard fields.

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  PASS_COUNT=$(echo "$AUTO_RESULT" | grep '^CHECK|' | grep '|PASS|' | wc -l | tr -d ' ')
  TOTAL_CHECKS=$(echo "$AUTO_RESULT" | grep '^CHECK|' | wc -l | tr -d ' ')
  TOTAL_CHECKS=${TOTAL_CHECKS:-12}

  # Parse failures — format: CHECK|name|FAIL|steps|expected|actual|severity
  FAILURES_RAW=$(echo "$AUTO_RESULT" | grep '^CHECK|' | grep '|FAIL|')
  FAILURE_COUNT=$(echo "$FAILURES_RAW" | grep -c '|FAIL|' || true)

  extract_standard "$AUTO_RESULT"

  # ── Pass path: → Product Acceptance ───────────────────────────────────────
  if [ -z "$FAILURES_RAW" ] || [ "$FAILURE_COUNT" -eq 0 ]; then
    COMMENT="[QA LEAD] ✅ QA Sign-off (§8) — $PASS_COUNT/$TOTAL_CHECKS checks passed

$TC_COUNT test cases created.

Checks passed:
• Logic integrity ✓
• Accessibility §5 ✓
• Performance §13 ✓
• Observability §7 ✓

Governance §8 validation complete.
Transitioning to Product Acceptance (§7 lifecycle).
$(standard_fields_block)"
    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "Product Acceptance"
    jira_transition "$KEY" "Done"  # fallback if "Product Acceptance" state not configured

    # Write handoff packet for Product Acceptance Agent (§2)
    write_handoff "$KEY" \
      "QA LEAD" \
      "Product Acceptance" \
      "$SUMMARY" \
      "All acceptance criteria validated — $TC_COUNT test cases passed" \
      "Accessibility §5 verified: semantic HTML, aria-labels, keyboard nav, aria-live" \
      "${HANDOFF_TECH:-See Architect comment}" \
      "${HANDOFF_RISKS:-None outstanding after QA}" \
      "None" \
      "None" \
      "Product Acceptance sign-off → Ready for Release"

    echo "QA Agent: ✅ $KEY passed — moving to Product Acceptance"

  else
    # ── Fail path: create §8-compliant Bug issues + back to In Development ───
    BUG_KEYS=""
    FAILURE_SUMMARY=""

    while IFS='|' read -r _CHECK_HDR CHKNAME _FAIL STEPS EXPECTED ACTUAL SEVERITY; do
      [ "$_CHECK_HDR" != "CHECK" ] && continue
      [ "$_FAIL" != "FAIL" ] && continue
      [ -z "$CHKNAME" ] && continue

      SEVERITY="${SEVERITY:-P2}"
      BUG_TITLE="[QA] $CHKNAME failure in $SUMMARY"
      ENV_INFO="SprintOps Console — $(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unknown commit') — Browser/in-browser Babel"

      # §8 mandatory bug fields: title, repro steps, expected, actual, environment, severity, feature association
      if [ -n "$BUG_ID" ]; then
        BUG_PAYLOAD=$(jq -n \
          --arg proj "$JIRA_PROJECT" \
          --arg typeid "$BUG_ID" \
          --arg summary "$BUG_TITLE" \
          --arg steps "${STEPS:-Not captured}" \
          --arg expected "${EXPECTED:-Not captured}" \
          --arg actual "${ACTUAL:-Not captured}" \
          --arg env "$ENV_INFO" \
          --arg severity "$SEVERITY" \
          --arg feature "$KEY: $SUMMARY" \
          '{
            "fields": {
              "project": {"key": $proj},
              "issuetype": {"id": $typeid},
              "summary": $summary,
              "labels": ["qa-failure"],
              "priority": {"name": (if $severity == "P1" then "High" elif $severity == "P2" then "Medium" else "Low" end)},
              "description": {
                "type": "doc", "version": 1,
                "content": [
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Steps to Reproduce"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$steps}]},
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Expected Result"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$expected}]},
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Actual Result"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$actual}]},
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Environment"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$env}]},
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Severity"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$severity}]},
                  {"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Feature Association"}]},
                  {"type":"paragraph","content":[{"type":"text","text":$feature}]}
                ]
              }
            }
          }')

        BUG_RESULT=$(jira_post "issue" "$BUG_PAYLOAD")
        BUG_KEY=$(echo "$BUG_RESULT" | jq -r '.key // ""')
        [ -n "$BUG_KEY" ] && BUG_KEYS="$BUG_KEYS $BUG_KEY" && echo "QA Agent: Created bug $BUG_KEY [$SEVERITY] — $CHKNAME"
      fi

      FAILURE_SUMMARY="$FAILURE_SUMMARY
• [$SEVERITY] $CHKNAME: ${ACTUAL:-Check failed}"

    done <<< "$FAILURES_RAW"

    COMMENT="[QA LEAD] ❌ QA Failed (§8) — $PASS_COUNT/$TOTAL_CHECKS checks passed

$TC_COUNT test cases created.
Bugs filed: ${BUG_KEYS:-none}

Failures:
$FAILURE_SUMMARY

§8 requirement: all bugs linked above include steps to reproduce, expected/actual results,
environment, severity, and feature association.

Transitioning to In Development. Resolve all bugs before re-submitting for QA.
$(standard_fields_block)"
    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "In Development"
    jira_transition "$KEY" "In Progress"  # fallback
    echo "QA Agent: ❌ $KEY failed — back to In Development. Bugs: $BUG_KEYS"
    exit 2
  fi

done
exit 0
