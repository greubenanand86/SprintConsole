#!/usr/bin/env bash
# Deployment Specialist Agent — reviews build and deployment readiness
FINDINGS=$(claude --print \
  "You are a Deployment Specialist reviewing the SprintOps Console at /home/claude/repo.

Read index.html, package.json, and list the vendor/ directory contents.

Report ONLY if you find critical deployment blockers: missing vendor files referenced in index.html, broken script load order, missing files that GitHub Pages would need, or security issues (exposed secrets, dangerous script attributes).

If the deployment setup looks ready for GitHub Pages, output nothing.
If there are blockers, output a short bullet list (max 5 items, plain text).
Be specific — name the file and the blocker." \
  --allowedTools "Read,Glob,Grep,Bash" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
