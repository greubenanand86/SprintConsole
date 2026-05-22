#!/usr/bin/env bash
# UI Expert Agent — reviews visual consistency and responsive design
FINDINGS=$(claude --print \
  "You are a UI Expert reviewing the SprintOps Console at /home/claude/repo.

Read colors_and_type.css and sprintops-shared.jsx. Spot-check sprintops-layout.jsx.

Report ONLY if you find critical UI issues: hardcoded colors that bypass the design token system, broken dark mode support, elements that overflow on narrow viewports, or inconsistent spacing/radius values.

If the UI looks consistent, output nothing.
If there are critical issues, output a short bullet list (max 5 items, plain text).
Be specific — name the file, line area, and the issue." \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
