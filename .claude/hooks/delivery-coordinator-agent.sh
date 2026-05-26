#!/usr/bin/env bash
# Delivery Coordinator & Scrum Agent — Per Agent Role Specifications v1.0 §5
# Mission: Maintain sprint flow, dependency visibility, and delivery predictability
# Authority: Recommend workflow actions; no auto-transitions (Phase 1); no priority changes without PM
# Usage: delivery-coordinator-agent.sh [sprint-summary]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

MAX_IN_FLIGHT="${PRODUCT_WIP_LIMIT:-6}"  # per-product WIP limit (products/<id>/config.env)

# Fetch all relevant sprint states
IN_DEV=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Development%22,%22In+Progress%22)+AND+issuetype=Story&maxResults=20&fields=summary,labels,priority,updated" 2>/dev/null || echo '{"issues":[],"total":0}')
BUGS_IN_FLIGHT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Bug+AND+status+not+in+(Done,Closed)&maxResults=10&fields=summary,priority" 2>/dev/null || echo '{"issues":[],"total":0}')
BLOCKED=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+labels=blocked+AND+status+not+in+(Done,Closed)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[],"total":0}')
STALE=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+not+in+(Done,Closed)AND+updated<=-7d&maxResults=10&fields=summary,status,updated" 2>/dev/null || echo '{"issues":[],"total":0}')
REFINED=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22Refined%22,%22Ready+for+Development%22)&maxResults=10&fields=summary,priority" 2>/dev/null || echo '{"issues":[],"total":0}')
DONE=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=Done+AND+updated>=-7d&maxResults=20&fields=summary" 2>/dev/null || echo '{"issues":[],"total":0}')

IN_DEV_COUNT=$(echo "$IN_DEV" | jq '.total // 0')
IN_DEV_DEBT=$(echo "$IN_DEV" | jq '[.issues[] | select(.fields.labels[]? == "tech-debt")] | length' 2>/dev/null || echo 0)
IN_DEV_BUGS=$(echo "$BUGS_IN_FLIGHT" | jq '.total // 0')
IN_DEV_FEATURES=$((IN_DEV_COUNT - IN_DEV_DEBT))
BLOCKED_COUNT=$(echo "$BLOCKED" | jq '.issues | length')
STALE_COUNT=$(echo "$STALE" | jq '.issues | length')
REFINED_COUNT=$(echo "$REFINED" | jq '.issues | length')
DONE_COUNT=$(echo "$DONE" | jq '.issues | length')

[ "$IN_DEV_COUNT" -eq 0 ] && [ "$REFINED_COUNT" -eq 0 ] && exit 0

echo "[DELIVERY COORDINATOR] Generating sprint health report ($TIMESTAMP)"

# Capacity math
CAPACITY_USED=$((IN_DEV_COUNT))
CAPACITY_AVAILABLE=$((MAX_IN_FLIGHT - CAPACITY_USED))
[ "$CAPACITY_AVAILABLE" -lt 0 ] && CAPACITY_AVAILABLE=0

# Allocation percentages (§9 target)
TOTAL_ACTIVE=$((IN_DEV_COUNT + IN_DEV_BUGS))
PCT_FEATURES=$([ "$TOTAL_ACTIVE" -gt 0 ] && echo "$((IN_DEV_FEATURES * 100 / TOTAL_ACTIVE))" || echo 0)
PCT_DEBT=$([ "$TOTAL_ACTIVE" -gt 0 ] && echo "$((IN_DEV_DEBT * 100 / TOTAL_ACTIVE))" || echo 0)
PCT_BUGS=$([ "$TOTAL_ACTIVE" -gt 0 ] && echo "$((IN_DEV_BUGS * 100 / TOTAL_ACTIVE))" || echo 0)

# Sprint health verdict
HEALTH="GREEN"
[ "$BLOCKED_COUNT" -gt 2 ] && HEALTH="YELLOW"
[ "$STALE_COUNT" -gt 3 ] && HEALTH="YELLOW"
[ "$IN_DEV_COUNT" -gt "$MAX_IN_FLIGHT" ] && HEALTH="YELLOW"
[ "$BLOCKED_COUNT" -gt 5 ] && HEALTH="RED"
[ "$IN_DEV_COUNT" -gt "$((MAX_IN_FLIGHT + 3))" ] && HEALTH="RED"

