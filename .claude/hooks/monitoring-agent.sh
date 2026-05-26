#!/usr/bin/env bash
# Monitoring Agent — Per Agent Role Specifications v1.0 §8 and Incident Management Playbook v1.0
# Mission: Observe post-release health and detect production issues early
# Authority: Alert and recommend action; cannot trigger rollback or close incidents autonomously
# Usage: monitoring-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find stories in Released or Monitoring state
  RELEASED=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22Released%22,%22Monitoring%22)&maxResults=20&fields=summary,status,updated" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$RELEASED" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[MONITORING] Auto-scan: $COUNT stories in Released/Monitoring state"
  echo "$RELEASED" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"' | \
  while IFS='|' read -r K SUMMARY STATUS; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story monitoring
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,updated" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATUS=$(echo "$ISSUE" | jq -r '.fields.status.name // "Unknown"')
UPDATED=$(echo "$ISSUE" | jq -r '.fields.updated // "Unknown"')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=100" 2>/dev/null || echo '{"comments":[]}')

# Check if already cleared
CLEAR_REPORT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[MONITORING\].*✅.*CLEAR' | wc -l | tr -d ' ')
if [ "$CLEAR_REPORT" -gt 0 ]; then
  jira_transition "$KEY" "Done" 2>/dev/null || true
  echo "[MONITORING] $KEY already CLEAR — transitioning to Done"
  exit 0
fi

# Scan for production bugs linked to this story
LINKED_BUGS=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Bug+AND+labels=production-bug+AND+status+not+in+(Done,Closed)&maxResults=5&fields=summary,priority" 2>/dev/null | \
  jq -r '.issues[] | "  - [\(.fields.priority.name // "Medium")] \(.fields.summary)"' 2>/dev/null)
HAS_INCIDENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[INCIDENT\]' || true)

# --- Signals detection (heuristics from source/comments) ------------------
# Crash signals
CRASH_SIGNALS="None detected"
if echo "$COMMENTS" | grep -qi 'crash\|uncaught\|unhandled\|ReferenceError\|TypeError'; then
  CRASH_SIGNALS="⚠️ Crash-like terms found in comments — verify manually"
fi

# Error signals
ERROR_SIGNALS="None detected"
if echo "$COMMENTS" | grep -qi '500\|error boundary\|failed to fetch\|api.*error\|4[0-9][0-9]'; then
  ERROR_SIGNALS="⚠️ Error terms found in comments — verify API logs"
fi

# Performance signals
PERF_SIGNALS="No degradation detected"
if echo "$COMMENTS" | grep -qi 'slow\|timeout\|latency\|performance\|freeze'; then
  PERF_SIGNALS="⚠️ Performance concerns mentioned — check metrics dashboard"
fi

# Adoption signals
ADOPTION_SIGNALS="No anomaly"
if echo "$COMMENTS" | grep -qi 'not working\|broken\|bug report\|users complaining'; then
  ADOPTION_SIGNALS="⚠️ User complaint signals detected"
fi

# Determine verdict
VERDICT="CLEAR"
ESCALATION_NEEDED="No"

if [ -n "$LINKED_BUGS" ]; then
  VERDICT="HOLD"
fi
if echo "$CRASH_SIGNALS" | grep -q '⚠️'; then
  VERDICT="ESCALATE"
  ESCALATION_NEEDED="Yes"
fi
if [ "$HAS_INCIDENT" -gt 0 ]; then
  VERDICT="ESCALATE"
  ESCALATION_NEEDED="Yes"
fi

cat << EOF
[MONITORING] $KEY — $VERDICT

## 1. Monitoring Window
- Story: $KEY — $TITLE
- Status: $STATUS
- Monitoring Since: $UPDATED
- Checked At: $TIMESTAMP
- Active Incidents: ${HAS_INCIDENT:-0}

## 2. Health Summary
$(
  case "$VERDICT" in
    CLEAR)
      echo "  ✅ STABLE: No error signals, crashes, or production bugs detected"
      ;;
    HOLD)
      echo "  ⚠️ HOLD: Open production bugs linked — monitoring continues"
      echo "  Open Bugs:"
      echo "${LINKED_BUGS:-  None}"
      ;;
    ESCALATE)
      echo "  🚨 ESCALATE: Active crash or incident signals require immediate response"
      ;;
  esac
)

