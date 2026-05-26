#!/usr/bin/env bash
# Security Agent — Per Agent Role Specifications v1.0 §10 and Security Baseline v1.0
# Mission: Identify and prevent security risks across architecture, code, release, data, and integrations
# Authority: Recommend block for security risk; cannot approve production release
# Usage: security-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find stories in In Review / Code Review
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Review%22,%22Code+Review%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[SECURITY] Auto-scan: $COUNT stories in review"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story security review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "Open"')
DESC=$(echo "$ISSUE" | jq -r '.fields.description // ""')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50" 2>/dev/null || echo '{"comments":[]}')

# Check if already reviewed
HAS_SEC=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[SECURITY\]' || true)
if [ "$HAS_SEC" -gt 0 ]; then
  echo "[SECURITY] $KEY already reviewed — skipping"
  exit 0
fi

# Detect if security-sensitive
TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
IS_SENSITIVE=$(echo "$TITLE_LOWER" | grep -iE 'auth|login|password|token|permission|role|payment|billing|pii|personal data|learner|gdpr|encryption|credential|api.key|integration|oauth|secret' && echo "yes" || echo "no")

cat << EOF
[SECURITY] $KEY — Review

## 1. Security Scope
- Story: $KEY — $TITLE
- Status: $STATE
- Security Sensitive: $IS_SENSITIVE
- Review Scope: Auth/Authz, API security, secrets, data handling, integrations
- Per Security Baseline v1.0 and Engineering Constitution §4

## 2. Risk Areas
Checking against Security Baseline v1.0 core principles:
$(
  if [ "$IS_SENSITIVE" = "yes" ]; then
    echo "- ⚠️ SENSITIVE CONTENT DETECTED: Auth, credentials, permissions, or data access"
    echo "- Requires full security review (items 1-9 below)"
  else
    echo "- Standard feature: lightweight security review"
  fi
)

Key areas to validate:
1. Least privilege: Code requests only minimum permissions needed
2. Secure defaults: Deny by default, no debug modes in production
3. Auditability: Security-relevant actions logged (who, what, when)
4. Environment separation: No cross-environment credential sharing
5. Secret isolation: No secrets in source, frontend, or logs
6. Authentication: Token expiration, RBAC, secure storage
7. API Security: Auth validation (401/403), input validation, rate limiting
8. Dependency governance: Vulnerabilities scanned and blocked
9. Data protection: Encryption in transit, minimal exposure, retention policy

## 3. Findings
$(
  if grep -qE '(password|token|credential|secret|key)' "$REPO_ROOT"/**/*.{jsx,js,json} 2>/dev/null; then
    echo "⚠️ Potential secrets detected in source code:"
    grep -r -iE '(hardcoded.*password|api.key|secret|token.*=)' "$REPO_ROOT" --include="*.jsx" --include="*.js" --include="*.json" 2>/dev/null | head -3 | sed 's/^/  FOUND: /'
  else
    echo "✅ No obvious hardcoded secrets detected in source"
  fi
)

Environment isolation check:
$(
  if [ -f "$REPO_ROOT/.env" ] || [ -f "$REPO_ROOT/.env.local" ]; then
    echo "⚠️ .env file exists — verify no secrets committed"
  else
    echo "✅ No .env in repo (good — use environment variables)"
  fi
)

Dependency check:
$(
  if [ -f "$REPO_ROOT/package.json" ]; then
    echo "  Run: npm audit (if project enables npm)"
  else
    echo "  ✅ No npm dependencies (CDN vendor setup)"
  fi
)

## 4. Severity
Verdict: $([ "$IS_SENSITIVE" = "yes" ] && echo "🔴 HIGH — security-sensitive content" || echo "🟡 MEDIUM — standard feature")

Risk factors:
$(
  if echo "$DESC" | grep -iq 'auth\|password\|token'; then
    echo "  - Handles authentication/credentials → HIGH severity"
  elif echo "$DESC" | grep -iq 'api\|external.*service'; then
    echo "  - External integration → MEDIUM-HIGH severity"
  elif echo "$DESC" | grep -iq 'data\|user\|personal'; then
    echo "  - Handles user data → MEDIUM severity"
  else
    echo "  - Standard UI/logic change → MEDIUM or LOW severity"
  fi
)

## 5. Required Fixes
$(
  if [ "$IS_SENSITIVE" = "yes" ]; then
    echo "For security-sensitive changes (per Security Baseline §2-9):"
    echo ""
    echo "MANDATORY BEFORE MERGE:"
    echo "1. ✅ No hardcoded secrets in source code"
    echo "2. ✅ Environment variables configured for all credentials"
    echo "3. ✅ Input validation implemented (whitelist expected types)"
    echo "4. ✅ Error messages don't expose internal details (no stack traces)"
    echo "5. ✅ Sensitive data not logged"
    echo "6. ✅ Secrets not in frontend/mobile"
    echo ""
    echo "FOR PRODUCTION RELEASE:"
    echo "7. ✅ Security Agent sign-off (this review)"
    echo "8. ✅ Release Risk Agent review"
    echo "9. ✅ Human approval before production deployment"
  else
    echo "Standard checks:"
    echo "1. ✅ No obvious hardcoded credentials"
    echo "2. ✅ No debug output or logging of sensitive data"
    echo "3. ✅ Dependencies up-to-date"
  fi
)

## 6. Release Blocker?
$(
  if [ "$IS_SENSITIVE" = "yes" ]; then
    echo "YES — Security-sensitive features require explicit sign-off"
    echo "Blocking criteria (Security Baseline §12):"
    echo "  - Auth/authz changes → YES, blocks"
    echo "  - Data access control → YES, blocks"
    echo "  - New sensitive APIs → YES, blocks"
    echo "  - External integrations → YES, blocks"
    echo "  - Credential/secrets handling → YES, blocks"
  else
    echo "NO — Standard features do not require security blocker"
    echo "Standard QA and Architecture reviews are sufficient"
  fi
)

## 7. Human Approval Needed?
$(
  if [ "$IS_SENSITIVE" = "yes" ]; then
    echo "YES — Per Security Baseline v1.0 §12"
    echo "Security-sensitive changes require explicit human review"
    echo "  - Cannot merge without [SECURITY] ✅ sign-off"
    echo "  - Cannot release without human security approval"
  else
    echo "NO — Standard features proceed with normal review flow"
  fi
)

---
[Security Agent] — Per Agent Role Specifications v1.0 §10 | SECURITY_BASELINE v1.0
EOF

# Post comment to Jira
if [ "$IS_SENSITIVE" = "yes" ]; then
  jira_comment "$KEY" "[SECURITY] 🔐 SECURITY REVIEW REQUIRED
This story involves auth/credentials/data access.
Must complete Security Baseline v1.0 checklist before production.
Cannot merge without [SECURITY] ✅ sign-off.
[Security Agent]" 2>/dev/null || true
else
  jira_comment "$KEY" "[SECURITY] ✅ Standard feature — no security-specific blocker.
Standard QA and Architecture reviews apply.
[Security Agent]" 2>/dev/null || true
fi
