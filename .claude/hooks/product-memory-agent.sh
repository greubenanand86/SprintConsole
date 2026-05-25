#!/usr/bin/env bash
# Product Memory Agent — Engineering Constitution §11 + Governance §6
# Records: architecture decisions, known limitations, technical debt,
# release learnings, recurring bugs, integration constraints
# All significant AI decisions must be stored in Product Memory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="$REPO_ROOT/PRODUCT_MEMORY.md"

RECENT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+updated>=-1h+ORDER+BY+updated+DESC&maxResults=20&fields=summary,status,labels")
COUNT=$(echo "$RECENT" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

# Bootstrap file if absent
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'EOF'
# Product Memory
## SprintOps Console

Stores significant AI decisions per Engineering Constitution §11 and Governance §6.

Sections:
- Architecture Decisions
- Known Limitations
- Technical Debt Log
- Release Learnings
- Recurring Issues
- Integration Constraints

Human accountability is retained for all entries.

---
EOF
fi

# ── Extract structured memory from AI agent Jira comments ─────────────────
ARCH_DECISIONS=""
TECH_DEBT_ITEMS=""
RELEASE_LEARNINGS=""
SECURITY_NOTES=""
RISK_NOTES=""
GENERAL_DECISIONS=""

while IFS='|' read -r KEY SUMMARY STATUS; do
  ISSUE_COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=30")

  # Architecture decisions (from ARCHITECT agent — ADR flagged items)
  ADR_LINES=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null | grep 'ADR REQUIRED\|DOCUMENTATION_REQUIRED' | head -3)
  [ -n "$ADR_LINES" ] && ARCH_DECISIONS="$ARCH_DECISIONS
### $KEY — $SUMMARY
$ADR_LINES"

  # Tech debt (from tech-debt agent labels)
  IS_DEBT=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null | grep -c 'Tech Debt\|tech-debt' || true)
  if [ "$IS_DEBT" -gt 0 ]; then
    TECH_DEBT_ITEMS="$TECH_DEBT_ITEMS
- $KEY: $SUMMARY (Status: $STATUS)"
  fi

  # Release learnings (from DEPLOY SPECIALIST)
  DEPLOY_NOTES=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null | grep '\[DEPLOY SPECIALIST\]' | head -2)
  [ -n "$DEPLOY_NOTES" ] && RELEASE_LEARNINGS="$RELEASE_LEARNINGS
- $KEY: $DEPLOY_NOTES"

  # Security notes (from SECURITY agent — HIGH risk only)
  SEC_HIGH=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null | grep '\[SECURITY\].*HIGH\|HIGH.*\[SECURITY\]' | head -2)
  [ -n "$SEC_HIGH" ] && SECURITY_NOTES="$SECURITY_NOTES
- $KEY ($SUMMARY): HIGH risk flagged"

  # Risk notes
  RISK_RED=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null | grep '\[RELEASE RISK\].*RED\|RED.*\[RELEASE RISK\]' | head -1)
  [ -n "$RISK_RED" ] && RISK_NOTES="$RISK_NOTES
- $KEY ($SUMMARY): RED risk flagged at $(date -u '+%Y-%m-%d')"

done < <(echo "$RECENT" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"')

# ── Write to PRODUCT_MEMORY.md ─────────────────────────────────────────────
ANYTHING_TO_WRITE=0
[ -n "$ARCH_DECISIONS" ] && ANYTHING_TO_WRITE=1
[ -n "$TECH_DEBT_ITEMS" ] && ANYTHING_TO_WRITE=1
[ -n "$RELEASE_LEARNINGS" ] && ANYTHING_TO_WRITE=1
[ -n "$SECURITY_NOTES" ] && ANYTHING_TO_WRITE=1
[ -n "$RISK_NOTES" ] && ANYTHING_TO_WRITE=1

[ "$ANYTHING_TO_WRITE" -eq 0 ] && exit 0

{
  echo ""
  echo "## Session: $TIMESTAMP"
  echo ""

  if [ -n "$ARCH_DECISIONS" ]; then
    echo "### Architecture Decisions"
    echo "$ARCH_DECISIONS"
    echo ""
  fi

  if [ -n "$TECH_DEBT_ITEMS" ]; then
    echo "### Technical Debt Log"
    echo "$TECH_DEBT_ITEMS"
    echo ""
  fi

  if [ -n "$RELEASE_LEARNINGS" ]; then
    echo "### Release Learnings"
    echo "$RELEASE_LEARNINGS"
    echo ""
  fi

  if [ -n "$SECURITY_NOTES" ]; then
    echo "### Security Notes (HIGH Risk)"
    echo "$SECURITY_NOTES"
    echo ""
  fi

  if [ -n "$RISK_NOTES" ]; then
    echo "### Release Risk Notes"
    echo "$RISK_NOTES"
    echo ""
  fi

  echo "---"
} >> "$MEMORY_FILE"

git -C "$REPO_ROOT" add PRODUCT_MEMORY.md 2>/dev/null
git -C "$REPO_ROOT" diff --cached --quiet || \
  git -C "$REPO_ROOT" commit -m "chore: update Product Memory log [$TIMESTAMP]" 2>/dev/null

echo "Product Memory Agent: Memory log updated with arch decisions, debt, learnings, security/risk notes"
exit 0
