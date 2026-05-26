#!/usr/bin/env bash

# TPM Agent — Technical Program Manager
# Mission: Coordinate agents, translate technical risk, maintain advisory-first governance
# Governs: Agent Role Specifications v1.0 §1, Governance Clarifications §2, TIER_1_AGENT_PROMPTS.md §1
# Authority: Recommend (not approve) production releases; escalate conflicts; coordinate agents
# Advisory-first model: Agents recommend; humans execute; no autonomous workflow movement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# Read input (Jira issue context passed on stdin)
INPUT=$(cat)
JIRA_KEY=$(echo "$INPUT" | jq -r '.key // .issue_key // ""' 2>/dev/null || echo "")
STORY_STATUS=$(echo "$INPUT" | jq -r '.fields.status.name // ""' 2>/dev/null || echo "")
STORY_SUMMARY=$(echo "$INPUT" | jq -r '.fields.summary // ""' 2>/dev/null || echo "")

[ -z "$JIRA_KEY" ] && exit 0

# Fetch agent verdicts from Jira comments
COMMENTS=$(jira_get "issue/$JIRA_KEY/comments?maxResults=100" 2>/dev/null || echo '{"comments":[]}')
ALL_COMMENTS=$(echo "$COMMENTS" | jq -r '.comments[]?.body // ""' 2>/dev/null | tr '\n' '|')

# Parse agent verdicts (Green/Yellow/Red, Pass/Fail, etc.)
SECURITY_VERDICT=$(echo "$ALL_COMMENTS" | grep -o '\[SECURITY[^]]*\]' | tail -1 | grep -o 'PASS\|FAIL\|BLOCKED\|REVIEW' | head -1 || echo "PENDING")
QA_VERDICT=$(echo "$ALL_COMMENTS" | grep -o '\[QA LEAD[^]]*\]' | tail -1 | grep -o 'PASS\|FAIL\|BLOCKED' | head -1 || echo "PENDING")
RELEASE_RISK=$(echo "$ALL_COMMENTS" | grep -o '\[RELEASE RISK[^]]*\]' | tail -1 | grep -o 'Green\|Yellow\|Red' | head -1 || echo "PENDING")
ARCHITECTURE=$(echo "$ALL_COMMENTS" | grep -o '\[ARCHITECT[^]]*\]' | tail -1 | grep -o 'PASS\|FAIL\|BLOCKED' | head -1 || echo "PENDING")
UX_VERDICT=$(echo "$ALL_COMMENTS" | grep -o '\[UX AGENT[^]]*\]' | tail -1 | grep -o 'PASS\|FAIL\|BLOCKED' | head -1 || echo "PENDING")
PM_VERDICT=$(echo "$ALL_COMMENTS" | grep -o '\[PRODUCT MANAGER[^]]*\]' | tail -1 | grep -o 'PASS\|FAIL\|BLOCKED' | head -1 || echo "PENDING")

# Identify blockers (Decision Hierarchy: Security > Stability > UX > Product > Maintainability > Speed)
BLOCKERS=()
RISKS=()

[ "$SECURITY_VERDICT" = "BLOCKED" ] && BLOCKERS+=("Security Agent") && RISKS+=("Security concern detected")
[ "$QA_VERDICT" = "BLOCKED" ] && BLOCKERS+=("QA Lead Agent") && RISKS+=("Acceptance criteria not met")
[ "$RELEASE_RISK" = "Red" ] && BLOCKERS+=("Release Risk Agent") && RISKS+=("High-risk release detected")
[ "$ARCHITECTURE" = "BLOCKED" ] && BLOCKERS+=("Architecture Agent") && RISKS+=("Architectural concerns")
[ "$PM_VERDICT" = "BLOCKED" ] && BLOCKERS+=("Product Manager Agent") && RISKS+=("Product value not validated")

[ "$RELEASE_RISK" = "Yellow" ] && RISKS+=("Staged rollout recommended")

# Determine recommendation based on Decision Hierarchy
RECOMMENDATION="PROCEED"
if [ ${#BLOCKERS[@]} -gt 0 ]; then
  RECOMMENDATION="BLOCKED"
elif [ "$RELEASE_RISK" = "Yellow" ]; then
  RECOMMENDATION="PROCEED_WITH_CAUTION"
fi

# Check if this is a production release story
IS_RELEASE=$(echo "$STORY_STATUS" | grep -i "Ready for Release\|Released" | wc -l)
HUMAN_APPROVAL_NEEDED="No"
if [ "$IS_RELEASE" -gt 0 ] && [ "$RECOMMENDATION" != "BLOCKED" ]; then
  HUMAN_APPROVAL_NEEDED="Yes"
fi

# Generate TPM structured output
OUTPUT="[TPM AGENT]

## Executive Summary
$(case "$RECOMMENDATION" in
  PROCEED) echo "✅ Ready to proceed" ;;
  PROCEED_WITH_CAUTION) echo "⚠️ Proceed with staged rollout" ;;
  BLOCKED) echo "🛑 Blocked — escalation required" ;;
esac)

## Current Status
- Security: $SECURITY_VERDICT
- QA: $QA_VERDICT
- Release Risk: $RELEASE_RISK
- Architecture: $ARCHITECTURE
- UX: $UX_VERDICT
- Product Value: $PM_VERDICT

## Risks
$([ ${#RISKS[@]} -gt 0 ] && printf "- %s\n" "${RISKS[@]}" || echo "None identified")

## Blockers
$([ ${#BLOCKERS[@]} -gt 0 ] && printf "- %s\n" "${BLOCKERS[@]}" || echo "None")

## Agent Inputs Needed
$([ "$SECURITY_VERDICT" = "PENDING" ] && echo "- Security Agent review")
$([ "$QA_VERDICT" = "PENDING" ] && echo "- QA Lead validation")
$([ "$RELEASE_RISK" = "PENDING" ] && echo "- Release Risk assessment")
$([ "$ARCHITECTURE" = "PENDING" ] && echo "- Architecture review")

## Recommended Action
$(case "$RECOMMENDATION" in
  PROCEED) echo "Release ready. Proceed to production deployment with human sign-off." ;;
  PROCEED_WITH_CAUTION) echo "Release with staged rollout (Release Risk Agent recommended). Coordinate phased deployment with Deploy Agent." ;;
  BLOCKED) echo "Cannot proceed. Resolve blocking agent concerns before release consideration." ;;
esac)

## Human Approval Needed?
$HUMAN_APPROVAL_NEEDED
$([ "$HUMAN_APPROVAL_NEEDED" = "Yes" ] && echo "(Production deployment requires human sign-off per Governance Clarifications §I)")"

echo "$OUTPUT"

# Write Jira comment
jira_comment "$JIRA_KEY" "$OUTPUT" 2>/dev/null || echo "$OUTPUT"

exit 0
