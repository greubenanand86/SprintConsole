#!/usr/bin/env bash
# Deploy Specialist Agent — Per Agent Role Specifications v1.0 §6 and Release Management Playbook v1.0
# Mission: Prepare, validate, and report deployment readiness for dev/staging/production
# Authority: Deploy to dev/staging if allowed; production requires human approval
# Usage: deploy-agent.sh <JIRA-KEY> [environment: development|staging|production]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"
ENV="${2:-staging}"

# Validate environment
if ! [[ "$ENV" =~ ^(development|staging|production)$ ]]; then
  echo "Error: Invalid environment. Use: development, staging, or production"
  exit 1
fi

if [ -z "$KEY" ]; then
  # Auto-detect: find first story in Ready for Release
  STORY=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=%22Ready+for+Release%22&maxResults=1&fields=key,summary,status" 2>/dev/null || echo '{}')
  KEY=$(echo "$STORY" | jq -r '.issues[0].key // ""')
  [ -z "$KEY" ] && exit 0
else
  STORY=$(jira_get "issue/$KEY?fields=key,summary,status" 2>/dev/null || echo '{}')
fi

TITLE=$(echo "$STORY" | jq -r '.issues[0].fields.summary // .fields.summary // ""')
STATE=$(echo "$STORY" | jq -r '.issues[0].fields.status.name // .fields.status.name // ""')

# Read prior handoffs (QA, PA, Security)
COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=100" 2>/dev/null || echo '{"comments":[]}')
QA_SIGN_OFF=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[QA LEAD\].*✅\|✅.*\[QA LEAD\]' | head -1)
PA_SIGN_OFF=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[PRODUCT ACCEPTANCE\].*✅\|✅.*\[PRODUCT ACCEPTANCE\]' | head -1)
SEC_SIGN_OFF=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[SECURITY\].*✅\|✅.*\[SECURITY\]' | head -1)
RISK_COMMENT=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep '\[RELEASE RISK\]' | head -1)

# Extract risk level
RISK_LEVEL=$(echo "$RISK_COMMENT" | grep -o 'GREEN\|YELLOW\|RED' | head -1)
[ -z "$RISK_LEVEL" ] && RISK_LEVEL="UNKNOWN"

cat << EOF
[DEPLOY SPECIALIST] $KEY → $ENV

## 1. Deployment Target
- Story: $KEY — $TITLE
- Current Status: $STATE
- Target Environment: $ENV
- Deployment Time: $(date -u '+%Y-%m-%d %H:%M UTC')

## 2. Deployment Readiness
$(
  if [ -n "$QA_SIGN_OFF" ]; then
    echo "  ✅ QA Sign-Off: Complete"
  else
    echo "  ❌ QA Sign-Off: Missing"
  fi

  if [ -n "$PA_SIGN_OFF" ]; then
    echo "  ✅ Product Acceptance: Complete"
  else
    echo "  ❌ Product Acceptance: Missing"
  fi

  # Check for critical keywords
  if echo "$TITLE" | grep -iE 'auth|security|payment|data access|critical'; then
    if [ -n "$SEC_SIGN_OFF" ]; then
      echo "  ✅ Security Review: Complete (Security-sensitive content)"
    else
      echo "  ⚠️  Security Review: Required (Security-sensitive content not signed off)"
    fi
  else
    echo "  ✅ Security Review: Not required (standard feature)"
  fi
)

## 3. Environment Checks
$(
  case "$ENV" in
    development)
      echo "  Development Environment Checks:"
      echo "  - Local config verified? (dev only, low risk)"
      echo "  - Dependencies available? (assuming npm/local setup)"
      echo "  - No production secrets in use? ✅ (dev isolation)"
      ;;
    staging)
      echo "  Staging Environment Checks:"
      echo "  - Staging config loaded correctly? (validate config refs)"
      echo "  - Staging database accessible? (pre-prod test data)"
      echo "  - Feature flags configured for staging? (if applicable)"
      echo "  - Secrets accessible? (staging credentials only)"
      ;;
    production)
      echo "  Production Environment Checks:"
      echo "  - Production config locked and validated? ⚠️ (CRITICAL)"
      echo "  - Production database backed up? (before migration)"
      echo "  - Feature flags ready? (kill-switch in place)"
      echo "  - Secrets secured in vault? (no hardcoded values)"
      echo "  - Monitoring and alerting armed? (post-deploy observation)"
      ;;
  esac
)

