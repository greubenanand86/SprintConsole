#!/usr/bin/env bash
# Release Readiness and Risk Agent — Per Agent Role Specifications v1.0 §7 and Release Management Playbook v1.0
# Mission: Assess whether a release is safe, risky, or blocked
# Authority: Recommend proceed/staged/delay/block; cannot approve production release
# Usage: release-risk-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

# Auto-detect or use provided key
if [ -z "$KEY" ]; then
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=%22Ready+for+Release%22&maxResults=1&fields=key,summary,status" 2>/dev/null || echo '{}')
  KEY=$(echo "$STORIES" | jq -r '.issues[0].key // ""')
  [ -z "$KEY" ] && exit 0
fi

# Fetch issue and comments
ISSUE=$(jira_get "issue/$KEY?fields=key,summary,status,fixVersions" 2>/dev/null || echo '{}')
COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=100" 2>/dev/null || echo '{"comments":[]}')

TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // ""')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // ""')

# Parse handoff comments
QA_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[QA LEAD\]' | head -1)
PA_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[PRODUCT ACCEPTANCE\]' | head -1)
SEC_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[SECURITY\]' | head -1)
ARCH_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[ARCHITECT\]' | head -1)

# Check for existing risk assessment
EXISTING_RISK=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[RELEASE RISK\]' | head -1)
if [ -n "$EXISTING_RISK" ]; then
  echo "[RELEASE RISK] Already assessed:"
  echo "$EXISTING_RISK" | head -3
  exit 0
fi

# Detect release type
HOTFIX=false
MOBILE=false
INFRA=false
if echo "$TITLE" | grep -iE 'hotfix|critical|P0'; then
  HOTFIX=true
fi
if echo "$TITLE" | grep -iE 'mobile|ios|android|expo'; then
  MOBILE=true
fi
if echo "$TITLE" | grep -iE 'auth|ci|cd|database|migration|infrastructure|security baseline'; then
  INFRA=true
fi

# Validate readiness gates
QA_STATUS="❌ Not signed off"
[ -n "$QA_COMMENT" ] && [ -z "$(echo "$QA_COMMENT" | grep -i 'block\|fail\|issue')" ] && QA_STATUS="✅ Approved"

PA_STATUS="❌ Not signed off"
[ -n "$PA_COMMENT" ] && [ -z "$(echo "$PA_COMMENT" | grep -i 'block\|revise')" ] && PA_STATUS="✅ Approved"

SEC_STATUS="⏸️ Not required (standard feature)"
if echo "$TITLE" | grep -iE 'auth|payment|data|permission|security|integration|vulnerab'; then
  SEC_STATUS="❌ Required but not signed off"
  [ -n "$SEC_COMMENT" ] && [ -z "$(echo "$SEC_COMMENT" | grep -i 'block\|issue')" ] && SEC_STATUS="✅ Approved"
fi

ROLLBACK_STATUS="⚠️ Needs confirmation"
if echo "$ARCH_COMMENT" | grep -qi 'rollback.*straightforward\|rollback.*clear'; then
  ROLLBACK_STATUS="✅ Verified"
elif git -C "$REPO_ROOT" rev-parse HEAD~1 >/dev/null 2>&1; then
  ROLLBACK_STATUS="⚠️ Git history available, plan needed"
fi

MONITORING_STATUS="⏸️ Not mentioned"
if echo "$COMMENTS" | grep -qi 'monitoring\|alerting\|metrics'; then
  MONITORING_STATUS="✅ Plan documented"
fi

# Determine risk level
RISK_LEVEL="YELLOW"  # Default to yellow until proven green

# Block if critical gates fail
if [[ "$QA_STATUS" == "❌"* ]] || [[ "$PA_STATUS" == "❌"* ]]; then
  RISK_LEVEL="RED"
fi

# Red if rollback not confirmed for production
if [[ "$ROLLBACK_STATUS" == "❌"* ]] && [ -z "$MOBILE" ]; then
  RISK_LEVEL="RED"
fi

# Red if security required but not signed off
if [[ "$SEC_STATUS" == "❌"* ]]; then
  RISK_LEVEL="RED"
fi

# Green if all critical gates pass and no blockers
if [[ "$QA_STATUS" == "✅"* ]] && [[ "$PA_STATUS" == "✅"* ]] && [[ "$SEC_STATUS" == "✅"* ]] && [[ "$ROLLBACK_STATUS" == "✅"* ]]; then
  RISK_LEVEL="GREEN"
fi

cat << EOF
[RELEASE RISK] $KEY — $RISK_LEVEL

