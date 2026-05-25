#!/usr/bin/env bash
# Incident Agent — Jira Workflow Governance §15 | Release Management Playbook §9
# Production incidents require: severity classification, rollback assessment,
# root cause tracking, postmortem documentation, post-release validation
# Hotfix governance (Playbook §9): incident classification + rollback awareness +
#   post-release validation + postmortem documentation
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
"Role: You are the Incident Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Analyze this production incident, classify its severity, identify root cause, assess rollback options, and document learnings for the postmortem.

Inputs:
- Incident: $SUMMARY
- Priority: $PRIORITY
- Status: $STATUS
- Source files readable via Read, Glob, and Grep tools

Per §15 and Release Management Playbook §9, production incidents require ALL of:
1. Severity classification (P0=service down, P1=major degradation, P2=degraded, P3=minor)
2. Rollback awareness — is a hotfix or revert viable? Who owns the rollback?
3. Root cause identification — what specifically caused this?
4. Post-release validation plan — what checks confirm the fix is working after deploy?
5. Postmortem documentation — learning recorded in Product Memory

Playbook §9 hotfix governance (applies if incident requires a hotfix/* branch):
- Hotfix must branch from main
- Hotfix requires Release Risk review before merging
- Hotfix requires TPM + Human approval per Playbook §3
- Postmortem must be completed and recorded

Output format — output EXACTLY these sections:

SEVERITY: <P0|P1|P2|P3>
SEVERITY_RATIONALE: <why this severity level>
AFFECTED_COMPONENT: <file or feature name>
ROOT_CAUSE: <concise root cause — plain language>
ROLLBACK_POSSIBLE: <YES — steps|NO — reason>
ROLLBACK_OWNER: <who should execute the rollback>
HOTFIX_REQUIRED: <YES — describe scope|NO — explain>
POST_RELEASE_VALIDATION:
- <check 1 to verify fix is working after deploy>
- <check 2>
IMMEDIATE_ACTION: <what should be done right now>
CONTRIBUTING_FACTORS:
- <factor>
PREVENTION:
- <action to prevent recurrence>
POSTMORTEM_SUMMARY: <1-2 sentence summary for Product Memory>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  SEVERITY=$(echo "$INCIDENT_ANALYSIS" | grep '^SEVERITY:' | sed 's/^SEVERITY: //' | tr -d '[:space:]')
  ROOT_CAUSE=$(echo "$INCIDENT_ANALYSIS" | grep '^ROOT_CAUSE:' | sed 's/^ROOT_CAUSE: //')
  ROLLBACK=$(echo "$INCIDENT_ANALYSIS" | grep '^ROLLBACK_POSSIBLE:' | sed 's/^ROLLBACK_POSSIBLE: //')
  ROLLBACK_OWNER=$(echo "$INCIDENT_ANALYSIS" | grep '^ROLLBACK_OWNER:' | sed 's/^ROLLBACK_OWNER: //')
  HOTFIX_REQUIRED=$(echo "$INCIDENT_ANALYSIS" | grep '^HOTFIX_REQUIRED:' | sed 's/^HOTFIX_REQUIRED: //')
  IMMEDIATE=$(echo "$INCIDENT_ANALYSIS" | grep '^IMMEDIATE_ACTION:' | sed 's/^IMMEDIATE_ACTION: //')
  POSTMORTEM=$(echo "$INCIDENT_ANALYSIS" | grep '^POSTMORTEM_SUMMARY:' | sed 's/^POSTMORTEM_SUMMARY: //')
  extract_standard "$INCIDENT_ANALYSIS"

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
Rollback Owner: ${ROLLBACK_OWNER:-Not identified — assign immediately}

⚡ Immediate Action: $IMMEDIATE

Post-Release Validation (confirm fix is working — Playbook §9):
$(echo "$INCIDENT_ANALYSIS" | sed -n '/^POST_RELEASE_VALIDATION:/,/^IMMEDIATE_ACTION:/p' | grep '^-' | sed 's/^- /☐ /')

Contributing Factors:
$(echo "$INCIDENT_ANALYSIS" | sed -n '/^CONTRIBUTING_FACTORS:/,/^PREVENTION:/p' | grep '^-' | sed 's/^- /• /')

Prevention Actions:
$(echo "$INCIDENT_ANALYSIS" | sed -n '/^PREVENTION:/,/^POSTMORTEM_SUMMARY:/p' | grep '^-' | sed 's/^- /• /')

$([ "$SEVERITY" = "P0" ] || [ "$SEVERITY" = "P1" ] && echo "⚠ HIGH SEVERITY — Human escalation required per §15. Do NOT close without postmortem sign-off.")
$(echo "$HOTFIX_REQUIRED" | grep -qi '^YES' && echo "
🔧 HOTFIX REQUIRED (Release Management Playbook §9):
→ Branch hotfix/* from main
→ Requires Release Risk review before merging to main
→ Requires TPM + Human approval (Playbook §3)
→ Complete post-release validation checks above
→ Postmortem must be documented and signed off before closing")
$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"
  echo "Incident Agent: $ICON $KEY [$SEVERITY] — $ROOT_CAUSE"

  # Escalate P0/P1 and hotfix-required incidents to TPM
  if [ "$SEVERITY" = "P0" ] || [ "$SEVERITY" = "P1" ]; then
    escalate_to_tpm "$KEY" \
      "$SEVERITY production incident: $ROOT_CAUSE. Release Management Playbook §9 + §15: human escalation required. Postmortem mandatory." \
      "INCIDENT AGENT"
  fi
  if echo "$HOTFIX_REQUIRED" | grep -qi '^YES'; then
    escalate_to_tpm "$KEY" \
      "Hotfix required for $SEVERITY incident. Playbook §9: hotfix/* branch from main, Release Risk review, TPM + Human approval, postmortem required." \
      "INCIDENT AGENT"
  fi

  # Accumulate postmortem for Product Memory
  POSTMORTEMS="$POSTMORTEMS
- $KEY [$SEVERITY] ($TIMESTAMP): $POSTMORTEM
  Root cause: $ROOT_CAUSE | Rollback: $ROLLBACK | Hotfix required: ${HOTFIX_REQUIRED:-Unknown}"

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
