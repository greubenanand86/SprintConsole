#!/usr/bin/env bash
# Incident Response Agent — Per Agent Role Specifications v1.0 §9 and Incident Management Playbook v1.0
# Mission: Coordinate incident understanding, severity classification, rollback recommendation, postmortem creation
# Authority: Recommend rollback; cannot execute without human approval; cannot close incidents without validation
# Usage: incident-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="${PRODUCT_MEMORY_FILE:-$REPO_ROOT/products/sprintconsole/PRODUCT_MEMORY.md}"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find open production bugs
  INCIDENTS=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Bug+AND+labels=production-bug+AND+status+not+in+(Done,Closed)+ORDER+BY+priority+ASC&maxResults=10&fields=summary,priority,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$INCIDENTS" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[INCIDENT] Auto-scan: $COUNT open production incidents"
  echo "$INCIDENTS" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-incident mode
ISSUE=$(jira_get "issue/$KEY?fields=summary,priority,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
PRIORITY=$(echo "$ISSUE" | jq -r '.fields.priority.name // "Medium"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "Open"')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50" 2>/dev/null || echo '{"comments":[]}')

# Skip if already assessed
HAS_INCIDENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[INCIDENT\]' || true)
if [ "$HAS_INCIDENT" -gt 0 ]; then
  echo "[INCIDENT] $KEY already assessed — skipping"
  exit 0
fi

# --- Severity mapping (Incident Playbook §2) --------------------------------
# P0/Critical → SEV-1 (outage), P1/High → SEV-2, P2/Medium → SEV-3, P3/Low → SEV-4
case "$PRIORITY" in
  Highest|Critical|P0) SEV="SEV-1"; ICON="🔴" ;;
  High|P1)             SEV="SEV-2"; ICON="🟠" ;;
  Medium|P2)           SEV="SEV-3"; ICON="🟡" ;;
  Low|P3|Lowest)       SEV="SEV-4"; ICON="🟢" ;;
  *)                   SEV="SEV-3"; ICON="🟡" ;;
esac

# --- Rollback assessment from git ------------------------------------------
ROLLBACK_POSSIBLE="Unknown"
ROLLBACK_STEPS=""
if git -C "$REPO_ROOT" rev-parse HEAD~1 >/dev/null 2>&1; then
  LAST_COMMIT=$(git -C "$REPO_ROOT" log --oneline -1 2>/dev/null || echo "")
  PREV_COMMIT=$(git -C "$REPO_ROOT" log --oneline -2 | tail -1 2>/dev/null || echo "")
  ROLLBACK_POSSIBLE="Yes"
  ROLLBACK_STEPS="git revert HEAD (last: $LAST_COMMIT)"
else
  ROLLBACK_POSSIBLE="Needs verification"
fi

# --- Determine impact scope ------------------------------------------------
HOTFIX_REQUIRED="Unknown"
if [ "$SEV" = "SEV-1" ] || [ "$SEV" = "SEV-2" ]; then
  HOTFIX_REQUIRED="Yes (hotfix/* branch from main required)"
else
  HOTFIX_REQUIRED="Evaluate — may be a fix in next sprint cycle"
fi

# --- Human approval requirements -------------------------------------------
HUMAN_APPROVAL_NEEDED="Yes"  # Always Yes per spec

cat << EOF
[INCIDENT] $ICON $KEY — $SEV

## 1. Incident Summary
- Story/Bug: $KEY — $TITLE
- Jira Priority: $PRIORITY
- Status: $STATE
- Detected: $TIMESTAMP

## 2. Severity
$SEV — $(
  case "$SEV" in
    SEV-1) echo "CRITICAL: Production outage or major data risk (immediate response required)" ;;
    SEV-2) echo "HIGH: Major feature degradation (escalate within 1 hour)" ;;
    SEV-3) echo "MEDIUM: Partial degradation (address within 4 hours)" ;;
    SEV-4) echo "LOW: Minor issue (address in next sprint)" ;;
  esac
)

Classification basis:
- Jira Priority: $PRIORITY → mapped to $SEV per Incident Playbook §2

