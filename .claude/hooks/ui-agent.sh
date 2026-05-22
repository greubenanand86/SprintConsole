#!/usr/bin/env bash
# UI Expert Agent
# Reviews In Progress stories and adds component + design token spec to Jira

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22In+Progress%22&maxResults=10&fields=summary")
COUNT=$(echo "$STORIES" | jq '.issues | length')

[ "$COUNT" -eq 0 ] && exit 0

echo "UI Agent: $COUNT in-progress stories to spec"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_UI=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' | grep -c '\[UI\]' || true)
  [ "$HAS_UI" -gt 0 ] && continue

  UI_SPEC=$(claude --print \
"You are a UI Expert for SprintOps Console. The design system uses CSS variables from colors_and_type.css:
--color-primary, --color-bg-surface, --color-bg-base, --color-bg-muted, --color-border,
--color-text-primary/secondary/muted, --color-success/warning/danger/info (each with -bg and -fg variants),
--radius-sm/md/lg/xl/2xl, --shadow-sm/soft/lg, --space-1 through --space-16

Story: $SUMMARY

Output EXACTLY this format:

DESIGN_TOKENS:
- <token name>: <how to use it for this story>

VISUAL_SPEC:
- <specific padding/radius/shadow rule>
- <dark mode consideration>
- <responsive breakpoint note>

DONT_DO:
- <common mistake to avoid>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  COMMENT="[UI EXPERT] Visual Specification:

Design Tokens:
$(echo "$UI_SPEC" | sed -n '/^DESIGN_TOKENS:/,/^VISUAL_SPEC:/p' | grep '^-' | sed 's/^- /🎨 /')

Visual Rules:
$(echo "$UI_SPEC" | sed -n '/^VISUAL_SPEC:/,/^DONT_DO:/p' | grep '^-' | sed 's/^- /• /')

Avoid:
$(echo "$UI_SPEC" | sed -n '/^DONT_DO:/,$p' | grep '^-' | sed 's/^- /✗ /')"

  jira_comment "$KEY" "$COMMENT"
  echo "UI Agent: Added visual spec to $KEY"

done
exit 0
