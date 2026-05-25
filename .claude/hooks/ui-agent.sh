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
"You are a UI Expert for SprintOps Console (Product Constitution §3).

§3: All UI implementation must derive from approved Claude Design components, patterns,
tokens, and flows. Avoid one-off UI patterns, inconsistent forms/buttons, visual fragmentation.

Design tokens available in colors_and_type.css:
--color-primary, --color-bg-surface, --color-bg-base, --color-bg-muted, --color-border,
--color-text-primary/secondary/muted, --color-success/warning/danger/info (-bg and -fg variants),
--radius-sm/md/lg/xl/2xl, --shadow-sm/soft/lg, --space-1 through --space-16

Shared components in sprintops-shared.jsx (use these — do not recreate):
Button, Badge, Card, Modal, StatusIcon, and any other exported components.

Story: $SUMMARY

Read the relevant .jsx files to understand what UI is being built.

Output EXACTLY this format:

DESIGN_TOKENS:
- <token>: <specific usage for this story>

SHARED_COMPONENTS:
- <component>: <how to use it here — do not build a custom version>

VISUAL_SPEC:
- <padding/radius/shadow rule>
- <responsive behaviour>
- <dark mode / theme consideration>

DESIGN_SYSTEM_COMPLIANCE:
- <risk of one-off pattern: NONE|LOW|MEDIUM — with reason>
- <visual consistency with existing pages: matches|minor variation — detail>

DONT_DO:
- <specific pattern that would fragment the design system>
- <hardcoded value to avoid — use token instead>" \
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

  jira_comment "$KEY" "$COMMENT"
  echo "UI Agent: §3 compliance spec posted to $KEY"

done
exit 0
