#!/usr/bin/env bash

# UX Agent — UX and Design System
# Mission: Ensure intuitive, accessible, consistent UX aligned with Claude Design
# Claude Design is the canonical design source of truth
# Governs: TIER_1_AGENT_PROMPTS.md §3, Agent Role Specifications v1.0 §3
# Authority: Recommend approval/rejection; block inaccessible/inconsistent UX by recommendation
# Cannot: create separate design system without approval
# Advisory-first: recommends; humans decide

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

TARGET_KEY="${1:-}"
[ -z "$TARGET_KEY" ] && echo "Usage: ux-agent.sh <JIRA-KEY>" && exit 1

ISSUE=$(jira_get "issue/$TARGET_KEY?fields=summary,status,description,labels,issuetype")
SUMMARY=$(echo "$ISSUE" | jq -r '.fields.summary // ""')
STATUS=$(echo "$ISSUE" | jq -r '.fields.status.name // ""')
LABELS=$(echo "$ISSUE" | jq -r '[.fields.labels[]?] | join(",")' 2>/dev/null || echo "")
ISSUE_TYPE=$(echo "$ISSUE" | jq -r '.fields.issuetype.name // ""')

echo "UX Agent: Reviewing $TARGET_KEY ($STATUS)"

# Run Claude UX analysis
ANALYSIS=$(claude --print \
"Role: You are the UX Agent for SprintOps Console — design system and accessibility authority.
Claude Design is the canonical design source of truth.
$AGENT_CONTEXT

Task: Review the user experience, design consistency, accessibility, and mobile/web alignment for this story.

Inputs:
- Story: $SUMMARY ($TARGET_KEY)
- Type: $ISSUE_TYPE
- Status: $STATUS
- Labels: $LABELS
- Design source: Claude Design (canonical)
- Accessibility standard: WCAG 2.1 AA minimum
- Platforms: Web (React 18), Mobile (React Native + Expo)
- Source files readable via Read tool

Design Review Checklist:
1. User flow — is the happy path clear and intuitive?
2. Design system alignment — does UI use sprintops-shared components and color_and_type.css tokens?
3. Accessibility — keyboard nav, ARIA labels, contrast, semantic HTML?
4. Error/loading/empty states — are all three UX states defined?
5. Mobile/Web — is design responsive or explicitly mobile-first?
6. Consistency — does the pattern match existing UI in the codebase?
7. First-use experience — can a new user understand the feature without explanation?

Output EXACTLY this format:

UX_SUMMARY: <one-line assessment of UX readiness>
USER_FLOW_REVIEW: <Y/N: is happy path clear and intuitive>
DESIGN_SYSTEM_ALIGNMENT: <Y/N: uses shared components and tokens; if N, which gaps>
ACCESSIBILITY_REVIEW: <Y/N: WCAG 2.1 AA compliant; if N, which violations>
MOBILE_WEB_NOTES: <responsive design notes; web-specific or mobile-first implications>
ISSUES_FOUND: <bullet list of UX/accessibility/consistency issues; or 'None — UX is clean'>
RECOMMENDATION: <Approve | Revise | Block — with brief reason>

$AGENT_CONSTRAINTS
$AGENT_ESCALATION_RULES
$STANDARD_OUTPUT_SUFFIX" \
  --allowedTools "Read" \
  --no-conversation 2>/dev/null)

extract_standard "$ANALYSIS"

# Parse verdicts
UX_SUMMARY=$(echo "$ANALYSIS" | grep '^UX_SUMMARY:' | sed 's/^UX_SUMMARY: //')
USER_FLOW=$(echo "$ANALYSIS" | grep '^USER_FLOW_REVIEW:' | sed 's/^USER_FLOW_REVIEW: //')
DESIGN_ALIGN=$(echo "$ANALYSIS" | grep '^DESIGN_SYSTEM_ALIGNMENT:' | sed 's/^DESIGN_SYSTEM_ALIGNMENT: //')
A11Y=$(echo "$ANALYSIS" | grep '^ACCESSIBILITY_REVIEW:' | sed 's/^ACCESSIBILITY_REVIEW: //')
MOBILE_WEB=$(echo "$ANALYSIS" | grep '^MOBILE_WEB_NOTES:' | sed 's/^MOBILE_WEB_NOTES: //')
ISSUES=$(echo "$ANALYSIS" | sed -n '/^ISSUES_FOUND:/,/^RECOMMENDATION:/p' | sed '1d;$d')
RECOMMENDATION=$(echo "$ANALYSIS" | grep '^RECOMMENDATION:' | sed 's/^RECOMMENDATION: //')

# Determine verdict icon
VERDICT_ICON="✅"
VERDICT_TAG="APPROVE"
echo "$RECOMMENDATION" | grep -qi "revise" && VERDICT_ICON="⚠️" && VERDICT_TAG="REVISE"
echo "$RECOMMENDATION" | grep -qi "block" && VERDICT_ICON="❌" && VERDICT_TAG="BLOCK"

COMMENT="[UX AGENT] $VERDICT_ICON UX Review

Story: $SUMMARY ($TARGET_KEY)
Status: $STATUS

## UX Summary
$UX_SUMMARY

## User Flow Review
$USER_FLOW

## Design System Alignment
$DESIGN_ALIGN

## Accessibility Review
$A11Y

## Mobile/Web Notes
$MOBILE_WEB

## Issues Found
$([ -z "$ISSUES" ] && echo "None — UX is clean" || echo "$ISSUES")

## Recommendation
$RECOMMENDATION
$(standard_fields_block)"

echo "$COMMENT"
jira_comment "$TARGET_KEY" "$COMMENT" 2>/dev/null || true

echo "UX Agent: $TARGET_KEY [$VERDICT_TAG]"
exit 0
