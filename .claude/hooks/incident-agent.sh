#!/usr/bin/env bash
# Incident Agent — Jira Workflow Governance §15
# Production incidents require: severity classification, rollback assessment,
# root cause tracking, postmortem documentation
# Incident learnings stored in Product Memory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="$REPO_ROOT/PRODUCT_MEMORY.md"

# Query open production bugs (label: production-bug)
INCIDENTS=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Bug+AND+labels=production-bug+AND+status+not+in+(Done,Closed)+ORDER+BY+priority+ASC&maxResults=10&fields=summary,priority,status,description")
COUNT=$(echo "$INCIDENTS" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Incident Agent: $COUNT open production incidents (§15)"

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
POSTMORTEMS=""

echo "$INCIDENTS" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.priority.name // "Medium")|\(.fields.status.name)"' | \
while IFS='|' read -r KEY SUMMARY PRIORITY STATUS; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=30")
  HAS_INCIDENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[INCIDENT\]' || true)
  [ "$HAS_INCIDENT" -gt 0 ] && continue

  INCIDENT_ANALYSIS=$(claude --print \
"You are the Incident Agent for SprintOps Console (Jira Workflow Governance §15).

Production incident: $SUMMARY
Priority: $PRIORITY
Status: $STATUS

Per §15, production incidents require:
1. Severity classification (P0=service down, P1=major degradation, P2=degraded, P3=minor)
2. Rollback assessment — can this be reverted, and how?
3. Root cause identification
4. Postmortem documentation
5. Learnings to prevent recurrence

Read the codebase and assess the incident.

Output EXACTLY this format:

SEVERITY: <P0|P1|P2|P3>
SEVERITY_RATIONALE: <why>
AFFECTED_COMPONENT: <file/feature name>
ROOT_CAUSE: <concise root cause>
ROLLBACK_POSSIBLE: <YES — steps|NO — reason>
IMMEDIATE_ACTION: <what should be done right now>
CONTRIBUTING_FACTORS:
- <factor>
PREVENTION:
- <action to prevent recurrence>
POSTMORTEM_SUMMARY: <1-2 sentence summary for Product Memory>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  SEVERITY=$(echo "$INCIDENT_ANALYSIS" | grep '^SEVERITY:' | sed 's/^SEVERITY: //' | tr -d '[:space:]')
  ROOT_CAUSE=$(echo "$INCIDENT_ANALYSIS" | grep '^ROOT_CAUSE:' | sed 's/^ROOT_CAUSE: //')
  ROLLBACK=$(echo "$INCIDENT_ANALYSIS" | grep '^ROLLBACK_POSSIBLE:' | sed 's/^ROLLBACK_POSSIBLE: //')
  IMMEDIATE=$(echo "$INCIDENT_ANALYSIS" | grep '^IMMEDIATE_ACTION:' | sed 's/^IMMEDIATE_ACTION: //')
  POSTMORTEM=$(echo "$INCIDENT_ANALYSIS" | grep '^POSTMORTEM_SUMMARY:' | sed 's/^POSTMORTEM_SUMMARY: //')

  # Severity icon
  case "$SEVERITY" in
    P0) ICON="🔴" ;;
    P1) ICON="🟠" ;;
    P2) ICON="🟡" ;;
    P3) ICON="🟢" ;;
    *)  ICON="⚪" ;;
  esac

  COMMENT="[INCIDENT] $ICON $SEVERITY — $SUMMARY

Severity: $SEVERITY — $(echo "$INCIDENT_ANALYSIS" | grep '^SEVERITY_RATIONALE:' | sed 's/^SEVERITY_RATIONALE: //')
Affected: $(echo "$INCIDENT_ANALYSIS" | grep '^AFFECTED_COMPONENT:' | sed 's/^AFFECTED_COMPONENT: //')
Root Cause: $ROOT_CAUSE
Rollback: $ROLLBACK

⚡ Immediate Action: $IMMEDIATE

Contributing Factors:
$(echo "$INCIDENT_ANALYSIS" | sed -n '/^CONTRIBUTING_FACTORS:/,/^PREVENTION:/p' | grep '^-' | sed 's/^- /• /')

Prevention Actions:
$(echo "$INCIDENT_ANALYSIS" | sed -n '/^PREVENTION:/,/^POSTMORTEM_SUMMARY:/p' | grep '^-' | sed 's/^- /• /')

$([ "$SEVERITY" = "P0" ] || [ "$SEVERITY" = "P1" ] && echo "⚠ HIGH SEVERITY — Human escalation required per §15. Do NOT close without postmortem sign-off.")"

  jira_comment "$KEY" "$COMMENT"
  echo "Incident Agent: $ICON $KEY [$SEVERITY] — $ROOT_CAUSE"

  # Accumulate postmortem for Product Memory
  POSTMORTEMS="$POSTMORTEMS
- $KEY [$SEVERITY] ($TIMESTAMP): $POSTMORTEM
  Root cause: $ROOT_CAUSE | Rollback: $ROLLBACK"

done

# Store incident learnings in Product Memory (§15)
if [ -n "$POSTMORTEMS" ] && [ -f "$MEMORY_FILE" ]; then
  {
    echo ""
    echo "## Incident Learnings — $TIMESTAMP"
    echo ""
    echo "### Production Incidents (§15)"
    echo "$POSTMORTEMS"
    echo ""
    echo "---"
  } >> "$MEMORY_FILE"

  git -C "$REPO_ROOT" add PRODUCT_MEMORY.md 2>/dev/null
  git -C "$REPO_ROOT" diff --cached --quiet || \
    git -C "$REPO_ROOT" commit -m "chore: record incident learnings in Product Memory [§15]" 2>/dev/null
fi

exit 0
