#!/usr/bin/env bash
# TPM Agent — Agent Interaction Protocols v1.0
# Escalation coordinator per protocol escalation rules:
# - Agents disagree (conflicting verdicts on same story)
# - Scope changes detected
# - Delivery risk increases (repeated QA failures, stuck stories)
# - QA blocks release
# - Security/legal concerns appear
# - Architecture conflicts arise
#
# Conflict Resolution Order (§4):
# 1. Security/legal  2. Stability  3. UX  4. Product value  5. Maintainability  6. Delivery speed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

# Query all recently updated stories for escalation signals
RECENT=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+updated>=-2h+ORDER+BY+updated+DESC&maxResults=30&fields=summary,status,updated")
COUNT=$(echo "$RECENT" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "TPM Agent: Scanning $COUNT recently updated stories for escalation triggers"

echo "$RECENT" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.status.name)"' | \
while IFS='|' read -r KEY SUMMARY STATUS; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  ALL_TEXTS=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null)

  # ── Skip if TPM already handled this story ───────────────────────────────
  TPM_EXISTS=$(echo "$ALL_TEXTS" | grep -c '\[TPM AGENT\]' || true)
  [ "$TPM_EXISTS" -gt 0 ] && continue

  # ── Detect escalation triggers ───────────────────────────────────────────
  ESCALATION_SIGNALS=""

  # Direct escalation flag from any agent
  DIRECT_ESCALATE=$(echo "$ALL_TEXTS" | grep '\[ESCALATE → TPM\]' | head -3)
  [ -n "$DIRECT_ESCALATE" ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
DIRECT: $DIRECT_ESCALATE"

  # QA failure count > 2 = delivery risk
  QA_FAIL_COUNT=$(echo "$ALL_TEXTS" | grep -c '\[QA LEAD\].*❌' || true)
  [ "$QA_FAIL_COUNT" -ge 2 ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
DELIVERY_RISK: QA failed $QA_FAIL_COUNT times — story stuck in QA loop"

  # Security HIGH risk flag
  SEC_HIGH=$(echo "$ALL_TEXTS" | grep '\[SECURITY\].*HIGH\|HIGH.*Risk' | head -1)
  [ -n "$SEC_HIGH" ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
SECURITY_CONCERN: $SEC_HIGH"

  # Monitoring escalate signal
  MON_ESCALATE=$(echo "$ALL_TEXTS" | grep '\[MONITORING\].*ESCALATE\|ESCALATE.*\[MONITORING\]' | head -1)
  [ -n "$MON_ESCALATE" ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
INCIDENT_ESCALATION: $MON_ESCALATE"

  # PA rejection + prior QA pass = agent disagreement
  PA_REJECT=$(echo "$ALL_TEXTS" | grep '\[PRODUCT ACCEPTANCE\].*❌' | head -1)
  QA_PASS=$(echo "$ALL_TEXTS" | grep '\[QA LEAD\].*✅' | head -1)
  [ -n "$PA_REJECT" ] && [ -n "$QA_PASS" ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
AGENT_DISAGREEMENT: QA approved but Product Acceptance rejected — conflict to resolve"

  # Deploy blocked + RED risk = release governance conflict
  DEPLOY_BLOCK=$(echo "$ALL_TEXTS" | grep '\[DEPLOY SPECIALIST\].*Blocked\|Blocked.*\[DEPLOY SPECIALIST\]' | head -1)
  [ -n "$DEPLOY_BLOCK" ] && ESCALATION_SIGNALS="$ESCALATION_SIGNALS
RELEASE_BLOCKED: $DEPLOY_BLOCK"

  [ -z "$ESCALATION_SIGNALS" ] && continue

  echo "TPM Agent: Escalation signals found for $KEY — analyzing..."

  # ── Claude applies conflict resolution order ─────────────────────────────
  RESOLUTION=$(claude --print \
"You are the TPM Agent for SprintOps Console (Agent Interaction Protocols v1.0).

Story: $SUMMARY ($KEY)
Current Status: $STATUS

Escalation signals detected:
$ESCALATION_SIGNALS

All prior agent activity:
$(echo "$ALL_TEXTS" | grep '\[ARCHITECT\]\|\[QA LEAD\]\|\[SECURITY\]\|\[UX DESIGNER\]\|\[PRODUCT ACCEPTANCE\]\|\[RELEASE RISK\]\|\[DEPLOY SPECIALIST\]\|\[MONITORING\]\|\[INCIDENT\]' | head -20)

Apply the Conflict Resolution Order (Agent Interaction Protocols §4):
1. Security / legal — highest priority; blocks everything
2. Stability — production safety
3. User experience — UX quality
4. Product value — feature correctness
5. Maintainability — code health
6. Delivery speed — lowest priority

TASK:
1. Identify the primary escalation type (agents disagree / scope change / delivery risk / QA block / security / architecture conflict)
2. Identify which conflicting positions exist
3. Apply the resolution order to determine the correct path
4. State whether this requires Human Approval (YES if security/legal/strategic scope change)
5. State the recommended resolution and why

Output EXACTLY this format:

ESCALATION_TYPE: <agents disagree|delivery risk|QA block|security concern|architecture conflict|release blocked>
CONFLICTING_POSITIONS:
- <position 1 from which agent>
- <position 2 from which agent>
RESOLUTION_ORDER_APPLIED: <which priority level wins and why>
RECOMMENDED_ACTION: <what should happen next>
HUMAN_APPROVAL_REQUIRED: <YES — reason|NO>
CONFIDENCE: <HIGH|MEDIUM|LOW>" \
    --allowedTools "Read" \
    --no-conversation 2>/dev/null)

  ESCALATION_TYPE=$(echo "$RESOLUTION" | grep '^ESCALATION_TYPE:' | sed 's/^ESCALATION_TYPE: //')
  RECOMMENDED=$(echo "$RESOLUTION" | grep '^RECOMMENDED_ACTION:' | sed 's/^RECOMMENDED_ACTION: //')
  HUMAN_REQ=$(echo "$RESOLUTION" | grep '^HUMAN_APPROVAL_REQUIRED:' | grep -i 'YES' | wc -l | tr -d ' ')
  CONFIDENCE=$(echo "$RESOLUTION" | grep '^CONFIDENCE:' | sed 's/^CONFIDENCE: //')

  COMMENT="[TPM AGENT] ⚡ Escalation Review — $ESCALATION_TYPE

Story: $SUMMARY ($KEY)
Status: $STATUS

Escalation Signals:
$(echo "$ESCALATION_SIGNALS" | sed 's/^/• /')

Conflicting Positions:
$(echo "$RESOLUTION" | sed -n '/^CONFLICTING_POSITIONS:/,/^RESOLUTION_ORDER_APPLIED:/p' | grep '^-' | sed 's/^- /• /')

Resolution Order Applied (§4):
$(echo "$RESOLUTION" | grep '^RESOLUTION_ORDER_APPLIED:' | sed 's/^RESOLUTION_ORDER_APPLIED: /→ /')

Recommended Action:
→ $RECOMMENDED

Confidence: $CONFIDENCE

$([ "$HUMAN_REQ" -gt 0 ] && echo "🚨 HUMAN APPROVAL REQUIRED
$(echo "$RESOLUTION" | grep '^HUMAN_APPROVAL_REQUIRED:' | sed 's/^HUMAN_APPROVAL_REQUIRED: YES — /Reason: /')")"

  jira_comment "$KEY" "$COMMENT"
  echo "TPM Agent: ⚡ $KEY — $ESCALATION_TYPE resolved [Confidence: $CONFIDENCE]"

done

exit 0
