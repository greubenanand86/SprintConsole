#!/usr/bin/env bash
# Tech Architect Agent — reviews code structure and patterns
FINDINGS=$(claude --print \
  "You are a Tech Architect reviewing the SprintOps Console at /home/claude/repo.

Read sprintops-app.jsx, sprintops-shared.jsx, and sprintops-data.js.

Report ONLY if you find critical architectural issues: global state mismanagement, window.* anti-patterns that could cause race conditions, memory leaks (event listeners not cleaned up), or patterns that will break as the app grows.

If the architecture looks sound for this prototype, output nothing.
If there are critical issues, output a short bullet list (max 5 items, plain text).
Be specific — name the file and the pattern." \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
