#!/usr/bin/env bash
# Web Frontend Agent — Per Agent Role Specifications v1.0 §14
# Mission: Build accessible, maintainable, performant React web experiences
# Authority: Create code and PRs; cannot merge without review; cannot bypass UX/QA/Architecture/Release Risk
# Usage: ui-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find stories in In Development / In Progress
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[WEB FRONTEND] Auto-scan: $COUNT stories in development"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story frontend review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "In Progress"')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50" 2>/dev/null || echo '{"comments":[]}')
HAS_UI=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[WEB FRONTEND\]\|\[UI EXPERT\]' || true)
[ "$HAS_UI" -gt 0 ] && { echo "[WEB FRONTEND] $KEY already reviewed — skipping"; exit 0; }

# Detect UI feature categories
IS_FORM=$(echo "$TITLE" | grep -iE 'form|input|field|edit|submit|create|update' && echo "yes" || echo "no")
IS_DISPLAY=$(echo "$TITLE" | grep -iE 'view|display|list|table|chart|dashboard|card' && echo "yes" || echo "no")
IS_MODAL=$(echo "$TITLE" | grep -iE 'modal|dialog|popup|overlay' && echo "yes" || echo "no")
IS_NAV=$(echo "$TITLE" | grep -iE 'nav|navigation|tab|route|link|sidebar' && echo "yes" || echo "no")

cat << EOF
[WEB FRONTEND] $KEY — Implementation Spec

## 1. Implementation Summary
- Story: $KEY — $TITLE
- Status: $STATE
- Feature Type: $([ "$IS_FORM" = "yes" ] && echo "Form/Input" || echo "—")\
$([ "$IS_DISPLAY" = "yes" ] && echo " Display/List" || echo "")\
$([ "$IS_MODAL" = "yes" ] && echo " Modal/Dialog" || echo "")\
$([ "$IS_NAV" = "yes" ] && echo " Navigation" || echo "")
- Stack: React 18 (JSX) + Babel standalone + Lucide icons + CSS tokens
- Target files: sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
  or feature-specific page (sprintops-readiness/estimation/release/config.jsx)

## 2. Files Changed
Likely changes:
$(
  [ "$IS_FORM" = "yes" ] && echo "  - Feature page .jsx — form component implementation"
  [ "$IS_DISPLAY" = "yes" ] && echo "  - Feature page .jsx — list/table rendering"
  [ "$IS_MODAL" = "yes" ] && echo "  - Feature page .jsx — Modal wired from sprintops-shared.jsx"
  [ "$IS_NAV" = "yes" ] && echo "  - sprintops-layout.jsx — navigation update"
  echo "  - sprintops-shared.jsx — ONLY if genuinely reusable"
  echo "  - colors_and_type.css — ONLY if new token is needed (rare)"
)

Governance:
  - Do NOT duplicate Button, Badge, Card, Modal, StatusIcon from sprintops-shared.jsx
  - Do NOT modify sprintops-data.js for UI logic
  - Do NOT add hardcoded hex colors or px values

## 3. Design System Usage
Tokens to use (from colors_and_type.css):
  - Spacing:   --space-* (no magic px values)
  - Color:     --color-text-*, --color-bg-*, --color-border-*
  - Radius:    --radius-* (consistent rounding)
  - Shadow:    --shadow-* (consistent elevation)
  - Typography: Use CSS classes defined in design tokens

Components to use (from sprintops-shared.jsx):
$(
  [ "$IS_FORM" = "yes" ] && echo "  - Button for submit/cancel actions"
  [ "$IS_DISPLAY" = "yes" ] && echo "  - Card for content containers"
  [ "$IS_MODAL" = "yes" ] && echo "  - Modal for dialogs"
  echo "  - Badge for status indicators"
  echo "  - StatusIcon for status visualization"
)

One-off patterns that are BLOCKED:
  - Custom button variations (use Button with variant prop)
  - Inline color styles (use CSS token)
  - Re-implemented modals (use Modal from shared)

