#!/usr/bin/env bash
# Tech Architect + QA Refinement Agent
# Picks up stories in "To Do" / backlog, adds technical notes + test scenarios, moves to Ready for Dev

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# ── Fetch unrefined stories ────────────────────────────────────────────────
STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22To+Do%22&maxResults=20&fields=summary,description,status")
COUNT=$(echo "$STORIES" | jq '.issues | length')

if [ "$COUNT" -eq 0 ]; then
  exit 0
fi

echo "Architect Agent: $COUNT stories to refine"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  REFINEMENT=$(claude --print \
"You are a Tech Architect and QA Lead refining a Jira user story.

Story: $SUMMARY

Project context: SprintOps Console — a React 18 app (no build step, Babel standalone, UMD bundles in vendor/).
Files: index.html, sprintops-app.jsx, sprintops-shared.jsx, sprintops-layout.jsx,
       sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx,
       sprintops-config.jsx, sprintops-data.js, colors_and_type.css

Output EXACTLY two sections, no extra text:

TECH_NOTES:
- <implementation note 1>
- <implementation note 2>
- <implementation note 3>

TEST_SCENARIOS:
- <test scenario 1>
- <test scenario 2>
- <test scenario 3>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  TECH=$(echo "$REFINEMENT" | sed -n '/^TECH_NOTES:/,/^TEST_SCENARIOS:/p' | grep '^-' | sed 's/^- //')
  TESTS=$(echo "$REFINEMENT" | sed -n '/^TEST_SCENARIOS:/,$p' | grep '^-' | sed 's/^- //')

  # Build comment text
  COMMENT="[ARCHITECT] Technical Notes:
$(echo "$TECH" | sed 's/^/• /')

[QA LEAD] Test Scenarios:
$(echo "$TESTS" | sed 's/^/✓ /')"

  jira_comment "$KEY" "$COMMENT"
  echo "Architect Agent: Refined $KEY — $SUMMARY"

done

echo "Architect Agent: Refinement complete"
exit 2