## 3. Impact
$(
  case "$SEV" in
    SEV-1)
      echo "- User Impact: ⚠️ ALL USERS (production outage)"
      echo "- Data Risk: HIGH — assess data integrity immediately"
      echo "- Business Impact: Critical — revenue/trust at risk"
      echo "- Blast Radius: 100% of users"
      ;;
    SEV-2)
      echo "- User Impact: ⚠️ MAJOR PORTION of users affected"
      echo "- Data Risk: Moderate — validate affected flows"
      echo "- Business Impact: High — key feature unavailable"
      echo "- Blast Radius: Likely broad"
      ;;
    SEV-3)
      echo "- User Impact: PARTIAL — subset of users or edge case"
      echo "- Data Risk: Low"
      echo "- Business Impact: Moderate — workaround may exist"
      echo "- Blast Radius: Limited"
      ;;
    SEV-4)
      echo "- User Impact: MINIMAL — minor or cosmetic"
      echo "- Data Risk: None"
      echo "- Business Impact: Low"
      echo "- Blast Radius: Negligible"
      ;;
  esac
)

## 4. Suspected Cause
- Title analysis: $TITLE
- Component: To be confirmed via investigation
- Recent changes: $(git -C "$REPO_ROOT" log --oneline -5 2>/dev/null | sed 's/^/  /')
- Related code areas: Review recent commits for changes matching incident scope

Investigation steps:
1. Check error boundaries in sprintops-app.jsx
2. Review sprintops-data.js for data integrity issues
3. Inspect recent commits for logic changes
4. Reproduce in staging environment before fix

## 5. Recommended Action
$(
  case "$SEV" in
    SEV-1)
      echo "⚡ IMMEDIATE RESPONSE:"
      echo "  1. Page on-call engineer NOW"
      echo "  2. Assess if rollback is faster than hotfix"
      echo "  3. Initiate rollback if user trust is impacted (Incident Playbook §5)"
      echo "  4. Notify stakeholders"
      echo "  5. Begin root cause investigation in parallel"
      ;;
    SEV-2)
      echo "⚡ ESCALATE WITHIN 1 HOUR:"
      echo "  1. Alert team lead"
      echo "  2. Assess hotfix vs next release cycle"
      echo "  3. Prepare rollback SOP on standby"
      echo "  4. Communicate to affected users if possible"
      ;;
    SEV-3)
      echo "⏳ PLAN WITHIN 4 HOURS:"
      echo "  1. Create hotfix story (or add to sprint)"
      echo "  2. Confirm reproduction steps"
      echo "  3. Prepare fix with QA validation plan"
      ;;
    SEV-4)
      echo "📋 SCHEDULE IN SPRINT:"
      echo "  1. Add to bug backlog"
      echo "  2. Prioritize in next sprint planning"
      echo "  3. QA validation when fixed"
      ;;
  esac
)

## 6. Rollback Needed?
$(
  if [ "$SEV" = "SEV-1" ]; then
    echo "LIKELY YES: SEV-1 incidents should roll back unless hotfix is faster (Incident Playbook §5)"
    echo "Rollback Available: $ROLLBACK_POSSIBLE"
    echo "Rollback Steps: $ROLLBACK_STEPS"
  elif [ "$SEV" = "SEV-2" ]; then
    echo "EVALUATE: Rollback if degradation is widespread and hotfix takes >2h"
    echo "Rollback Available: $ROLLBACK_POSSIBLE"
    echo "Rollback Steps: $ROLLBACK_STEPS"
  else
    echo "Probably Not: Lower severity — monitor and fix forward"
    echo "Rollback Available: $ROLLBACK_POSSIBLE (if needed)"
  fi
)

Rollback Execution: REQUIRES HUMAN APPROVAL (cannot be executed autonomously)
$([ "$ROLLBACK_POSSIBLE" = "Yes" ] && echo "Rollback Command Ready: git revert HEAD (test in staging first)")

