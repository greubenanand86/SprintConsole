#!/usr/bin/env bash
# Observability Agent — Engineering Constitution §7
# Checks "In Progress" stories for structured logging, error monitoring,
# crash reporting, and analytics instrumentation compliance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Observability Agent: Checking $COUNT in-progress stories for §7 compliance"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_OBS=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[OBSERVABILITY\]' || true)
  [ "$HAS_OBS" -gt 0 ] && continue

  OBS_SPEC=$(claude --print \
"You are an Observability Engineer reviewing a story for SprintOps Console.
Engineering Constitution §7 mandates: structured logging, error monitoring,
crash reporting, analytics instrumentation, and release tracking.

Story: $SUMMARY

Read the relevant .jsx files to understand the implementation context.

Check and specify observability requirements for this story. Output EXACTLY this format:

ERROR_BOUNDARIES:
- <where to wrap in React Error Boundary, or 'Not required — no async/remote data'>

LOGGING_SPEC:
- <what to log and at what level: ERROR / WARN / INFO>
- <structured fields to include: e.g., userId, storyId, action>

ANALYTICS_EVENTS:
- <user interaction to track, or 'None required'>

EMPTY_ERROR_STATES:
- <component: what empty state message to show>
- <component: what error state message to show>

COMPLIANCE: <PASS — requirements met|FAIL — gaps found>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  COMPLIANCE=$(echo "$OBS_SPEC" | grep '^COMPLIANCE:' | sed 's/^COMPLIANCE: //')

  COMMENT="[OBSERVABILITY] Observability Specification — §7

Error Boundaries:
$(echo "$OBS_SPEC" | sed -n '/^ERROR_BOUNDARIES:/,/^LOGGING_SPEC:/p' | grep '^-' | sed 's/^- /🛡 /')

Logging Spec:
$(echo "$OBS_SPEC" | sed -n '/^LOGGING_SPEC:/,/^ANALYTICS_EVENTS:/p' | grep '^-' | sed 's/^- /📋 /')

Analytics Events:
$(echo "$OBS_SPEC" | sed -n '/^ANALYTICS_EVENTS:/,/^EMPTY_ERROR_STATES:/p' | grep '^-' | sed 's/^- /📊 /')

Empty / Error States:
$(echo "$OBS_SPEC" | sed -n '/^EMPTY_ERROR_STATES:/,/^COMPLIANCE:/p' | grep '^-' | sed 's/^- /⚠ /')

Compliance: ${COMPLIANCE:-REVIEW REQUIRED}

Engineering Constitution §7: Mandatory — structured logging, error monitoring,
crash reporting, analytics instrumentation, and release tracking."

  jira_comment "$KEY" "$COMMENT"
  echo "Observability Agent: Spec posted for $KEY (${COMPLIANCE:-REVIEW REQUIRED})"

done
exit 0
