#!/usr/bin/env bash
# UX Designer Agent
# Picks up stories in "In Progress", adds UX flow notes as Jira comment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22In+Progress%22&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "UX Agent: $COUNT in-progress stories to review"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  # Skip if already has UX notes
  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_UX=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' | grep -c '\[UX\]' || true)
  [ "$HAS_UX" -gt 0 ] && continue

  UX_NOTES=$(claude --print \
"You are a UX Designer reviewing a user story for SprintOps Console (a React 18 sprint management tool).

Story: $SUMMARY

Output EXACTLY this format, no extra text:

USER_FLOW:
- <step 1>
- <step 2>
- <step 3>

INTERACTION_NOTES:
- <note on hover/click/focus states>
- <note on loading/empty/error states>
- <note on mobile behaviour>

COMPONENTS_TO_USE:
- <component name from sprintops-shared.jsx>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  COMMENT="[UX DESIGNER] UX Specification:

User Flow:
$(echo "$UX_NOTES" | sed -n '/^USER_FLOW:/,/^INTERACTION_NOTES:/p' | grep '^-' | sed 's/^- /→ /')

Interaction Notes:
$(echo "$UX_NOTES" | sed -n '/^INTERACTION_NOTES:/,/^COMPONENTS_TO_USE:/p' | grep '^-' | sed 's/^- /• /')

Shared Components to use:
$(echo "$UX_NOTES" | sed -n '/^COMPONENTS_TO_USE:/,$p' | grep '^-' | sed 's/^- /✦ /')"

  jira_comment "$KEY" "$COMMENT"
  echo "UX Agent: Added flow notes to $KEY"

done
exit 0