## 7. Human Approval Needed?
$HUMAN_APPROVAL_NEEDED
$(
  case "$SEV" in
    SEV-1) echo "  IMMEDIATE: Page on-call + Engineering Lead. Incident Playbook §4: human owns final rollback decision" ;;
    SEV-2) echo "  URGENT: Notify Engineering Lead within 1 hour" ;;
    SEV-3) echo "  REQUIRED: Engineering review before hotfix ships to production" ;;
    SEV-4) echo "  REQUIRED: Standard story approval flow applies" ;;
  esac
)

Hotfix Path (if required): Per Release Management Playbook §9 and Repository Governance:
  - Branch from: main → hotfix/$KEY
  - Requires: Release Risk review + TPM + Human approval
  - Postmortem: Required before closing $SEV incident

## 8. Postmortem Notes
Incident: $TITLE
Severity: $SEV | Priority: $PRIORITY | Detected: $TIMESTAMP

Root Cause: (to be determined during investigation)
Detection Gap: (how long between introduction and detection?)
Timeline:
  - $TIMESTAMP: Incident detected
  - [PENDING]: Investigation started
  - [PENDING]: Root cause identified
  - [PENDING]: Fix deployed
  - [PENDING]: Incident closed

Contributing Factors:
  - [ ] Code change not caught in QA
  - [ ] Missing error boundaries / monitoring
  - [ ] Insufficient regression coverage
  - [ ] Edge case not captured in acceptance criteria

Prevention Actions:
  - [ ] Add regression test for this scenario
  - [ ] Improve monitoring coverage for affected component
  - [ ] Update Definition of Done checklist if gap found

Learnings for Product Memory: Record after incident is resolved.
(Per Incident Management Playbook §6 — postmortem is mandatory for $SEV)

---
[Incident Response Agent] — Per Agent Role Specifications v1.0 §9 | INCIDENT_MANAGEMENT_PLAYBOOK v1.0
EOF

# Post comment to Jira
JIRA_BODY="[INCIDENT] $ICON $SEV — $TITLE

Severity: $SEV | Priority: $PRIORITY | Detected: $TIMESTAMP

Rollback Available: $ROLLBACK_POSSIBLE
Hotfix Required: $HOTFIX_REQUIRED

$([ "$SEV" = "SEV-1" ] || [ "$SEV" = "SEV-2" ] && echo "⚠ HIGH SEVERITY — Human escalation required per Incident Playbook §4. Postmortem mandatory.")

Next steps:
$(
  case "$SEV" in
    SEV-1) echo "→ Page on-call immediately
→ Assess rollback vs hotfix
→ Begin root cause investigation" ;;
    SEV-2) echo "→ Alert Engineering Lead within 1h
→ Prepare hotfix or rollback plan" ;;
    *) echo "→ Triage and assign to sprint
→ Fix with QA validation" ;;
  esac
)

Human approval required before any production action.
[Incident Response Agent]"

jira_comment "$KEY" "$JIRA_BODY" 2>/dev/null || true

# Escalate SEV-1 and SEV-2 to TPM (Incident Playbook §4)
if [ "$SEV" = "SEV-1" ] || [ "$SEV" = "SEV-2" ]; then
  escalate_to_tpm "$KEY" \
    "$SEV production incident: $TITLE. Incident Playbook §4: immediate human escalation required. Postmortem mandatory per §6. Rollback available: $ROLLBACK_POSSIBLE." \
    "INCIDENT AGENT" 2>/dev/null || true
fi

# Record in Product Memory if SEV-1 or SEV-2
if [ -f "$MEMORY_FILE" ] && { [ "$SEV" = "SEV-1" ] || [ "$SEV" = "SEV-2" ]; }; then
  {
    printf "\n## Incident Learning — %s\n\n" "$TIMESTAMP"
    printf "- %s [%s]: %s\n" "$KEY" "$SEV" "$TITLE"
    printf "  Priority: %s | Rollback: %s\n" "$PRIORITY" "$ROLLBACK_POSSIBLE"
    printf "  Postmortem: Pending — complete before closing\n"
    printf "\n---\n"
  } >> "$MEMORY_FILE"

  git -C "$REPO_ROOT" add "$MEMORY_FILE" 2>/dev/null || true
  git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null || \
    git -C "$REPO_ROOT" commit -m "chore: record $SEV incident in Product Memory [§9 §15]" 2>/dev/null || true
fi