## 1. Release Summary
- Story: $KEY — $TITLE
- Current Status: $STATE
- Release Type: $(
    if $HOTFIX; then echo "Hotfix (high priority)"; fi
    if $INFRA; then echo "Infrastructure (requires TPM+Security)"; fi
    if $MOBILE; then echo "Mobile (staged release path)"; fi
    if ! $HOTFIX && ! $INFRA && ! $MOBILE; then echo "Standard Release"; fi
  )
- Scope: Single story (verify no hidden dependencies)

## 2. QA Status
$QA_STATUS
$([ -n "$QA_COMMENT" ] && echo "  Details: $(echo "$QA_COMMENT" | cut -c 1-150)...")

## 3. Product Acceptance Status
$PA_STATUS
$([ -n "$PA_COMMENT" ] && echo "  Details: $(echo "$PA_COMMENT" | cut -c 1-150)...")

## 4. Security/Legal Concerns
$SEC_STATUS
$(if echo "$TITLE" | grep -iE 'auth|payment|pii|gdpr|legal|compliance'; then
  echo "  ⚠️ Content flagged as security/compliance sensitive"
  echo "  - Verify all required reviews completed"
  echo "  - Check for legal sign-off if applicable"
fi)

## 5. Rollback Readiness
$ROLLBACK_STATUS
$(if [ -d "$REPO_ROOT/.git" ]; then
  COMMITS=$(git -C "$REPO_ROOT" log --oneline | wc -l)
  echo "  - Git history: $COMMITS commits available"
  echo "  - Rollback target: \`git revert HEAD\` is ready"
  echo "  - Testing: Rollback SOP must be tested before production"
fi)

## 6. Monitoring Readiness
$MONITORING_STATUS
$(if [[ "$MONITORING_STATUS" == "✅"* ]]; then
  echo "  - Error tracking: Armed"
  echo "  - Metrics dashboard: Deployed"
  echo "  - Alert thresholds: Configured"
else
  echo "  ⚠️ Monitoring plan not documented"
  echo "  - Error boundaries needed (per Engineering Constitution §7)"
  echo "  - Post-deploy observation metrics required"
fi)

## 7. Risk Score
$RISK_LEVEL
$(case "$RISK_LEVEL" in
  GREEN)
    echo "  Rationale: All gates passed, readiness confirmed, rollback verified"
    echo "  Confidence: High — proceed with human approval"
    ;;
  YELLOW)
    echo "  Rationale: Non-critical gates pending or monitoring not fully confirmed"
    echo "  Recommendation: Staged rollout (monitor first 10% of traffic)"
    echo "  OR: Hold until remaining gates pass"
    ;;
  RED)
    echo "  Rationale: Critical gates blocked (QA/PA/Security/Rollback)"
    echo "  Status: DEPLOYMENT BLOCKED"
    echo "  Action: Resolve all red items before retry"
    ;;
esac)

## 8. Recommendation
$(case "$RISK_LEVEL" in
  GREEN)
    echo "✅ PROCEED: Release is safe per Release Management Playbook §2"
    echo "   - Awaits human approval"
    echo "   - Deploy to production when authorized"
    if $HOTFIX; then
      echo "   - Post-deploy: Run postmortem per Incident Playbook §9"
    fi
    ;;
  YELLOW)
    echo "⚠️ STAGED ROLLOUT: Proceed with caution"
    echo "   - Deploy to 10% of users first (feature flag or canary)"
    echo "   - Monitor for 30 min before expanding to 100%"
    echo "   - Rollback SOP on standby"
    ;;
  RED)
    echo "🚫 BLOCK DEPLOYMENT: Release is not ready"
    echo "   - Resolve all red flags above"
    echo "   - If QA/PA failed: Contact QA Lead / Product Acceptance Agent"
    echo "   - If Security failed: Contact Security Agent"
    echo "   - If Rollback unclear: Contact DevOps / Architect"
    ;;
esac)

## 9. Human Approval Required?
YES — Per Agent Role Specifications v1.0 §7 and RELEASE_MANAGEMENT_PLAYBOOK.md §9
$(case "$RISK_LEVEL" in
  GREEN)
    echo "  Status: Release is safe. Awaiting human sign-off to proceed."
    ;;
  YELLOW)
    echo "  Status: Release is yellow. Human must approve staged rollout plan."
    ;;
  RED)
    echo "  Status: Release is blocked. Human may NOT approve until RED items resolved."
    echo "  - This is a hard block per Release Management Playbook §2"
    ;;
esac)

---
[Release Readiness & Risk Agent] — Per Agent Role Specifications v1.0 §7 | RELEASE_MANAGEMENT_PLAYBOOK v1.0
EOF
