#!/usr/bin/env bash
# Analytics Agent — Per Agent Role Specifications v1.0 §17
# Mission: Ensure product usage, release health, and key workflow signals are measurable
# Authority: Recommend instrumentation; cannot add tracking that violates privacy/compliance
# Usage: analytics-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: stories in QA or Ready for Release (validate analytics before ship)
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22Ready+for+QA%22,%22QA+In+Progress%22,%22Ready+for+Release%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[ANALYTICS] Auto-scan: $COUNT stories approaching release"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story analytics spec
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "In Progress"')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50" 2>/dev/null || echo '{"comments":[]}')
HAS_ANALYTICS=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[ANALYTICS\]' || true)
[ "$HAS_ANALYTICS" -gt 0 ] && { echo "[ANALYTICS] $KEY already reviewed — skipping"; exit 0; }

# Detect analytics signal type
IS_FEATURE=$(echo "$TITLE" | grep -iE 'feature|add|create|implement|new' && echo "yes" || echo "no")
IS_UX=$(echo "$TITLE" | grep -iE 'ui|view|page|modal|form|button|flow|onboard' && echo "yes" || echo "no")
IS_SPRINT=$(echo "$TITLE" | grep -iE 'sprint|velocity|capacity|readiness|estimation|release' && echo "yes" || echo "no")
IS_ERROR=$(echo "$TITLE" | grep -iE 'error|crash|fail|bug|fix' && echo "yes" || echo "no")

# Build event name prefix
PREFIX="sprintops"

cat << EOF
[ANALYTICS] $KEY — Instrumentation Spec

## 1. Analytics Objective
- Story: $KEY — $TITLE
- Status: $STATE
- Goal: Prove the feature is working and delivering value (Product Constitution §8)
- Measure: What metric confirms users are adopting and succeeding with this feature?

Key question: What does success look like in 2 weeks?

## 2. Events Needed
$(
  if [ "$IS_FEATURE" = "yes" ] || [ "$IS_UX" = "yes" ]; then
    echo "Feature Lifecycle Events:"
    echo "  1. Feature viewed — when user sees this feature"
    echo "  2. Feature engaged — when user takes the primary action"
    echo "  3. Feature completed — when user finishes the workflow"
    echo "  4. Error encountered — when feature fails (with error type)"
    echo ""
    echo "  Optional (if high-traffic or conversion-critical):"
    echo "  5. Feature abandoned — user started but didn't complete"
  fi
  if [ "$IS_SPRINT" = "yes" ]; then
    echo "Sprint Management Events:"
    echo "  1. Sprint view opened — which sprint, sprint status"
    echo "  2. Story status changed — from, to, sprint, user"
    echo "  3. Readiness check performed — sprint, readiness score"
    echo "  4. Estimation session started/completed — sprint, story count"
  fi
  if [ "$IS_ERROR" = "yes" ]; then
    echo "Error Health Events:"
    echo "  1. Error boundary triggered — component, error type"
    echo "  2. Retry attempted — context, outcome"
  fi
)

## 3. Event Names
Naming convention: ${PREFIX}.[object].[action] (all lowercase, underscores allowed)

$(
  if [ "$IS_UX" = "yes" ]; then
    OBJ=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]+' | head -1)
    echo "Recommended events for this story:"
    echo "  ${PREFIX}.${OBJ:-feature}.viewed"
    echo "  ${PREFIX}.${OBJ:-feature}.clicked"
    echo "  ${PREFIX}.${OBJ:-feature}.completed"
    echo "  ${PREFIX}.${OBJ:-feature}.error"
  fi

  echo ""
  echo "Rules (prevent naming drift):"
  echo "  ✅ ${PREFIX}.[noun].[verb] — e.g., sprintops.story.created"
  echo "  ❌ click_button       — too generic, missing context"
  echo "  ❌ SPRINT_UPDATED     — uppercase, inconsistent naming"
  echo "  ❌ on_feature_shown   — 'on_' prefix is noise"
)