## 3. Error/Crash Signals
- Crash Signals: $CRASH_SIGNALS
- API/Error Signals: $ERROR_SIGNALS
- Active Incident Flags: ${HAS_INCIDENT:-0}
$([ -n "$LINKED_BUGS" ] && echo "- Linked Production Bugs:
$LINKED_BUGS")

## 4. Performance Signals
- Performance: $PERF_SIGNALS
- Auth/Auth Failures: Not detected (check auth logs separately)
- API Error Rate: Baseline (manual validation required without instrumentation)

## 5. User Impact
- Adoption Signal: $ADOPTION_SIGNALS
- User Complaints Detected: $(echo "$COMMENTS" | grep -qi 'users\|customers\|report' && echo "Possible signals in comments — review" || echo "None detected")
- Blast Radius: $([ "$VERDICT" = "ESCALATE" ] && echo "⚠️ Potentially broad — assess immediately" || echo "Contained")

## 6. Recommendation
$(
  case "$VERDICT" in
    CLEAR)
      echo "✅ PROCEED TO DONE: Monitoring window passed cleanly"
      echo "   - Transition: Released → Monitoring → Stable → Done"
      echo "   - No further monitoring required for this release"
      ;;
    HOLD)
      echo "⏸️ HOLD IN MONITORING: Open production bugs must be resolved"
      echo "   - Assign bugs to appropriate team"
      echo "   - Re-check after bugs are closed"
      echo "   - Do NOT close story until bugs are resolved"
      ;;
    ESCALATE)
      echo "🚨 ESCALATE TO INCIDENT RESPONSE AGENT"
      echo "   - Log production incident immediately"
      echo "   - Run: incident-agent.sh $KEY"
      echo "   - Notify on-call engineer"
      echo "   - Hold rollback SOP on standby"
      ;;
  esac
)

## 7. Escalation Needed?
$ESCALATION_NEEDED
$([ "$ESCALATION_NEEDED" = "Yes" ] && echo "  → Route to Incident Response Agent immediately
  → Per Incident Management Playbook v1.0 §3-§4
  → Human notification required for SEV-1/SEV-2")
$([ "$ESCALATION_NEEDED" = "No" ] && echo "  → Continue monitoring window per Release Management Playbook §8")

---
[Monitoring Agent] — Per Agent Role Specifications v1.0 §8 | INCIDENT_MANAGEMENT_PLAYBOOK v1.0
EOF

# Post comment and transition
if [ "$VERDICT" = "CLEAR" ]; then
  jira_comment "$KEY" "[MONITORING] ✅ CLEAR — post-release health check passed. Transitioning to Done. ($TIMESTAMP)" 2>/dev/null || true
  jira_transition "$KEY" "Stable" 2>/dev/null || true
  jira_transition "$KEY" "Done" 2>/dev/null || true
elif [ "$VERDICT" = "HOLD" ]; then
  jira_comment "$KEY" "[MONITORING] ⏸️ HOLD — open production bugs detected. Continuing monitoring. ($TIMESTAMP)" 2>/dev/null || true
  jira_transition "$KEY" "Monitoring" 2>/dev/null || true
elif [ "$VERDICT" = "ESCALATE" ]; then
  jira_comment "$KEY" "[MONITORING] 🚨 ESCALATE — crash/incident signals detected. Incident Agent required. ($TIMESTAMP)" 2>/dev/null || true
  escalate_to_tpm "$KEY" "Active crash or incident signal detected post-release. Incident Management Playbook §3 response required." "MONITORING AGENT" 2>/dev/null || true
fi