cat << EOF
[DELIVERY COORDINATOR] Sprint Health Report — $TIMESTAMP

## 1. Sprint Health
Status: $(case "$HEALTH" in GREEN) echo "✅ GREEN" ;; YELLOW) echo "⚠️ YELLOW" ;; RED) echo "🔴 RED" ;; esac)

Sprint Allocation vs §9 Governance Targets:
  Feature work:   $PCT_FEATURES%  (target: 50-60%)  — $IN_DEV_FEATURES stories
  Technical debt: $PCT_DEBT%  (target: 15-20%)  — $IN_DEV_DEBT stories
  Bugs/support:   $PCT_BUGS%  (target: 15-20%)  — $IN_DEV_BUGS bugs

Completed this week:  $DONE_COUNT stories
WIP limit:            $IN_DEV_COUNT / $MAX_IN_FLIGHT ($([ "$IN_DEV_COUNT" -ge "$MAX_IN_FLIGHT" ] && echo "AT LIMIT" || echo "OK"))
Capacity remaining:   $CAPACITY_AVAILABLE slot(s) for new work

## 2. Work In Progress
$(
  echo "In Development ($IN_DEV_COUNT stories):"
  echo "$IN_DEV" | jq -r '.issues[] | "  - \(.key): \(.fields.summary)"' 2>/dev/null | head -10 || echo "  (none)"
  if [ "$IN_DEV_BUGS" -gt 0 ]; then
    echo ""
    echo "Active Bugs ($IN_DEV_BUGS):"
    echo "$BUGS_IN_FLIGHT" | jq -r '.issues[] | "  - \(.key) [\(.fields.priority.name // "Medium")]: \(.fields.summary)"' 2>/dev/null | head -5
  fi
  if [ "$REFINED_COUNT" -gt 0 ]; then
    echo ""
    echo "Queue — Ready for Development ($REFINED_COUNT stories):"
    echo "$REFINED" | jq -r '.issues[] | "  - \(.key): \(.fields.summary)"' 2>/dev/null | head -5
  fi
)

## 3. Blockers
$(
  if [ "$BLOCKED_COUNT" -gt 0 ]; then
    echo "⚠️ $BLOCKED_COUNT blocked ticket(s):"
    echo "$BLOCKED" | jq -r '.issues[] | "  🛑 \(.key): \(.fields.summary) (\(.fields.status.name))"' 2>/dev/null
    echo ""
    echo "  Action: Each blocked ticket needs owner + unblock plan today"
  else
    echo "✅ No blocked tickets"
  fi
)

Stale (no activity >7 days):
$(
  if [ "$STALE_COUNT" -gt 0 ]; then
    echo "⚠️ $STALE_COUNT stale ticket(s):"
    echo "$STALE" | jq -r '.issues[] | "  ⏰ \(.key): \(.fields.summary) (last: \(.fields.updated // "?"))"' 2>/dev/null | head -5
  else
    echo "✅ No stale tickets"
  fi
)

## 4. Dependencies
$(
  # Detect cross-story dependencies from comment patterns
  CROSS_DEPS=$(echo "$IN_DEV" | jq -r '.issues[] | select(.fields.summary | test("depend|block|wait|after|require"; "i")) | "  ⛓️  \(.key): \(.fields.summary)"' 2>/dev/null)
  if [ -n "$CROSS_DEPS" ]; then
    echo "Cross-story dependencies detected:"
    echo "$CROSS_DEPS"
    echo ""
    echo "  ⚠️ Validate these are unblocked before sprint end"
  else
    echo "✅ No obvious cross-story dependencies detected in WIP titles"
    echo "  (Always verify dependencies in standup — this is heuristic only)"
  fi
)

## 5. Carryover Risk
$(
  RISKY_COUNT=$((BLOCKED_COUNT + STALE_COUNT))
  if [ "$RISKY_COUNT" -gt 0 ]; then
    echo "⚠️ Carryover risk: $RISKY_COUNT tickets flagged (blocked + stale)"
    echo ""
    echo "  At-risk stories:"
    echo "$BLOCKED" | jq -r '.issues[] | "  - \(.key): blocked"' 2>/dev/null
    echo "$STALE" | jq -r '.issues[] | "  - \(.key): stale"' 2>/dev/null | head -5
    echo ""
    if [ "$RISKY_COUNT" -gt 3 ]; then
      echo "  Risk Level: HIGH — escalate to TPM"
    else
      echo "  Risk Level: MEDIUM — monitor in standup"
    fi
  else
    echo "✅ LOW carryover risk — sprint tracking healthy"
  fi
)

