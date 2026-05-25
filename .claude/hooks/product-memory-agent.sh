#!/usr/bin/env bash
# Product Memory Agent — Product Constitution §7, Engineering Constitution §11, Governance §6
# Records: architecture decisions, UX rationale, rejected approaches,
# technical debt, release learnings, recurring usability issues, security/risk events

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="$REPO_ROOT/PRODUCT_MEMORY.md"

RECENT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+updated>=-1h+ORDER+BY+updated+DESC&maxResults=20&fields=summary,status,labels")
COUNT=$(echo "$RECENT" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'EOF'
# Product Memory
## SprintOps Console

Significant decisions per Product Constitution §7, Engineering Constitution §11, Governance §6.

Sections captured per session:
- Architecture Decisions (ADR flags from Architect Agent)
- UX Rationale (from UX Designer Agent)
- Rejected Approaches (from Architect alternatives)
- Technical Debt (from Tech Debt Agent)
- Release Learnings (from Deploy Specialist)
- Recurring Usability Issues (from QA failures)
- Security Notes (HIGH risk flags)
- Release Risk Events (RED flags)

Human accountability is retained for all entries.

---
EOF
fi

# ── Collect entries from AI agent Jira comments ────────────────────────────
ARCH_DECISIONS=""
UX_RATIONALE=""
TECH_DEBT_ITEMS=""
RELEASE_LEARNINGS=""
USABILITY_ISSUES=""
SECURITY_NOTES=""
RISK_NOTES=""
GOV_FLAGS=""

while IFS='|' read -r KEY SUMMARY STATUS; do
  ISSUE_COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=30")
  ALL_TEXT=$(echo "$ISSUE_COMMENTS" | jq -r '
    .comments[].body.content[]?.content[]?.text // ""
  ' 2>/dev/null)

  # Architecture decisions (ADR flagged by architect)
  ADR=$(echo "$ALL_TEXT" | grep 'ADR REQUIRED' | head -2)
  [ -n "$ADR" ] && ARCH_DECISIONS="$ARCH_DECISIONS
- $KEY ($SUMMARY): $ADR"

  # UX rationale (from UX designer — recoverability and progressive disclosure decisions)
  UX=$(echo "$ALL_TEXT" | grep '\[UX DESIGNER\]' | head -1)
  [ -n "$UX" ] && UX_RATIONALE="$UX_RATIONALE
- $KEY ($SUMMARY): UX spec recorded [$(date -u '+%Y-%m-%d')]"

  # Technical debt
  DEBT=$(echo "$ALL_TEXT" | grep -i 'tech.debt\|\[Tech Debt\]' | head -1)
  [ -n "$DEBT" ] && TECH_DEBT_ITEMS="$TECH_DEBT_ITEMS
- $KEY: $SUMMARY (Status: $STATUS)"

  # Release learnings (deploy specialist notes)
  DEPLOY=$(echo "$ALL_TEXT" | grep '\[DEPLOY SPECIALIST\]' | head -1)
  [ -n "$DEPLOY" ] && RELEASE_LEARNINGS="$RELEASE_LEARNINGS
- $KEY ($SUMMARY): Release prepared $(date -u '+%Y-%m-%d')"

  # Recurring usability issues (QA failures)
  QA_FAIL=$(echo "$ALL_TEXT" | grep '\[QA LEAD\].*❌\|❌.*\[QA LEAD\]' | head -1)
  [ -n "$QA_FAIL" ] && USABILITY_ISSUES="$USABILITY_ISSUES
- $KEY ($SUMMARY): QA failed — check test cases for usability patterns"

  # Security HIGH risk
  SEC_HIGH=$(echo "$ALL_TEXT" | grep '\[SECURITY\].*HIGH\|HIGH.*Risk' | head -1)
  [ -n "$SEC_HIGH" ] && SECURITY_NOTES="$SECURITY_NOTES
- $KEY ($SUMMARY): HIGH security risk flagged [$(date -u '+%Y-%m-%d')]"

  # Release RED risk
  RED=$(echo "$ALL_TEXT" | grep '\[RELEASE RISK\].*RED\|RED.*Risk' | head -1)
  [ -n "$RED" ] && RISK_NOTES="$RISK_NOTES
- $KEY ($SUMMARY): RED release risk flagged [$(date -u '+%Y-%m-%d')]"

  # Product governance flags
  GOV_DEFER=$(echo "$ALL_TEXT" | grep '\[PRODUCT GOVERNANCE\].*DEFER\|\[PRODUCT GOVERNANCE\].*FLAG' | head -1)
  [ -n "$GOV_DEFER" ] && GOV_FLAGS="$GOV_FLAGS
- $KEY ($SUMMARY): Governance flagged for review [$(date -u '+%Y-%m-%d')]"

done < <(echo "$RECENT" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"')

# ── Write only if there's something to record ──────────────────────────────
ANYTHING=0
for var in "$ARCH_DECISIONS" "$UX_RATIONALE" "$TECH_DEBT_ITEMS" "$RELEASE_LEARNINGS" \
           "$USABILITY_ISSUES" "$SECURITY_NOTES" "$RISK_NOTES" "$GOV_FLAGS"; do
  [ -n "$var" ] && ANYTHING=1 && break
done

[ "$ANYTHING" -eq 0 ] && exit 0

{
  echo ""
  echo "## $TIMESTAMP"
  echo ""

  [ -n "$ARCH_DECISIONS" ] && {
    echo "### Architecture Decisions"
    echo "$ARCH_DECISIONS"
    echo ""
  }

  [ -n "$UX_RATIONALE" ] && {
    echo "### UX Rationale"
    echo "$UX_RATIONALE"
    echo ""
  }

  [ -n "$TECH_DEBT_ITEMS" ] && {
    echo "### Technical Debt"
    echo "$TECH_DEBT_ITEMS"
    echo ""
  }

  [ -n "$RELEASE_LEARNINGS" ] && {
    echo "### Release Learnings"
    echo "$RELEASE_LEARNINGS"
    echo ""
  }

  [ -n "$USABILITY_ISSUES" ] && {
    echo "### Recurring Usability Issues"
    echo "$USABILITY_ISSUES"
    echo ""
  }

  [ -n "$SECURITY_NOTES" ] && {
    echo "### Security Notes (HIGH Risk)"
    echo "$SECURITY_NOTES"
    echo ""
  }

  [ -n "$RISK_NOTES" ] && {
    echo "### Release Risk Events (RED)"
    echo "$RISK_NOTES"
    echo ""
  }

  [ -n "$GOV_FLAGS" ] && {
    echo "### Product Governance Flags"
    echo "$GOV_FLAGS"
    echo ""
  }

  echo "---"
} >> "$MEMORY_FILE"

git -C "$REPO_ROOT" add PRODUCT_MEMORY.md 2>/dev/null
git -C "$REPO_ROOT" diff --cached --quiet || \
  git -C "$REPO_ROOT" commit -m "chore: update Product Memory [$TIMESTAMP]" 2>/dev/null

echo "Product Memory Agent: Log updated with §7 §11 entries (UX rationale, debt, learnings, risks)"
exit 0