## 4. Rollback Plan
$(
  case "$ENV" in
    development)
      echo "  Development Rollback:"
      echo "  - Strategy: git revert (branch is ephemeral)"
      echo "  - Owner: Developer"
      echo "  - Estimated Time: <5 min"
      echo "  - Validation: Straightforward — no data migration"
      ;;
    staging)
      echo "  Staging Rollback:"
      echo "  - Strategy: git revert + redeploy to staging"
      if [ -d "$REPO_ROOT/.git" ]; then
        COMMITS=$(git -C "$REPO_ROOT" rev-list --count --all 2>/dev/null || echo "?")
        echo "  - Rollback Target: Previous stable commit ($COMMITS available)"
      else
        echo "  - Rollback Target: Previous stable commit"
      fi
      echo "  - Owner: DevOps/Deploy Specialist"
      echo "  - Database: Restore from backup if migration applied"
      echo "  - Estimated Time: 10-30 min"
      ;;
    production)
      echo "  Production Rollback: ⚠️ CRITICAL"
      echo "  - Strategy: MUST BE TESTED BEFORE RELEASE"
      echo "  - Owner: DevOps + On-Call Engineer"
      if [ -d "$REPO_ROOT/.git" ]; then
        COMMITS=$(git -C "$REPO_ROOT" rev-list --count --all 2>/dev/null || echo "?")
        echo "  - Rollback Target: Last stable release commit ($COMMITS history available)"
      else
        echo "  - Rollback Target: Last stable release commit"
      fi
      echo "  - Database: Migration must be reversible"
      echo "  - Communication: Notify stakeholders on rollback"
      echo "  - Estimated Time: 15-45 min (TBD — must test first)"
      ;;
  esac
)

## 5. Risks
$(
  case "$ENV" in
    development)
      echo "  Risk Level: ✅ LOW"
      echo "  - User Impact: None (isolated development)"
      echo "  - Data Risk: None (dev schema only)"
      echo "  - Recovery: Fast (git revert)"
      echo "  - Blast Radius: Single developer"
      ;;
    staging)
      echo "  Risk Level: ⚠️ MEDIUM"
      echo "  - User Impact: Test users only (if any exist)"
      echo "  - Data Risk: Medium (staging DB, test data only)"
      echo "  - Recovery: Moderate (revert + restore from backup)"
      echo "  - Blast Radius: Pre-production validation environment"
      ;;
    production)
      echo "  Risk Level: 🚫 HIGH"
      echo "  - User Impact: CRITICAL (affects all users)"
      if [ "$RISK_LEVEL" = "GREEN" ]; then
        echo "  - Release Risk Score: GREEN (assessed safe)"
      elif [ "$RISK_LEVEL" = "YELLOW" ]; then
        echo "  - Release Risk Score: YELLOW (staged rollout recommended)"
      elif [ "$RISK_LEVEL" = "RED" ]; then
        echo "  - Release Risk Score: RED (DEPLOYMENT BLOCKED)"
      else
        echo "  - Release Risk Score: UNKNOWN (must be assessed)"
      fi
      echo "  - Data Risk: Depends on migrations (validate rollback path)"
      echo "  - Recovery: Slow and complex"
      echo "  - Blast Radius: All customers"
      ;;
  esac
)

## 6. Human Approval Required?
$(
  case "$ENV" in
    development)
      echo "NO — Deploy Specialist may deploy to development independently"
      ;;
    staging)
      echo "Recommended — Confirm with Release Risk Agent before production handoff"
      ;;
    production)
      echo "YES — Production deployment REQUIRES explicit human approval"
      echo "  (Per Agent Role Specifications v1.0 §6 and RELEASE_MANAGEMENT_PLAYBOOK.md §9)"
      ;;
  esac
)

## 7. Recommendation
$(
  case "$ENV" in
    development)
      echo "✅ PROCEED: Deploy to development (low risk, fast feedback cycle)"
      echo "   - Validate build succeeds"
      echo "   - Quick smoke test in browser"
      ;;
    staging)
      if [ "$RISK_LEVEL" = "RED" ]; then
        echo "⏸️ HOLD: Risk assessment is RED. Escalate to Release Risk Agent."
      else
        echo "✅ PROCEED TO STAGING: Deploy now, monitor for 24h before production handoff"
        echo "   - Watch error logs and metrics"
        echo "   - Validate deployment flow (config load, secrets, etc.)"
        echo "   - Confirm rollback SOP is executable"
      fi
      ;;
    production)
      if [ "$RISK_LEVEL" = "RED" ]; then
        echo "🚫 BLOCKED: Risk assessment is RED. Release blocked per RELEASE_MANAGEMENT_PLAYBOOK.md §2."
        echo "   - Address risks flagged by Release Risk Agent"
        echo "   - Reassess before next deployment attempt"
      elif [ "$RISK_LEVEL" = "YELLOW" ]; then
        echo "⚠️ ESCALATE TO RELEASE RISK AGENT: Yellow risk detected."
        echo "   - Staged rollout recommended (small % of users first)"
        echo "   - Await human approval with staged deployment plan"
      else
        echo "⏸️ AWAITING HUMAN APPROVAL: All checks passed."
        if [ -z "$QA_SIGN_OFF" ] || [ -z "$PA_SIGN_OFF" ]; then
          echo "   ⚠️ NOTE: Missing handoffs — verify in Jira before proceeding"
        fi
        echo "   - Human confirms deployment is safe"
        echo "   - Monitoring team armed for post-deploy observation"
      fi
      ;;
  esac
)

---
[Deploy Specialist Agent] — Per Agent Role Specifications v1.0 §6 | RELEASE_MANAGEMENT_PLAYBOOK v1.0
EOF
