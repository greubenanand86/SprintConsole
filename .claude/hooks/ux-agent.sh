#!/usr/bin/env bash
# UX Designer Agent — reviews user flows, empty states, error handling
FINDINGS=$(claude --print \
  "You are a UX Designer reviewing the SprintOps Console at /home/claude/repo.

Read sprintops-readiness.jsx, sprintops-estimation.jsx, sprintops-release.jsx, sprintops-config.jsx.

Report ONLY if you find critical UX issues: missing empty states, no error feedback, confusing flows, broken interactions, or accessibility blockers.

If UX looks solid, output nothing.
If there are critical issues, output a short bullet list (max 5 items, plain text).
Be specific — name the component and the issue." \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