## 4. Properties
Standard properties (always included):
  - timestamp    — ISO 8601 UTC
  - session_id   — anonymous session identifier
  - user_id      — authenticated user ID (hashed if PII risk — see §5)
  - platform     — web | ios | android
  - app_version  — current release version

Feature-specific properties:
$(
  [ "$IS_SPRINT" = "yes" ] && echo "  - sprint_id        — sprint identifier
  - sprint_status    — active | completed | planning
  - story_count      — number of stories in sprint"

  [ "$IS_UX" = "yes" ] && echo "  - source           — which page/context triggered the event
  - interaction_type — click | keyboard | touch"

  [ "$IS_ERROR" = "yes" ] && echo "  - error_code       — machine-readable error identifier
  - error_message    — sanitized (no PII or credentials)
  - component        — which component triggered the error"
)

## 5. Privacy Considerations
$(
  echo "Privacy checks (METRICS_DASHBOARD_FRAMEWORK v1.0 + Legal & Compliance Governance v1.0):"
  echo ""
  echo "  □ No PII in event properties:"
  echo "    - Do NOT send: email, name, IP address, raw user ID (hash it)"
  echo "    - DO send: hashed user ID, anonymous session ID, aggregated counts"
  echo "  □ User consent:"
  echo "    - Analytics requires user consent if covered by GDPR/CCPA"
  echo "    - Verify consent mechanism in place before enabling tracking"
  echo "  □ Data retention:"
  echo "    - Analytics events should have defined retention period (90-365 days)"
  echo "    - Do NOT store sensitive operational data in analytics"
  echo "  □ Third-party analytics SDK:"
  echo "    - New analytics SDK requires Legal & Compliance Agent review"
  echo "    - Verify DPA with analytics vendor"
  echo ""
  if echo "$TITLE" | grep -iE 'learner|student|education'; then
    echo "  ⚠️ LEARNER DATA: FERPA/COPPA may restrict analytics for minor users — escalate to Legal"
  fi
)

## 6. Dashboard Impact
Per METRICS_DASHBOARD_FRAMEWORK v1.0 — which dashboards does this affect?
$(
  [ "$IS_SPRINT" = "yes" ] && echo "  - TPM Dashboard: Sprint velocity, delivery metrics"
  [ "$IS_FEATURE" = "yes" ] && echo "  - Product Dashboard: Feature adoption, engagement rates"
  [ "$IS_UX" = "yes" ] && echo "  - Product Dashboard: UX friction signals, conversion"
  [ "$IS_ERROR" = "yes" ] && echo "  - Engineering Dashboard: Error rate, crash rate"
  echo ""
  echo "  After shipping:"
  echo "    → Add event to relevant dashboard panel"
  echo "    → Set baseline threshold for alerting"
  echo "    → Review in next sprint review meeting"
)

## 7. Recommendation
$(
  if [ "$IS_FEATURE" = "yes" ] || [ "$IS_UX" = "yes" ]; then
    echo "✅ INSTRUMENT THIS FEATURE"
    echo ""
    echo "Minimum required events before shipping:"
    echo "  1. Feature viewed / started"
    echo "  2. Feature completed / success"
    echo "  3. Error encountered (typed error codes)"
    echo ""
    echo "Anti-patterns to avoid:"
    echo "  - Tracking every micro-interaction (noise > signal)"
    echo "  - Event names that change meaning over time"
    echo "  - Missing the terminal outcome event (did user succeed?)"
  else
    echo "⏸️ REVIEW REQUIRED"
    echo ""
    echo "Analytics need identified but confirmation required."
    echo "Coordinate with Product Manager to define success metric."
  fi
)

---
[Analytics Agent] — Per Agent Role Specifications v1.0 §17 | METRICS_DASHBOARD_FRAMEWORK v1.0
NOTE: Cannot add tracking that violates privacy/compliance rules. Legal & Compliance Agent review required for new SDKs.
EOF

jira_comment "$KEY" "[ANALYTICS] 📊 Analytics instrumentation spec prepared.
Events, naming conventions, privacy checks, and dashboard impact documented.
[Analytics Agent]" 2>/dev/null || true
