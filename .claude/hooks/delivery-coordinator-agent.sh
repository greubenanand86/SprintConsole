#!/usr/bin/env bash
# Delivery Coordinator Agent — Jira Workflow Governance §4, Agent Interaction Protocols v1.0
# Sits between Architecture Agent and Dev
# Responsibilities:
#   - Gate "Refined" stories into "Ready for Development"
#   - Enforce §9 sprint allocation (50-60% features, 15-20% debt, 10-15% design, 15-20% bugs)
#   - Write handoff packet per Agent Interaction Protocols §2
#   - Escalate to TPM when sprint is overcommitted or capacity is at risk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

MAX_IN_FLIGHT=6  # max stories in "In Development" before gating new work

# ── Count current sprint work in each allocation category ─────────────────
IN_DEV=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Development%22,%22In+Progress%22)+AND+issuetype=Story&maxResults=20&fields=summary,labels,issuetype")
IN_DEV_COUNT=$(echo "$IN_DEV" | jq '.total // 0')

IN_DEV_DEBT=$(echo "$IN_DEV" | jq '[.issues[] | select(.fields.labels[]? == "tech-debt")] | length' 2>/dev/null || echo 0)
IN_DEV_BUGS=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Development%22,%22In+Progress%22)+AND+issuetype=Bug&maxResults=5&fields=summary" | jq '.total // 0')
IN_DEV_FEATURES=$((IN_DEV_COUNT - IN_DEV_DEBT))

echo "Delivery Coordinator: In Development — $IN_DEV_COUNT stories ($IN_DEV_FEATURES features, $IN_DEV_DEBT debt), $IN_DEV_BUGS bugs"

# ── Check capacity ─────────────────────────────────────────────────────────
if [ "$IN_DEV_COUNT" -ge "$MAX_IN_FLIGHT" ]; then
  echo "Delivery Coordinator: Sprint at capacity ($IN_DEV_COUNT/$MAX_IN_FLIGHT) — no new stories moving to Ready for Development"
  # Escalate if significantly over
  if [ "$IN_DEV_COUNT" -gt "$((MAX_IN_FLIGHT + 2))" ]; then
    FIRST_KEY=$(echo "$IN_DEV" | jq -r '.issues[0].key // ""')
    [ -n "$FIRST_KEY" ] && escalate_to_tpm "$FIRST_KEY" \
      "Sprint overcommitted: $IN_DEV_COUNT stories in development (max $MAX_IN_FLIGHT). Delivery risk per §16." \
      "DELIVERY COORDINATOR"
  fi
  exit 0
fi

CAPACITY_AVAILABLE=$((MAX_IN_FLIGHT - IN_DEV_COUNT))

# ── Fetch "Refined" stories waiting for development ────────────────────────
REFINED=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22Refined%22,%22Ready+for+Development%22)&maxResults=10&fields=summary,description,priority,labels,status&orderBy=priority+ASC")
REFINED_COUNT=$(echo "$REFINED" | jq '.issues | length' 2>/dev/null)
REFINED_COUNT=${REFINED_COUNT:-0}

[ "$REFINED_COUNT" -eq 0 ] && {
  echo "Delivery Coordinator: No refined stories waiting — nothing to coordinate"
  exit 0
}

echo "Delivery Coordinator: $REFINED_COUNT refined stories, $CAPACITY_AVAILABLE capacity slots available"

MOVED=0

