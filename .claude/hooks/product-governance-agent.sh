#!/usr/bin/env bash
# Product Governance Agent — Product Constitution §4
# Reviews "To Do" stories against product governance questions:
# who benefits, problem solved, why now, maintenance cost, duplicate check
# Advisory only — per §9, agents suggest improvements, do not block autonomously

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22To+Do%22,%22Idea+%2F+Request%22,%22Triage%22,%22Product+Discovery%22)&maxResults=20&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Fetch full backlog for duplicate detection
ALL_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT&maxResults=100&fields=summary,status")
BACKLOG_SUMMARIES=$(echo "$ALL_STORIES" | jq -r '.issues[].fields.summary' 2>/dev/null)

echo "Product Governance Agent: Reviewing $COUNT stories against §4 governance"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_GOV=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[PRODUCT GOVERNANCE\]' || true)
  [ "$HAS_GOV" -gt 0 ] && continue

  GOV_REVIEW=$(claude --print \
"Role: You are the Product Governance Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Evaluate this story against Product Constitution §4 governance questions and §1 simplicity principle.

Inputs:
- Story to evaluate: $SUMMARY
- Existing backlog (for duplicate detection):
$(echo "$BACKLOG_SUMMARIES" | head -50 | sed 's/^/- /')

Product Constitution §10 Decision Hierarchy:
1. User trust  2. Accessibility  3. Stability  4. Simplicity
5. Maintainability  6. Speed of delivery  7. Feature expansion

Output format — output EXACTLY these fields:

WHO_BENEFITS: <specific user persona, 'All users', or 'Unknown — needs clarification'>
PROBLEM_SOLVED: <the user problem being addressed>
WHY_NOW: <urgency or roadmap alignment, or 'Not justified — recommend deferring'>
MAINTENANCE_COST: <LOW|MEDIUM|HIGH — brief reason>
DUPLICATE_RISK: <YES — similar to: <story name>|NO — unique value>
SIMPLICITY_ASSESSMENT: <PASS — appropriately scoped|FLAG — may introduce unnecessary complexity>
ANALYTICS_VALUE: <metric that proves this feature is working>

GOVERNANCE_VERDICT: <APPROVED — clear value|DEFER — unclear value|FLAG — needs discussion>
GOVERNANCE_NOTES:
- <note 1>
- <note 2>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  VERDICT=$(echo "$GOV_REVIEW" | grep '^GOVERNANCE_VERDICT:' | sed 's/^GOVERNANCE_VERDICT: //')
  DUP=$(echo "$GOV_REVIEW" | grep '^DUPLICATE_RISK:' | grep -i 'YES' | wc -l | tr -d ' ')

  case "$VERDICT" in
    APPROVED*) VERDICT_ICON="✅" ;;
    DEFER*)    VERDICT_ICON="⏸" ;;
    FLAG*)     VERDICT_ICON="🚩" ;;
    *)         VERDICT_ICON="❓" ;;
  esac

  COMMENT="[PRODUCT GOVERNANCE] $VERDICT_ICON Product Governance Review — §4

Who Benefits: $(echo "$GOV_REVIEW" | grep '^WHO_BENEFITS:' | sed 's/^WHO_BENEFITS: //')
Problem Solved: $(echo "$GOV_REVIEW" | grep '^PROBLEM_SOLVED:' | sed 's/^PROBLEM_SOLVED: //')
Why Now: $(echo "$GOV_REVIEW" | grep '^WHY_NOW:' | sed 's/^WHY_NOW: //')
Maintenance Cost: $(echo "$GOV_REVIEW" | grep '^MAINTENANCE_COST:' | sed 's/^MAINTENANCE_COST: //')
Duplicate Risk: $(echo "$GOV_REVIEW" | grep '^DUPLICATE_RISK:' | sed 's/^DUPLICATE_RISK: //')
Simplicity: $(echo "$GOV_REVIEW" | grep '^SIMPLICITY_ASSESSMENT:' | sed 's/^SIMPLICITY_ASSESSMENT: //')
Analytics Value: $(echo "$GOV_REVIEW" | grep '^ANALYTICS_VALUE:' | sed 's/^ANALYTICS_VALUE: //')

Verdict: ${VERDICT:-REVIEW REQUIRED}

Governance Notes:
$(echo "$GOV_REVIEW" | sed -n '/^GOVERNANCE_NOTES:/,$p' | grep '^-' | sed 's/^- /• /')

Product Constitution §4: Features approved only if they solve a meaningful problem,
align with roadmap, maintain coherence, and do not create unnecessary complexity.
§9: This assessment is advisory — human product owner has final authority."

  extract_standard "$GOV_REVIEW"
  COMMENT="$COMMENT
$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"
  echo "Product Governance Agent: $KEY reviewed ($VERDICT_ICON $VERDICT)"

done
exit 0
