#!/usr/bin/env bash
# React Native Mobile Agent — Per Agent Role Specifications v1.0 §15
# Mission: Build cross-platform mobile experiences with React Native, Expo, TypeScript, and shared design patterns
# Authority: Create code and PRs; no native modules without Architecture review; cannot bypass QA/UX/Release Risk
# Usage: mobile-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find mobile-labelled stories in development
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+labels=mobile+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[MOBILE AGENT] Auto-scan: $COUNT mobile stories in development"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story mobile review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "In Progress"')

# Detect feature category
IS_SCREEN=$(echo "$TITLE" | grep -iE 'screen|page|view|route' && echo "yes" || echo "no")
IS_COMPONENT=$(echo "$TITLE" | grep -iE 'component|widget|card|list|form' && echo "yes" || echo "no")
IS_NATIVE=$(echo "$TITLE" | grep -iE 'camera|push.*notif|biometric|nfc|haptic|bluetooth|local.*storage' && echo "yes" || echo "no")

cat << EOF
[MOBILE AGENT] $KEY — React Native Implementation Spec

## 1. Mobile Implementation Summary
- Story: $KEY — $TITLE
- Status: $STATE
- Feature Type: $([ "$IS_SCREEN" = "yes" ] && echo "Screen/Navigation" || echo "—")\
$([ "$IS_COMPONENT" = "yes" ] && echo " Component" || echo "")\
$([ "$IS_NATIVE" = "yes" ] && echo " ⚠️ Native Module" || echo "")
- Target Stack: React Native + Expo + TypeScript (per ARCHITECTURE.md §4 and SHARED_PACKAGE_STRATEGY.md)
- Mobile root: /mobile (target architecture — not yet initialized in prototype phase)

## 2. Android Impact
$(
  echo "Android Platform Checks:"
  echo "  - API level target: Android 8.0+ (API 26+)"
  echo "  - Material Design 3 alignment (where applicable)"
  echo "  - Back button / hardware navigation handled"
  echo "  - Android permissions declared in AndroidManifest.xml (if applicable)"
  if [ "$IS_NATIVE" = "yes" ]; then
    echo "  - ⚠️ Native module detected: requires [ARCHITECT] review"
    echo "  - Confirm Expo SDK supports feature (prefer Expo API over bare native)"
  else
    echo "  - ✅ No Android-specific native concerns detected"
  fi
)

## 3. iOS Impact
$(
  echo "iOS Platform Checks:"
  echo "  - iOS 15.0+ minimum deployment target"
  echo "  - Human Interface Guidelines alignment (HIG)"
  echo "  - Safe area insets respected (useSafeAreaInsets)"
  echo "  - Info.plist permissions declared (if applicable)"
  if [ "$IS_NATIVE" = "yes" ]; then
    echo "  - ⚠️ Native module detected: requires [ARCHITECT] review"
    echo "  - Confirm Expo SDK supports feature (prefer Expo API over bare native)"
    echo "  - App Store review impact? Flag to Release Risk Agent"
  else
    echo "  - ✅ No iOS-specific native concerns detected"
  fi
)

## 4. Shared Component Usage
Shared packages (per SHARED_PACKAGE_STRATEGY.md):
  - /packages/ui    → Shared UI components (web + mobile)
  - /api-client     → API integration (same client web and mobile)
  - /validation     → Shared validation logic (no duplication)
  - /utils          → Shared utility functions
  - /config         → Environment and feature config
  - /analytics      → Analytics events (shared naming)

Implementation rules:
  - ✅ Use shared components from /packages/ui where possible
  - ✅ Use shared API client from /api-client
  - ✅ Use TypeScript (mandatory — Architecture Blueprint §3)
  - ❌ Do NOT duplicate validation logic from /validation
  - ❌ Do NOT create mobile-only analytics events (coordinate with Analytics Agent)
  - ❌ Do NOT introduce native modules without [ARCHITECT] approval

## 5. Accessibility Notes
Mobile accessibility (mandatory):
  - accessibilityLabel on interactive elements
  - accessibilityRole="button" for touchable actions
  - accessibilityHint for non-obvious interactions
  - Minimum touch target: 44×44 points (Apple HIG) / 48×48dp (Material)
  - Dynamic type / font scaling supported (no fixed font sizes)
  - VoiceOver (iOS) and TalkBack (Android) manually tested
  - Color contrast: WCAG AA minimum (4.5:1)

$(
  [ "$IS_SCREEN" = "yes" ] && echo "Screen accessibility:
  - Screen title announced on navigation
  - Focus order logical (top-to-bottom, consistent with reading order)"
  [ "$IS_COMPONENT" = "yes" ] && echo "Component accessibility:
  - Group related elements with accessibilityRole='group'
  - Status changes announced via accessibilityLiveRegion"
)

## 6. Device/Platform Risks
$(
  if [ "$IS_NATIVE" = "yes" ]; then
    echo "🚨 HIGH RISK: Native module required"
    echo "  - Must get [ARCHITECT] approval before implementation"
    echo "  - OTA updates may not apply to native changes (requires full store release)"
    echo "  - Testing on real devices (not just simulator) mandatory"
    echo "  - Expo Go compatibility check required"
  else
    echo "Standard mobile risks:"
  fi
  echo "  - Form factor differences (phone vs tablet) — test both"
  echo "  - Keyboard avoidance — KeyboardAvoidingView for forms"
  echo "  - Network conditions — offline/slow network behavior"
  echo "  - Background/foreground state transitions"
  echo "  - Screen orientation changes (portrait/landscape)"
)

## 7. Tests Added
$(
  echo "Mobile test checklist:"
  echo "  □ Functional: Happy path on iOS + Android simulators"
  echo "  □ Edge cases: Empty state, error state, loading state"
  echo "  □ Accessibility: VoiceOver (iOS) + TalkBack (Android)"
  echo "  □ Performance: No jank on scroll, animation at 60fps"
  echo "  □ Network: Offline behavior (cached vs live data)"
  if [ "$IS_NATIVE" = "yes" ]; then
    echo "  □ Real device: Tested on physical iPhone + Android device"
  fi
  echo "  □ Regression: Core navigation and existing screens unaffected"
)

## 8. PR Ready? Yes/No
No — Mobile implementation in progress.
PR ready when:
  □ Feature implemented on iOS and Android
  □ Loading/empty/error states present
  □ Accessibility labels and roles applied
  □ TypeScript types strict (no \`any\`)
  □ Shared packages used (not duplicated)
  □ Simulator screenshots or screen recording attached
$([ "$IS_NATIVE" = "yes" ] && echo "  □ [ARCHITECT] approval for native module")

After PR:
  → [UX DESIGNER] review
  → [ARCHITECT] review
  → [QA LEAD] review (mobile-specific QA)
  → [RELEASE RISK] review (mobile beta → store release path)

---
[React Native Mobile Agent] — Per Agent Role Specifications v1.0 §15 | ARCHITECTURE_BLUEPRINT v1.0 §4
EOF

jira_comment "$KEY" "[MOBILE AGENT] 📱 Mobile implementation spec prepared.
Platform checks, shared component guidance, and accessibility requirements documented.
[React Native Mobile Agent]" 2>/dev/null || true
