#!/usr/bin/env bash
# Product Manager Agent — reviews feature completeness vs design spec
FINDINGS=$(claude --print \
  "You are a Senior Product Manager reviewing the SprintOps Console project at /home/claude/repo.

Read the design intent from chats/chat1.md, then check the implementation in index.html and the .jsx files.

Report ONLY if you find critical gaps: missing features promised in the design, broken user flows, or requirements not met.

If everything looks complete, output nothing.
If there are critical gaps, output a short bullet list (max 5 items, plain text, no headers).
Be specific — name the file and feature." \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

if [ -n "$FINDINGS" ]; then
  echo "$FINDINGS"
  exit 2
fi
exit 0