## 4. Accessibility Notes
Mandatory (Engineering Constitution §5):
  - ✅ Semantic HTML: <button>, <nav>, <form>, <label> — NOT <div onClick>
  - ✅ Keyboard navigation: all interactive elements Tab-reachable
  - ✅ ARIA labels on icon-only buttons (aria-label="Close modal")
  - ✅ Sufficient contrast: use --color-text-primary (not muted tokens for critical info)
  - ✅ Error messages: clear, suggest recovery, no technical jargon
  - ✅ Loading/empty/error states: every feature must handle all three

$(
  [ "$IS_FORM" = "yes" ] && echo "Form-specific accessibility:
  - Labels associated with inputs (htmlFor / aria-label)
  - Required fields marked visually AND with aria-required
  - Validation errors announced to screen readers (aria-live)"

  [ "$IS_MODAL" = "yes" ] && echo "Modal accessibility:
  - Focus trapped inside modal when open
  - Escape key closes modal
  - Focus returns to trigger on close"
)

## 5. API/Data Impact
$(
  echo "Data source: window.SPRINTOPS_DATA (sprintops-data.js)"
  echo "  - Read-only from UI: pull data through props or state, no mutations to SPRINTOPS_DATA"
  echo "  - State management: local useState/useReducer only (no global state)"
  echo "  - Side effects: cleanup useEffect on unmount (no lingering timers or listeners)"
)

API readiness:
  - Current: Babel/JSX prototype, no real API calls
  - Target: When backend is available, use approved API client (api-client package)
  - Do NOT call external URLs or make raw fetch() without Architecture approval

## 6. Tests Added
$(
  echo "Manual test checklist (automated tests: Engineering Constitution §6 backlog):"
  echo "  □ Happy path — feature works as described"
  echo "  □ Empty state — correct message shown when no data"
  echo "  □ Error state — error boundary or message shown on failure"
  echo "  □ Loading state — spinner or skeleton shown during fetch"
  if [ "$IS_FORM" = "yes" ]; then
    echo "  □ Form validation — required fields caught, helpful messages shown"
    echo "  □ Submit success — correct feedback on completion"
  fi
  if [ "$IS_MODAL" = "yes" ]; then
    echo "  □ Modal open/close — keyboard and mouse work"
    echo "  □ Backdrop click — closes modal"
  fi
  echo "  □ Keyboard navigation — all interactions reachable via keyboard"
  echo "  □ Regression — other features unaffected"
)

## 7. Risks
$(
  echo "- Design system drift: Risk if shared components are duplicated instead of used"
  echo "- Accessibility regression: Risk if semantic HTML or ARIA skipped under time pressure"
  if [ "$IS_FORM" = "yes" ]; then
    echo "- Input validation: Risk of missing edge cases if client-only validation not thorough"
  fi
  echo "- Performance: Risk of re-render loops if useEffect dependencies incorrect"
  echo "- Mitigation: Code review by [ARCHITECT] validates all above"
)

## 8. PR Ready? Yes/No
No — Development in progress.
PR ready when:
  □ All acceptance criteria implemented
  □ Loading/empty/error states present
  □ Accessibility manual check passed
  □ No hardcoded colors, magic px, or duplicated components
  □ Self-review complete
  □ Test evidence collected (screenshots or test case results)

After PR:
  → [UX DESIGNER] review
  → [ARCHITECT] review
  → [QA LEAD] review
  → [SECURITY] review (if auth/data affected)
  → [RELEASE RISK] review

---
[Web Frontend Agent] — Per Agent Role Specifications v1.0 §14 | ENGINEERING_CONSTITUTION v1.0
EOF

jira_comment "$KEY" "[WEB FRONTEND] 📋 Implementation spec prepared.
Design system, accessibility, and data handling requirements documented.
See comment for full implementation guidance.
[Web Frontend Agent]" 2>/dev/null || true
