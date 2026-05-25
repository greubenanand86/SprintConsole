#!/usr/bin/env bash
# Product Acceptance Agent — Jira Workflow Governance §7
# Validates features at "Product Acceptance" stage:
# feature solves intended problem, UX expectations met, release quality acceptable
# Transitions to "Ready for Release" on pass, "In Development" on fail
# Human involvement required when risk is HIGH, scope changed, or compliance concerns

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22Product+Acceptance%22)&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Product Acceptance Agent: $COUNT stories pending acceptance review (§7)"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_PA=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[PRODUCT ACCEPTANCE\]' || true)
  [ "$HAS_PA" -gt 0 ] && continue

  # Pull prior agent comments for context
  QA_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[QA LEAD\]' | head -3)
  UX_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[UX DESIGNER\]' | head -2)
  SEC_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[SECURITY\]' | head -2)

  PA_REVIEW=$(claude --print \
"You are the Product Acceptance Agent for SprintOps Console (Jira Workflow Governance §7).

Product Acceptance confirms:
1. Feature solves the intended problem as stated in acceptance criteria
2. UX expectations are met (clear, low-friction, accessible, recoverable)
3. Release quality is acceptable (no known blockers, edge cases handled)
4. Workflows behave correctly end-to-end
5. Definition of Done criteria are satisfied (§6):
   - Acceptance criteria validated
   - QA verified
   - Accessibility reviewed
   - Regression impact reviewed
   - Documentation updated where applicable
   - Monitoring/logging added where applicable
   - Release notes prepared

Story: $SUMMARY

Prior QA result: ${QA_COMMENT:-Not found}
UX specification: ${UX_COMMENT:-Not found}
Security review: ${SEC_COMMENT:-Not found}

Read the implemented .jsx files and assess acceptance.

Output EXACTLY this format:

PROBLEM_SOLVED: <YES — clearly solves stated problem|NO — does not match acceptance criteria>
UX_EXPECTATIONS: <MET|PARTIALLY MET|NOT MET — with reason>
RELEASE_QUALITY: <ACCEPTABLE|CONCERNS — list them>
DOD_STATUS:
- AC validated: <YES|NO>
- QA verified: <YES|NO — based on QA comment>
- Accessibility reviewed: <YES|NO>
- Regression considered: <YES|NO>
- Release notes ready: <YES|NO>

HUMAN_REVIEW_REQUIRED: <YES — high risk/strategic/compliance|NO — standard release>
VERDICT: <ACCEPTED — move to Ready for Release|REJECTED — back to In Development>
REJECTION_REASONS:
- <reason, or N/A if accepted>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  VERDICT=$(echo "$PA_REVIEW" | grep '^VERDICT:' | sed 's/^VERDICT: //')
  HUMAN_REQUIRED=$(echo "$PA_REVIEW" | grep '^HUMAN_REVIEW_REQUIRED:' | grep -i 'YES' | wc -l | tr -d ' ')

  if echo "$VERDICT" | grep -qi 'ACCEPTED'; then
    COMMENT="[PRODUCT ACCEPTANCE] ✅ Accepted — Moving to Ready for Release

Problem Solved: $(echo "$PA_REVIEW" | grep '^PROBLEM_SOLVED:' | sed 's/^PROBLEM_SOLVED: //')
UX Expectations: $(echo "$PA_REVIEW" | grep '^UX_EXPECTATIONS:' | sed 's/^UX_EXPECTATIONS: //')
Release Quality: $(echo "$PA_REVIEW" | grep '^RELEASE_QUALITY:' | sed 's/^RELEASE_QUALITY: //')

Definition of Done:
$(echo "$PA_REVIEW" | sed -n '/^DOD_STATUS:/,/^HUMAN_REVIEW_REQUIRED:/p' | grep '^-' | sed 's/^- /☑ /')

$([ "$HUMAN_REQUIRED" -gt 0 ] && echo "⚠ Human review recommended — strategic/risk/compliance concern noted.")"

    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "Ready for Release"
    jira_transition "$KEY" "Done"  # fallback if "Ready for Release" not configured
    echo "Product Acceptance Agent: ✅ $KEY accepted — transitioning to Ready for Release"

  else
    REASONS=$(echo "$PA_REVIEW" | sed -n '/^REJECTION_REASONS:/,$p' | grep '^-' | sed 's/^- /• /' | grep -v 'N/A')
    COMMENT="[PRODUCT ACCEPTANCE] ❌ Rejected — Back to In Development

Problem Solved: $(echo "$PA_REVIEW" | grep '^PROBLEM_SOLVED:' | sed 's/^PROBLEM_SOLVED: //')
UX Expectations: $(echo "$PA_REVIEW" | grep '^UX_EXPECTATIONS:' | sed 's/^UX_EXPECTATIONS: //')
Release Quality: $(echo "$PA_REVIEW" | grep '^RELEASE_QUALITY:' | sed 's/^RELEASE_QUALITY: //')

Rejection Reasons:
$REASONS

Definition of Done gaps:
$(echo "$PA_REVIEW" | sed -n '/^DOD_STATUS:/,/^HUMAN_REVIEW_REQUIRED:/p' | grep ': NO' | sed 's/^- /☐ /')

Please resolve all rejection reasons before re-submitting for Product Acceptance."

    jira_comment "$KEY" "$COMMENT"
    jira_transition "$KEY" "In Development"
    jira_transition "$KEY" "In Progress"  # fallback
    echo "Product Acceptance Agent: ❌ $KEY rejected — back to In Development"
    exit 2
  fi

done
exit 0