echo "$REFINED" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.priority.name // "Medium")|\(.fields.status.name)"' | \
while IFS='|' read -r KEY SUMMARY PRIORITY STATUS; do

  [ "$MOVED" -ge "$CAPACITY_AVAILABLE" ] && break

  # Skip if already at Ready for Development
  [ "$STATUS" = "Ready for Development" ] && continue

  # ── Check prior agent handoffs exist (Definition of Ready gate) ───────────
  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  ALL_TEXTS=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null)

  HAS_ARCHITECT=$(echo "$ALL_TEXTS" | grep -c '\[ARCHITECT\]' || true)
  HAS_GOVERNANCE=$(echo "$ALL_TEXTS" | grep -c '\[PRODUCT GOVERNANCE\]\|\[PM AGENT\]' || true)
  HAS_ESCALATION=$(echo "$ALL_TEXTS" | grep -c '\[ESCALATE → TPM\]' || true)

  # If unresolved escalation, do not move forward
  if [ "$HAS_ESCALATION" -gt 0 ]; then
    TPM_RESOLVED=$(echo "$ALL_TEXTS" | grep -c '\[TPM AGENT\]' || true)
    if [ "$TPM_RESOLVED" -eq 0 ]; then
      echo "Delivery Coordinator: $KEY has unresolved escalation — skipping until TPM resolves"
      continue
    fi
  fi

  # If architect hasn't refined it, don't move forward
  if [ "$HAS_ARCHITECT" -eq 0 ]; then
    echo "Delivery Coordinator: $KEY missing architect refinement — not ready for development"
    continue
  fi

  # ── §9 Sprint allocation check ─────────────────────────────────────────
  IS_DEBT=$(echo "$ALL_TEXTS" | grep -ci 'tech.debt\|\[tech debt\]' || true)
  STORY_TYPE="feature"
  [ "$IS_DEBT" -gt 0 ] && STORY_TYPE="debt"

  # Warn if allocation is imbalanced (advisory only — don't block)
  ALLOC_NOTE=""
  if [ "$STORY_TYPE" = "feature" ] && [ "$IN_DEV_FEATURES" -ge 5 ]; then
    ALLOC_NOTE="Note: Sprint is feature-heavy ($IN_DEV_FEATURES features). §9 recommends 50-60% features."
  fi
  if [ "$STORY_TYPE" = "debt" ] && [ "$IN_DEV_DEBT" -ge 3 ]; then
    ALLOC_NOTE="Note: Sprint has significant debt work ($IN_DEV_DEBT debt stories). §9 limit is 15-20%."
  fi

  # ── Pull last handoff context from architect ───────────────────────────
  LAST_HANDOFF=$(read_last_handoff "$KEY")
  TECH_NOTES=$(echo "$LAST_HANDOFF" | sed 's/.*Technical Notes: //' | cut -d'|' -f1 | head -c 200)
  RISKS=$(echo "$LAST_HANDOFF" | sed 's/.*Risks: //' | cut -d'|' -f1 | head -c 150)

  # ── Transition to Ready for Development ──────────────────────────────
  jira_transition "$KEY" "Ready for Development"
  jira_transition "$KEY" "In Progress"  # fallback

  # ── Write handoff packet for Dev/QA ──────────────────────────────────
  write_handoff "$KEY" \
    "DELIVERY COORDINATOR" \
    "In Development → Code Review → Ready for QA" \
    "$SUMMARY" \
    "See story description" \
    "See [UX DESIGNER] comment in Jira" \
    "${TECH_NOTES:-See [ARCHITECT] comment}" \
    "${RISKS:-See [ARCHITECT] comment}" \
    "See story description" \
    "None — architect refinement complete" \
    "Feature implemented, all AC met, passing QA checks, accessibility verified (§5)"

  SPRINT_STATUS="Sprint: $IN_DEV_COUNT in dev, $CAPACITY_AVAILABLE slots. §9 allocation: ${IN_DEV_FEATURES} features / ${IN_DEV_DEBT} debt / ${IN_DEV_BUGS} bugs."

  jira_comment "$KEY" "[DELIVERY COORDINATOR] ✅ Ready for Development — $PRIORITY priority

$SPRINT_STATUS
${ALLOC_NOTE:+
⚠ Allocation advisory: $ALLOC_NOTE}

Handoff Packet written. Development may begin.
Governance §5 Definition of Ready confirmed: Architect refinement present, no unresolved escalations.

On completion, move to Code Review for Security + Architect review."

  echo "Delivery Coordinator: ✅ $KEY [$PRIORITY] — moved to Ready for Development"
  MOVED=$((MOVED + 1))

done

echo "Delivery Coordinator: $MOVED stories readied for development"
[ "$MOVED" -gt 0 ] && exit 2
exit 0
