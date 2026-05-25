#!/usr/bin/env bash
# Tech Architect + QA Refinement Agent
# Picks up stories in "To Do", adds technical notes + test scenarios
# Per governance §2: significant actions must include rationale, impact summary,
# risk awareness, affected systems, and rollback awareness

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Fetch unrefined stories ────────────────────────────────────────────────
STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22To+Do%22&maxResults=20&fields=summary,description,status")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -eq 0 ]; then
  exit 0
fi

echo "Architect Agent: $COUNT stories to refine"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  REFINEMENT=$(claude --print \
"You are a Tech Architect and QA Lead refining a Jira user story for SprintOps Console.

Story: $SUMMARY

Project context: SprintOps Console — a React 18 app (no build step, Babel standalone, UMD bundles in vendor/).
Files: index.html, sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
       sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx,
       sprintops-config.jsx, sprintops-data.js, colors_and_type.css

Per governance §2 (Explainability), your output must include rationale, impact summary,
risk awareness, affected systems, and rollback awareness.

Output EXACTLY these sections, no extra text:

TECH_NOTES:
- <implementation note 1>
- <implementation note 2>
- <implementation note 3>

RATIONALE:
- <why this technical approach was chosen>

IMPACT_SUMMARY:
- <what changes and what is affected>

RISK_AWARENESS:
- <potential risk or 'Low risk — isolated UI change'>

AFFECTED_SYSTEMS:
- <component or file affected>

ROLLBACK_AWARENESS:
- <how to revert this change if needed>

TEST_SCENARIOS:
- <test scenario 1>
- <test scenario 2>
- <test scenario 3>

SENSITIVE_AREAS: <YES|NO — touches auth/PII/payments/credentials/integrations>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  SENSITIVE=$(echo "$REFINEMENT" | grep '^SENSITIVE_AREAS:' | grep -i 'YES' | wc -l | tr -d ' ')

  COMMENT="[ARCHITECT] Technical Refinement

Technical Notes:
$(echo "$REFINEMENT" | sed -n '/^TECH_NOTES:/,/^RATIONALE:/p' | grep '^-' | sed 's/^- /• /')

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

⚠ SECURITY FLAG: This story touches sensitive areas. Security Agent review is mandatory before production per governance §7."
  fi

  jira_comment "$KEY" "$COMMENT"
  echo "Architect Agent: Refined $KEY — $SUMMARY"

done

echo "Architect Agent: Refinement complete"
exit 2
