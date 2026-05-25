#!/usr/bin/env bash
# Release Risk Agent — governance §9
# Assesses deployment risk for Done stories: Green / Yellow / Red
# Green = proceed, Yellow = staged rollout recommended, Red = block

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(Done,%22Ready+for+Release%22)+AND+updated>=-1h&maxResults=20&fields=summary,labels")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Skip if first story already has a risk assessment
FIRST_KEY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
[ -z "$FIRST_KEY" ] && exit 0

COMMENTS=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50")
HAS_RISK=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[RELEASE RISK\]' || true)
[ "$HAS_RISK" -gt 0 ] && exit 0

echo "Release Risk Agent: Assessing risk for $COUNT stories"

STORY_LIST=$(echo "$DONE_STORIES" | jq -r '.issues[] | "- \(.key): \(.fields.summary)"')

RISK_ASSESSMENT=$(claude --print \
"Role: You are the Release Risk Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Assess the overall deployment risk for this release. Output a risk level (GREEN/YELLOW/RED) with rationale, rollback plan, and monitoring checklist.

Inputs:
- Stories in this release:
$STORY_LIST
- Source files readable via Read, Glob, and Grep tools

Risk factors to evaluate:
1. Scope and number of changes
2. Security-sensitive areas touched (auth, PII, payments, integrations)
3. Data model or breaking changes
4. Test coverage and QA sign-off completeness
5. Rollback feasibility (can changes be reverted cleanly?)
6. Monitoring availability post-deploy

Output format — output EXACTLY these sections:

RISK_LEVEL: <GREEN|YELLOW|RED>

RATIONALE:
- <reason 1>
- <reason 2>

AFFECTED_SYSTEMS:
- <system or component>

ROLLBACK_PLAN:
- <step 1>
- <step 2>

MONITORING_CHECKLIST:
- <what to verify post-deploy>

RECOMMENDATION: <PROCEED|STAGED_ROLLOUT|BLOCK>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX

$NONTECHNICAL_SUMMARY_REQ" \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

RISK_LEVEL=$(echo "$RISK_ASSESSMENT" | grep '^RISK_LEVEL:' | sed 's/^RISK_LEVEL: //')
RECOMMENDATION=$(echo "$RISK_ASSESSMENT" | grep '^RECOMMENDATION:' | sed 's/^RECOMMENDATION: //')
extract_standard "$RISK_ASSESSMENT"
NON_TECH=$(echo "$RISK_ASSESSMENT" | sed -n '/^NON_TECHNICAL_SUMMARY:/,/^SUMMARY:/p' | head -8)

case "$RISK_LEVEL" in
  GREEN)  RISK_ICON="✅" ;;
  YELLOW) RISK_ICON="⚠️" ;;
  RED)    RISK_ICON="🚫" ;;
  *)      RISK_ICON="❓" ; RISK_LEVEL="UNKNOWN" ;;
esac

COMMENT="[RELEASE RISK] $RISK_ICON Risk Level: $RISK_LEVEL

Rationale:
$(echo "$RISK_ASSESSMENT" | sed -n '/^RATIONALE:/,/^AFFECTED_SYSTEMS:/p' | grep '^-' | sed 's/^- /• /')

Affected Systems:
$(echo "$RISK_ASSESSMENT" | sed -n '/^AFFECTED_SYSTEMS:/,/^ROLLBACK_PLAN:/p' | grep '^-' | sed 's/^- /• /')

Rollback Plan:
$(echo "$RISK_ASSESSMENT" | sed -n '/^ROLLBACK_PLAN:/,/^MONITORING_CHECKLIST:/p' | grep '^-' | sed 's/^- /→ /')

Monitoring Checklist:
$(echo "$RISK_ASSESSMENT" | sed -n '/^MONITORING_CHECKLIST:/,/^RECOMMENDATION:/p' | grep '^-' | sed 's/^- /☐ /')

Recommendation: ${RECOMMENDATION:-STAGED_ROLLOUT}

GOVERNANCE NOTE: Per §4 and §9, human approval is required before production
deployment regardless of risk level. A RED assessment blocks deployment entirely.
${NON_TECH:+
Non-Technical Summary:
$NON_TECH}
$(standard_fields_block)"

echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  jira_comment "$KEY" "$COMMENT"
done

# Write risk level for deploy-agent to consume
echo "$RISK_LEVEL" > /tmp/sprintops-release-risk.txt

echo "Release Risk Agent: Level=$RISK_LEVEL Recommendation=${RECOMMENDATION:-STAGED_ROLLOUT}"

if [ "$RISK_LEVEL" = "RED" ]; then
  echo "Release Risk Agent: 🚫 RED — deployment blocked. Human escalation required per §10."
  exit 2
fi
exit 0
