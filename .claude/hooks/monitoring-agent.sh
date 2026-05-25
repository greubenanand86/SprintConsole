#!/usr/bin/env bash
# Monitoring Agent — Incident Management Playbook v1.0 | Jira Workflow Governance §12 | Release Management Playbook §8 | Environment Governance §12
# Incident Workflow §3: Incident Detected → Severity Classification → Containment → Rollback Assessment → Resolution → Monitoring → Postmortem
# Detects production incidents (SEV-1/2/3/4 per Incident Playbook §2) and routes to Incident Agent
# Released -> Monitoring -> Stable -> Done lifecycle (Playbook §8) with mandatory post-release checks
# Environment Governance §12: Mandatory monitoring in Staging + Production
#   - Structured logging (JSON), crash reporting, real-time alerts, analytics validation
#   - Post-release window: crashes, API failures, auth issues, performance, analytics
# Release Management Playbook §8: Crashes, API failures, auth issues, performance degradation, analytics anomalies
# Transitions: Released → Monitoring (active watch) → Stable (clean pass) → Done

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
"Role: You are the Monitoring Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Assess the production health of this released feature and determine the monitoring verdict.

Inputs:
- Released story: $SUMMARY (Status: $STATUS)
- Open production bugs: ${LINKED_BUGS:-None found}
- Incident flags: ${HAS_INCIDENT:-0}
- Source files readable via Read and Glob tools

Release Management Playbook §8 mandatory post-release monitoring checks:
1. Crashes — are there crash reports or error boundaries being triggered?
2. API failures — are API calls failing or returning error rates above baseline?
3. Auth issues — are there authentication or authorization failures?
4. Performance degradation — are response times or rendering times significantly worse?
5. Analytics anomalies — are analytics events missing, doubled, or reporting unexpected values?

Additional checks per §12:
6. Production stability — are there open production bugs linked to this feature?
7. Rollback readiness — can this be reverted if issues emerge?
8. User impact — any signals of user-facing problems?

Monitoring lifecycle (Playbook §8): Released → Monitoring → Stable → Done
- CLEAR verdict moves story to Stable (then Done once stable window passes)
- HOLD verdict keeps in Monitoring for another check cycle
- ESCALATE verdict triggers incident response per §15

Output format — output EXACTLY these sections:

CRASHES: <NONE DETECTED|DETECTED — details>
API_FAILURES: <NONE DETECTED|DETECTED — details>
AUTH_ISSUES: <NONE DETECTED|DETECTED — details>
PERFORMANCE: <ACCEPTABLE|DEGRADED — details>
ANALYTICS: <NORMAL|ANOMALY — details>
STABILITY: <STABLE|UNSTABLE — reason>
ROLLBACK_READY: <YES — how|NO — gap>
USER_IMPACT: <NONE DETECTED|RISK — reason>

MONITORING_VERDICT: <CLEAR — safe to mark Stable|HOLD — keep monitoring|ESCALATE — incident response needed>
NOTES:
- <observation>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read,Glob" \
    --no-conversation 2>/dev/null)

  VERDICT=$(echo "$MONITOR_CHECK" | grep '^MONITORING_VERDICT:' | sed 's/^MONITORING_VERDICT: //')
  STABILITY=$(echo "$MONITOR_CHECK" | grep '^STABILITY:' | sed 's/^STABILITY: //')
  extract_standard "$MONITOR_CHECK"

  case "$VERDICT" in
    CLEAR*)
      COMMENT="[MONITORING] ✅ CLEAR — Production monitoring passed (Release Management Playbook §8)

Crashes: $(echo "$MONITOR_CHECK" | grep '^CRASHES:' | sed 's/^CRASHES: //')
API Failures: $(echo "$MONITOR_CHECK" | grep '^API_FAILURES:' | sed 's/^API_FAILURES: //')
Auth Issues: $(echo "$MONITOR_CHECK" | grep '^AUTH_ISSUES:' | sed 's/^AUTH_ISSUES: //')
Performance: $(echo "$MONITOR_CHECK" | grep '^PERFORMANCE:' | sed 's/^PERFORMANCE: //')
Analytics: $(echo "$MONITOR_CHECK" | grep '^ANALYTICS:' | sed 's/^ANALYTICS: //')
Stability: $STABILITY
Rollback: $(echo "$MONITOR_CHECK" | grep '^ROLLBACK_READY:' | sed 's/^ROLLBACK_READY: //')
User Impact: $(echo "$MONITOR_CHECK" | grep '^USER_IMPACT:' | sed 's/^USER_IMPACT: //')

Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,/^SUMMARY:/p' | grep '^-' | sed 's/^- /• /')

Monitoring period complete. Transitioning: Monitoring → Stable → Done (Playbook §8).
$(standard_fields_block)"
      jira_comment "$KEY" "$COMMENT"
      jira_transition "$KEY" "Monitoring"
      jira_transition "$KEY" "Stable"
      jira_transition "$KEY" "Done"
      echo "Monitoring Agent: ✅ $KEY — CLEAR, moving Monitoring → Stable → Done"
      ;;

    HOLD*)
      COMMENT="[MONITORING] ⏸ HOLD — Continuing monitoring period

Stability: $STABILITY
Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,/^SUMMARY:/p' | grep '^-' | sed 's/^- /• /')

Will check again next session.
$(standard_fields_block)"
      jira_comment "$KEY" "$COMMENT"
      jira_transition "$KEY" "Monitoring"
      echo "Monitoring Agent: ⏸ $KEY — holding in monitoring"
      ;;

    ESCALATE*)
      COMMENT="[MONITORING] 🚨 ESCALATE — Incident response required

Stability: $STABILITY
Open Bugs: ${LINKED_BUGS:-None on record}

Notes:
$(echo "$MONITOR_CHECK" | sed -n '/^NOTES:/,/^SUMMARY:/p' | grep '^-' | sed 's/^- /• /')

⚠ Human escalation required per §15 Incident Governance.
Do NOT close this story until incident is resolved.
$(standard_fields_block)"
      jira_comment "$KEY" "$COMMENT"
      echo "Monitoring Agent: 🚨 $KEY — escalating to incident response"
      exit 2
      ;;
  esac

done
exit 0
