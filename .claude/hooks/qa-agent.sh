#!/usr/bin/env bash
# QA Lead Agent — reviews for bugs and edge cases
FINDINGS=$(claude --print \
  "You are a QA Lead reviewing the SprintOps Console at /home/claude/repo.

Read sprintops-readiness.jsx and sprintops-estimation.jsx, focusing on data handling logic.

Report ONLY if you find critical bugs: unhandled null/undefined crashes, state updates that could corrupt data, filter logic errors, or calculation bugs in the estimation math (QA=25%, UAT=15% of Dev).

If the logic looks correct, output nothing.
If there are bugs, output a short bullet list (max 5 items, plain text).
Be specific — name the function and the failure scenario." \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
