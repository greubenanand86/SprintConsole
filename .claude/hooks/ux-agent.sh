#!/usr/bin/env bash
# UX Designer Agent — Product Constitution §2, §6
# Reviews "In Progress" stories with full §2 UX principle coverage:
# clarity, predictability, low friction, recoverability, progressive disclosure,
# error message quality, offline considerations, mobile ergonomics, first-use experience

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "UX Agent: $COUNT in-progress stories to review (§2 full coverage)"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_UX=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[UX DESIGNER\]' || true)
  [ "$HAS_UX" -gt 0 ] && continue

  UX_NOTES=$(claude --print \
"You are a UX Designer reviewing a story for SprintOps Console (Product Constitution §2, §6).

Story: $SUMMARY

Product Constitution §2 requires every workflow to address:
- Clarity and predictability (user knows where they are, what happens next)
- Low friction (minimal steps to complete key actions)
- Recoverability (users can undo, retry, or correct mistakes)
- Progressive disclosure (advanced functionality revealed only when needed)
- Error state quality (clear language, recovery suggestion, no tech jargon, progress preserved)
- Loading / empty / error / offline states for every feature
- Mobile ergonomics (touch targets ≥44px, thumb-reachable actions, responsive)
- First-use experience (new users quickly understand the core workflow)

§10 Decision Hierarchy: User trust > Accessibility > Stability > Simplicity

Read the relevant .jsx files to understand the current UI context.

Output EXACTLY this format, no extra text:

USER_FLOW:
- <step 1 — what user sees/does>
- <step 2>
- <step 3>

RECOVERABILITY:
- <how user undoes or retries the primary action>
- <what happens if the action partially fails>

PROGRESSIVE_DISCLOSURE:
- <what is shown immediately vs. revealed on demand>

ERROR_STATES:
- <error scenario>: <clear user-facing message — no tech jargon> — <recovery action offered>
- <error scenario>: <message> — <recovery action>

LOADING_EMPTY_OFFLINE:
- Loading: <what skeleton/spinner to show>
- Empty: <message and call-to-action for zero-data state>
- Offline: <graceful degradation behaviour>

MOBILE_ERGONOMICS:
- <touch target size note>
- <thumb-zone consideration for primary action>
- <responsive layout note>

FIRST_USE_EXPERIENCE:
- <how a new user would understand this feature without explanation>

COMPONENTS_TO_USE:
- <component from sprintops-shared.jsx and why>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  COMMENT="[UX DESIGNER] UX Specification — §2 §6

User Flow:
$(echo "$UX_NOTES" | sed -n '/^USER_FLOW:/,/^RECOVERABILITY:/p' | grep '^-' | sed 's/^- /→ /')

Recoverability:
$(echo "$UX_NOTES" | sed -n '/^RECOVERABILITY:/,/^PROGRESSIVE_DISCLOSURE:/p' | grep '^-' | sed 's/^- /↩ /')

Progressive Disclosure:
$(echo "$UX_NOTES" | sed -n '/^PROGRESSIVE_DISCLOSURE:/,/^ERROR_STATES:/p' | grep '^-' | sed 's/^- /◈ /')

Error States:
$(echo "$UX_NOTES" | sed -n '/^ERROR_STATES:/,/^LOADING_EMPTY_OFFLINE:/p' | grep '^-' | sed 's/^- /⚠ /')

Loading / Empty / Offline:
$(echo "$UX_NOTES" | sed -n '/^LOADING_EMPTY_OFFLINE:/,/^MOBILE_ERGONOMICS:/p' | grep '^-' | sed 's/^- /⟳ /')

Mobile Ergonomics:
$(echo "$UX_NOTES" | sed -n '/^MOBILE_ERGONOMICS:/,/^FIRST_USE_EXPERIENCE:/p' | grep '^-' | sed 's/^- /📱 /')

First-Use Experience:
$(echo "$UX_NOTES" | sed -n '/^FIRST_USE_EXPERIENCE:/,/^COMPONENTS_TO_USE:/p' | grep '^-' | sed 's/^- /★ /')

Shared Components:
$(echo "$UX_NOTES" | sed -n '/^COMPONENTS_TO_USE:/,$p' | grep '^-' | sed 's/^- /✦ /')"

  jira_comment "$KEY" "$COMMENT"
  echo "UX Agent: Full §2 spec posted to $KEY"

done
exit 0
