#!/usr/bin/env bash
# Product Memory Agent — governance §6
# All significant AI decisions must be stored in Product Memory
# Reads recent Jira AI agent comments and appends to PRODUCT_MEMORY.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="$REPO_ROOT/PRODUCT_MEMORY.md"

RECENT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+updated>=-1h+ORDER+BY+updated+DESC&maxResults=20&fields=summary,status")
COUNT=$(echo "$RECENT" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

# Bootstrap file if absent
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'EOF'
# Product Memory
## SprintOps Console — AI Decision Log

Significant AI decisions recorded per governance §6.
Human accountability is retained for all entries.

---
EOF
fi

ENTRY_WRITTEN=0

{
  echo ""
  echo "## $TIMESTAMP"
  echo ""

  echo "$RECENT" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"' | while IFS='|' read -r KEY SUMMARY STATUS; do

    ISSUE_COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=30")
    AI_LINES=$(echo "$ISSUE_COMMENTS" | jq -r '
      .comments[].body.content[]?.content[]?.text // ""
    ' 2>/dev/null | grep -E '^\[(ARCHITECT|QA LEAD|UX DESIGNER|UI EXPERT|SECURITY|RELEASE RISK|DEPLOY SPECIALIST)\]' | head -8)

    [ -z "$AI_LINES" ] && continue

    echo "### $KEY — $SUMMARY"
    echo "- **Status:** $STATUS"
    echo "- **Recorded:** $TIMESTAMP"
    echo "- **AI Actions:**"
    echo "$AI_LINES" | while IFS= read -r line; do
      echo "  - $line"
    done
    echo ""
    ENTRY_WRITTEN=1
  done

  echo "---"
} >> "$MEMORY_FILE"

git -C "$REPO_ROOT" add PRODUCT_MEMORY.md 2>/dev/null
git -C "$REPO_ROOT" diff --cached --quiet || git -C "$REPO_ROOT" commit -m "chore: update Product Memory log [$TIMESTAMP]" 2>/dev/null

echo "Product Memory Agent: Decision log updated ($MEMORY_FILE)"
exit 0
