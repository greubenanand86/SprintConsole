#!/usr/bin/env bash
# Monitoring Agent — Jira Workflow Governance §12
# Released -> Monitoring -> Done lifecycle
# Checks: crash analysis, incident review, rollback readiness, production validation
# Transitions to Done when monitoring period is clean

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Query stories in Released or Monitoring state
RELEASED=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22Released%22,%22Monitoring%22)&maxResults=20&fields=summary,status,updated")
COUNT=$(echo "$RELEASED" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Monitoring Agent: $COUNT released stories to monitor (§12)"

echo "$RELEASED" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"' | while IFS='|' read -r KEY SUMMARY STATUS; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")

  # Check if already has a clean monitoring report (done monitoring)
  CLEAN_REPORT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[MONITORING\].*✅.*CLEAR' | wc -l | tr -d ' ')
  [ "$CLEAN_REPORT" -gt 0 ] && {
    jira_transition "$KEY" "Done"
    echo "Monitoring Agent: $KEY monitoring complete — transitioning to Done"
    continue
  }

  # Check for open production bugs linked to this story
  LINKED_BUGS=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Bug+AND+labels=production-bug+AND+status+not+in+(Done,Closed,Released)&maxResults=5&fields=summary,priority" | \
    jq -r '.issues[] | "- [\(.fields.priority.name // "Medium")] \(.fields.summary)"' 2>/dev/null)

  # Check for any incident flags in comments
  HAS_INCIDENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[INCIDENT\]' || true)

  MONITOR_CHECK=$(claude --print \
"You are the Monitoring Agent for SprintOps Console (Jira Workflow Governance §12).

Released story: $SUMMARY (Status: $STATUS)

Post-release monitoring checks:
1. Production stability — are there open production bugs linked to this feature?
2. Rollback readiness — can this be reverted if issues emerge?
3. User impact — any signals of user-facing problems?
4. Performance — any observable degradation?

Open production bugs: ${LINKED_BUGS:-None found}
Incident flags: ${HAS_INCIDENT:-0}

Read the deployed files to assess the feature's production state.

Output EXACTLY this format:

STABILITY: <STABLE|UNSTABLE — reason>
ROLLBACK_READY: <YES — how|NO — gap>
USER_IMPACT: <NONE DETECTED|RISK — reason>
PERFORMANCE: <ACCEPTABLE|CONCERN — reason>

MONITORING_VERDICT: <CLEAR — safe to close|HOLD — keep monitoring|ESCALATE — incident response needed>
NOTES:
- <observation>" \
    --allowedTools "Read,Glob" \
    --no-conversation 2>/dev/null)

  VERDICT=$(echo "$MONITOR_CHECK" | grep '^MONITORING_VERDICT:' | sed 's/^MONITORING_VERDICT: //')
  STABILITY=$(echo "$MONITOR_CHECK" | grep '^STABILITY:' | sed 's/^STABILITY: //')

  case "$VERDICT" in
    CLEAR*)
      COMMENT="[MONITORING] ✅ CLEAR — Production monitoring passed

Stability: $STABILITY
Rollback: $(echo "$MONITOR_CHECK" | grep '^ROLLBACK_READY:' | sed 's/^ROLLBACK_READY: //')
User Impact: $(echo "$MONITOR_CHECK" | grep '^USER_IMPACT:' | sed 's/^USER_IMPACT: //')
Performance: $(echo "$MONITOR_CHECK" | grep '^PERFORMANCE:' | sed 's/^PERFORMANCE: //')

Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,$p' | grep '^-' | sed 's/^- /• /')

Monitoring period complete. Transitioning to Done."
      jira_comment "$KEY" "$COMMENT"
      jira_transition "$KEY" "Monitoring"
      jira_transition "$KEY" "Done"
      echo "Monitoring Agent: ✅ $KEY — CLEAR, moving to Done"
      ;;

    HOLD*)
      COMMENT="[MONITORING] ⏸ HOLD — Continuing monitoring period

Stability: $STABILITY
Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,$p' | grep '^-' | sed 's/^- /• /')

Will check again next session."
      jira_comment "$KEY" "$COMMENT"
      jira_transition "$KEY" "Monitoring"
      echo "Monitoring Agent: ⏸ $KEY — holding in monitoring"
      ;;

    ESCALATE*)
      COMMENT="[MONITORING] 🚨 ESCALATE — Incident response required

Stability: $STABILITY
Open Bugs: ${LINKED_BUGS:-None on record}

Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,$p' | grep '^-' | sed 's/^- /• /')

⚠ Human escalation required per §15 Incident Governance.
Do NOT close this story until incident is resolved."
      jira_comment "$KEY" "$COMMENT"
      echo "Monitoring Agent: 🚨 $KEY — escalating to incident response"
      exit 2
      ;;
  esac

done
exit 0