## 6. Recommended Actions
$(
  echo "Immediate actions:"

  if [ "$BLOCKED_COUNT" -gt 0 ]; then
    echo "  1. ⛔ UNBLOCK: Assign owners to $BLOCKED_COUNT blocked tickets immediately"
  fi
  if [ "$STALE_COUNT" -gt 0 ]; then
    echo "  2. ⏰ INVESTIGATE: $STALE_COUNT stale tickets (>7 days no activity) — check in standup"
  fi
  if [ "$IN_DEV_COUNT" -ge "$MAX_IN_FLIGHT" ]; then
    echo "  3. 🚦 WIP LIMIT: Sprint at capacity ($IN_DEV_COUNT/$MAX_IN_FLIGHT) — finish before starting new work"
  fi
  if [ "$CAPACITY_AVAILABLE" -gt 0 ] && [ "$REFINED_COUNT" -gt 0 ]; then
    echo "  4. ✅ INTAKE: $CAPACITY_AVAILABLE slot(s) available; $REFINED_COUNT stories ready for development"
    echo "     Move highest-priority refined story to In Development"
  fi

  # Allocation warnings
  if [ "$PCT_FEATURES" -lt 50 ] && [ "$TOTAL_ACTIVE" -gt 0 ]; then
    echo "  5. 📊 ALLOCATION: Feature work ($PCT_FEATURES%) below target (50-60%) — review with PM"
  fi
  if [ "$PCT_DEBT" -lt 15 ] && [ "$TOTAL_ACTIVE" -gt 0 ]; then
    echo "  6. 📊 ALLOCATION: Tech debt ($PCT_DEBT%) below target (15-20%) — review with PM"
  fi
)

## 7. Escalations Needed
$(
  NEEDS_ESCALATION="No"
  ESCALATION_REASONS=""

  if [ "$IN_DEV_COUNT" -gt "$((MAX_IN_FLIGHT + 2))" ]; then
    NEEDS_ESCALATION="Yes"
    ESCALATION_REASONS="$ESCALATION_REASONS
  - Sprint overcommitted ($IN_DEV_COUNT/$MAX_IN_FLIGHT) — delivery risk"
  fi
  if [ "$BLOCKED_COUNT" -gt 3 ]; then
    NEEDS_ESCALATION="Yes"
    ESCALATION_REASONS="$ESCALATION_REASONS
  - $BLOCKED_COUNT blocked tickets — TPM coordination required"
  fi
  if [ "$STALE_COUNT" -gt 4 ]; then
    NEEDS_ESCALATION="Yes"
    ESCALATION_REASONS="$ESCALATION_REASONS
  - $STALE_COUNT stale tickets — team capacity or prioritization issue"
  fi

  echo "$NEEDS_ESCALATION"
  [ "$NEEDS_ESCALATION" = "Yes" ] && echo "  Escalation reasons:$ESCALATION_REASONS"
  [ "$NEEDS_ESCALATION" = "No" ] && echo "  Sprint is tracking normally"
)

---
[Delivery Coordinator & Scrum Agent] — Per Agent Role Specifications v1.0 §5
NOTE: Ticket transitions are NOT automated (Phase 1). Recommended actions require human / PM approval.
EOF

# Escalate if sprint is overcommitted
if [ "$IN_DEV_COUNT" -gt "$((MAX_IN_FLIGHT + 2))" ] || [ "$BLOCKED_COUNT" -gt 3 ]; then
  FIRST_KEY=$(echo "$IN_DEV" | jq -r '.issues[0].key // ""')
  [ -n "$FIRST_KEY" ] && \
    escalate_to_tpm "$FIRST_KEY" \
      "Sprint delivery risk: $IN_DEV_COUNT in development (max $MAX_IN_FLIGHT), $BLOCKED_COUNT blocked. Per §16: Delivery speed < Stability." \
      "DELIVERY COORDINATOR" 2>/dev/null || true
fi
