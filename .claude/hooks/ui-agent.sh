#!/usr/bin/env bash
# UI Expert Agent — Product Constitution §3
# Reviews "In Progress" stories with full §3 design system compliance:
# enforces Claude Design tokens, shared component usage, flags one-off patterns
# and visual fragmentation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "UI Agent: $COUNT in-progress stories to spec (§3 design system compliance)"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_UI=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[UI EXPERT\]' || true)
  [ "$HAS_UI" -gt 0 ] && continue

  UI_SPEC=$(claude --print \
"Role: You are the UI Expert Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Produce a §3 design system compliance specification for this story.

Inputs:
- Story: $SUMMARY
- Source files readable via Read tool
- Design tokens: colors_and_type.css (--color-*, --radius-*, --space-*, --shadow-*)
- Shared components: sprintops-shared.jsx (Button, Badge, Card, Modal, StatusIcon)

Product Constitution §3: All UI must derive from approved design components, patterns, and tokens. No one-off patterns, no visual fragmentation.

Output format — output EXACTLY these sections:

DESIGN_TOKENS:
- <token>: <specific usage for this story>

SHARED_COMPONENTS:
- <component>: <how to use it here — do not build a custom version>

VISUAL_SPEC:
- <padding/radius/shadow rule>
- <responsive behaviour>
- <dark mode or theme consideration>

DESIGN_SYSTEM_COMPLIANCE:
- <risk of one-off pattern: NONE|LOW|MEDIUM — with reason>
- <visual consistency with existing pages: matches|minor variation — detail>

DONT_DO:
- <specific pattern that would fragment the design system>
- <hardcoded value to avoid — use token instead>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  COMPLIANCE=$(echo "$UI_SPEC" | sed -n '/^DESIGN_SYSTEM_COMPLIANCE:/,/^DONT_DO:/p' | grep '^-' | head -1)

  COMMENT="[UI EXPERT] Visual Specification — §3 Design System

Design Tokens:
$(echo "$UI_SPEC" | sed -n '/^DESIGN_TOKENS:/,/^SHARED_COMPONENTS:/p' | grep '^-' | sed 's/^- /🎨 /')

Shared Components (use — do not rebuild):
$(echo "$UI_SPEC" | sed -n '/^SHARED_COMPONENTS:/,/^VISUAL_SPEC:/p' | grep '^-' | sed 's/^- /✦ /')

Visual Rules:
$(echo "$UI_SPEC" | sed -n '/^VISUAL_SPEC:/,/^DESIGN_SYSTEM_COMPLIANCE:/p' | grep '^-' | sed 's/^- /• /')

Design System Compliance:
$(echo "$UI_SPEC" | sed -n '/^DESIGN_SYSTEM_COMPLIANCE:/,/^DONT_DO:/p' | grep '^-' | sed 's/^- /✓ /')

Avoid (design system violations):
$(echo "$UI_SPEC" | sed -n '/^DONT_DO:/,$p' | grep '^-' | sed 's/^- /✗ /')

Product Constitution §3: All UI must derive from approved Claude Design components
and tokens. One-off patterns introduce visual fragmentation and must be avoided."

  extract_standard "$UI_SPEC"
  COMMENT="$COMMENT
$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"
  echo "UI Agent: §3 compliance spec posted to $KEY"

done
exit 0
