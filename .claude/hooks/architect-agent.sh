#!/usr/bin/env bash
# Tech Architect + QA Refinement Agent — Engineering Constitution §1, §2, §3, §10
# Picks up "To Do" stories, adds technical notes, architecture standards compliance,
# tech stack compliance (§2), component standards (§3), documentation requirements (§10),
# plus explainability fields per governance §2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Fetch unrefined stories ────────────────────────────────────────────────
STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22To+Do%22,%22Idea+%2F+Request%22,%22Triage%22,%22Ready+for+Refinement%22)&maxResults=20&fields=summary,description,status")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -eq 0 ]; then
  exit 0
fi

echo "Architect Agent: $COUNT stories to refine"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  REFINEMENT=$(claude --print \
"You are a Tech Architect refining a Jira user story for SprintOps Console.

Story: $SUMMARY

Project: React 18, no build step, Babel standalone, CSS design tokens in colors_and_type.css.
Files: index.html, sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
       sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx,
       sprintops-config.jsx, sprintops-data.js, colors_and_type.css

Engineering Constitution requirements to check and address:

§1 Simplicity: Prefer simplest solution. Flag over-engineering risk.
§2 Tech Standards: Use React patterns correctly. TypeScript is mandated but missing (flag as debt).
§3 Architecture: Components must handle loading/error/empty states. No business logic in UI.
   State: local stays local. Use CSS tokens, not hardcoded values.
§10 Documentation: Major decisions need rationale, alternatives, risks, rollback.
Governance §2: Include rationale, impact summary, risk awareness, affected systems, rollback awareness.

Output EXACTLY these sections, no extra text:

TECH_NOTES:
- <implementation note 1>
- <implementation note 2>
- <implementation note 3>

ARCHITECTURE_COMPLIANCE:
- §1 Simplicity: <assessment>
- §3 Component states: <loading/error/empty required? how to implement?>
- §3 State management: <what state is needed and where it lives>
- §3 Design tokens: <which CSS variables to use>

TECH_STACK_NOTES:
- <React pattern to follow for this story>
- <TypeScript debt note if applicable>

DOCUMENTATION_REQUIRED:
- <what architecture decision to document, or 'Standard implementation — no ADR needed'>

RATIONALE:
- <why this technical approach>

IMPACT_SUMMARY:
- <what changes and what is affected>

RISK_AWARENESS:
- <potential risk>

AFFECTED_SYSTEMS:
- <component or file>

ROLLBACK_AWARENESS:
- <how to revert>

TEST_SCENARIOS:
- <test scenario 1>
- <test scenario 2>
- <test scenario 3>

SENSITIVE_AREAS: <YES|NO>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  SENSITIVE=$(echo "$REFINEMENT" | grep '^SENSITIVE_AREAS:' | grep -i 'YES' | wc -l | tr -d ' ')
  ADR=$(echo "$REFINEMENT" | sed -n '/^DOCUMENTATION_REQUIRED:/,/^RATIONALE:/p' | grep '^-' | sed 's/^- //' | head -1)

  COMMENT="[ARCHITECT] Technical Refinement — §1 §2 §3 §10

Technical Notes:
$(echo "$REFINEMENT" | sed -n '/^TECH_NOTES:/,/^ARCHITECTURE_COMPLIANCE:/p' | grep '^-' | sed 's/^- /• /')

Architecture Compliance:
$(echo "$REFINEMENT" | sed -n '/^ARCHITECTURE_COMPLIANCE:/,/^TECH_STACK_NOTES:/p' | grep '^-' | sed 's/^- /✓ /')

Tech Stack Notes:
$(echo "$REFINEMENT" | sed -n '/^TECH_STACK_NOTES:/,/^DOCUMENTATION_REQUIRED:/p' | grep '^-' | sed 's/^- /🔧 /')

Documentation Required:
$(echo "$REFINEMENT" | sed -n '/^DOCUMENTATION_REQUIRED:/,/^RATIONALE:/p' | grep '^-' | sed 's/^- /📄 /')

Rationale:
$(echo "$REFINEMENT" | sed -n '/^RATIONALE:/,/^IMPACT_SUMMARY:/p' | grep '^-' | sed 's/^- /→ /')

Impact Summary:
$(echo "$REFINEMENT" | sed -n '/^IMPACT_SUMMARY:/,/^RISK_AWARENESS:/p' | grep '^-' | sed 's/^- /📋 /')

Risk Awareness:
$(echo "$REFINEMENT" | sed -n '/^RISK_AWARENESS:/,/^AFFECTED_SYSTEMS:/p' | grep '^-' | sed 's/^- /⚠ /')

Affected Systems:
$(echo "$REFINEMENT" | sed -n '/^AFFECTED_SYSTEMS:/,/^ROLLBACK_AWARENESS:/p' | grep '^-' | sed 's/^- /🔧 /')

Rollback Awareness:
$(echo "$REFINEMENT" | sed -n '/^ROLLBACK_AWARENESS:/,/^TEST_SCENARIOS:/p' | grep '^-' | sed 's/^- /↩ /')

[QA LEAD] Test Scenarios:
$(echo "$REFINEMENT" | sed -n '/^TEST_SCENARIOS:/,/^SENSITIVE_AREAS:/p' | grep '^-' | sed 's/^- /✓ /')"

  if [ "$SENSITIVE" -gt 0 ]; then
    COMMENT="$COMMENT

⚠ SECURITY FLAG: Touches sensitive areas. Security Agent review mandatory per §4."
  fi

  if [ -n "$ADR" ] && ! echo "$ADR" | grep -qi "no adr needed"; then
    COMMENT="$COMMENT

📄 ADR REQUIRED: $ADR — Document in PRODUCT_MEMORY.md per §10."
  fi

  jira_comment "$KEY" "$COMMENT"
  echo "Architect Agent: Refined $KEY — $SUMMARY"

done

echo "Architect Agent: Refinement complete"
exit 2
