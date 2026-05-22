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
