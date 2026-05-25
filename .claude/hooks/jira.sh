#!/usr/bin/env bash
# Shared Jira helpers — sourced by all agent scripts

JIRA_AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_TOKEN" | base64)

jira_get() {
  curl -s -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_post() {
  curl -s -X POST \
       -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d "$2" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_put() {
  curl -s -X PUT \
       -H "Authorization: Basic $JIRA_AUTH" \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d "$2" \
       "$JIRA_URL/rest/api/3/$1"
}

jira_transition() {
  # $1 = issue key, $2 = transition name (case-insensitive)
  local ISSUE="$1" TARGET="$2"
  local TRANSITIONS
  TRANSITIONS=$(jira_get "issue/$ISSUE/transitions")
  local TID
  TID=$(echo "$TRANSITIONS" | jq -r --arg name "$TARGET" \
    '.transitions[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .id' | head -1)
  if [ -n "$TID" ]; then
    jira_post "issue/$ISSUE/transitions" "{\"transition\":{\"id\":\"$TID\"}}" > /dev/null
    echo "Transitioned $ISSUE to $TARGET"
  else
    echo "Warning: transition '$TARGET' not found for $ISSUE"
  fi
}

jira_comment() {
  # $1 = issue key, $2 = comment body text
  local BODY
  BODY=$(jq -n --arg text "$2" '{
    "body": {
      "type": "doc", "version": 1,
      "content": [{"type": "paragraph", "content": [{"type": "text", "text": $text}]}]
    }
  }')
  jira_post "issue/$1/comment" "$BODY" > /dev/null
}

# Agent Interaction Protocols v1.0 — Handoff Packet helpers
# write_handoff: each agent calls this when handing work to the next stage
# Args: KEY FROM_AGENT TO_STAGE OBJECTIVE AC UX_NOTES TECH_NOTES RISKS DEPS OPEN_QS EXPECTED
write_handoff() {
  local KEY="$1" FROM_AGENT="$2" TO_STAGE="$3"
  local OBJECTIVE="${4:-Not specified}"
  local AC="${5:-See story description}"
  local UX_NOTES="${6:-See UX Agent comment}"
  local TECH_NOTES="${7:-See Architect comment}"
  local RISKS="${8:-None identified}"
  local DEPS="${9:-None}"
  local OPEN_QS="${10:-None}"
  local EXPECTED="${11:-Feature complete and tested}"

  jira_comment "$KEY" "[HANDOFF PACKET] $FROM_AGENT → $TO_STAGE | $(date -u '+%Y-%m-%d %H:%M UTC')
Jira: $KEY
Objective: $OBJECTIVE
Acceptance Criteria: $AC
UX Notes: $UX_NOTES
Technical Notes: $TECH_NOTES
Risks: $RISKS
Dependencies: $DEPS
Open Questions: $OPEN_QS
Expected Output: $EXPECTED"
}

# read_last_handoff: reads the most recent [HANDOFF PACKET] comment for a story
read_last_handoff() {
  local KEY="$1"
  jira_get "issue/$KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[HANDOFF PACKET\]' | tail -1
}

# escalate_to_tpm: flags a story for TPM review
escalate_to_tpm() {
  local KEY="$1" REASON="$2" SOURCE_AGENT="$3"
  jira_comment "$KEY" "[ESCALATE → TPM] $SOURCE_AGENT flagged: $REASON
Conflict Resolution Order (Agent Interaction Protocols §4):
1. Security / legal  2. Stability  3. User experience
4. Product value     5. Maintainability  6. Delivery speed
TPM Agent will review and post resolution."
  echo "$SOURCE_AGENT: Escalated $KEY to TPM — $REASON"
}
