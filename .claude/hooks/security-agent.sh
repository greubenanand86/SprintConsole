#!/usr/bin/env bash
# Security Agent — Engineering Constitution §4 | Environment Governance v1.0 | Security Baseline v1.0
# Reviews "In Review" stories for §4 + Security Baseline comprehensive security checklist
# Core checklist: no secrets in source, environment isolation, least privilege access,
# dependency scanning, auth validation, input validation, secure storage
# Security Baseline §2-8: least privilege, secure defaults, auditability, environment separation,
# secret isolation, auth standards, API security (rate limiting, error handling), data protection
# Additional checks: test data governance (no production data in lower environments per Env v1.0 §10),
# secrets management (environment variables only, no sharing across environments per Env v1.0 §11)
# Posts security assessment — does NOT approve; flags for mandatory human review

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Review%22,%22Code+Review%22)&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Sensitive areas per §4 / governance §7
SENSITIVE_PATTERN="auth|login|logout|password|credential|token|session|permission|role|payment|billing|charge|invoice|pii|personal data|learner data|gdpr|privacy|encrypt|certificate|secret|api.key|integration|webhook|oauth|2fa|mfa|storage|localStorage|sessionStorage"

echo "Security Agent: Scanning $COUNT in-review stories (§4 compliance)"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_SEC=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[SECURITY\]' || true)
  [ "$HAS_SEC" -gt 0 ] && continue

  SUMMARY_LOWER=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]')
  IS_SENSITIVE=$(echo "$SUMMARY_LOWER" | grep -cE "$SENSITIVE_PATTERN" || true)

  SEC_REVIEW=$(claude --print \
"Role: You are the Security Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Review this story against the Security Baseline v1.0 and Engineering Constitution §4 security checklist. Identify risks, failures, and required actions. Flag anything that requires human security sign-off.

Inputs:
- Story: $SUMMARY
- Source files readable via Read, Glob, and Grep tools

Security Baseline v1.0 + Engineering Constitution §4 mandatory security checklist:

Core principles (§2):
1. Least privilege access: code requests only minimum permissions needed
2. Secure defaults: deny by default, encrypt sensitive data, no debug modes in production
3. Auditability: security-relevant actions logged (who, what, when, where)
4. Environment separation: no cross-environment credential sharing, secrets per environment
5. Secret isolation: no secrets in source code, frontend/mobile, or logs; centralized management

Authentication (§3):
6. Token expiration: access tokens short-lived (15-60 min), refresh tokens longer-lived
7. RBAC implemented: users have roles, permissions checked at API layer
8. Secure storage: HTTP-only cookies (web), Keychain/Keystore (mobile)

API Security (§4):
9. Auth validation: 401 for unauthenticated, 403 for unauthorized
10. Input validation: whitelist expected types, parameterized queries (no SQL injection)
11. Rate limiting awareness: code uses rate limiting to prevent abuse
12. Structured error handling: no stack traces or internal details in error responses

Secrets Management (§5):
13. No secrets in source control, frontend, mobile, or logs
14. Centralized secret management (Vault, AWS Secrets Manager, etc.)
15. Secrets never logged or exposed in stack traces

Dependency Governance (§7):
16. Dependencies scanned for vulnerabilities (npm audit, Snyk, etc.)
17. Known vulnerabilities block deployment
18. Outdated packages monitored and updated

Logging & Auditability (§8):
19. Sensitive operations logged (auth, authorization, data access)
20. Logs include context (who, what, when, where)
21. Logs secure (encrypted, access-controlled, tamper-proof)

Data Protection (§9):
22. Sensitive data encrypted in transit (HTTPS) and at rest (if applicable)
23. Minimal data exposure (only return needed fields)
24. Data retention policy followed
25. Access to sensitive data restricted and audited

Output format — output EXACTLY these sections:

RISK_LEVEL: <LOW|MEDIUM|HIGH>

BASELINE_CHECKLIST:
- Least privilege access: <PASS|FAIL|N/A — reason>
- Secure defaults: <PASS|FAIL|N/A — reason>
- Auditability: <PASS|FAIL|N/A — reason>
- Environment separation: <PASS|FAIL|N/A — reason>
- Secret isolation (no secrets in code/frontend/logs): <PASS|FAIL|N/A — reason>
- Token expiration & RBAC: <PASS|FAIL|N/A — reason>
- Secure storage: <PASS|FAIL|N/A — reason>
- Auth validation (401/403): <PASS|FAIL|N/A — reason>
- Input validation (parameterized): <PASS|FAIL|N/A — reason>
- Rate limiting awareness: <PASS|FAIL|N/A — reason>
- Structured error handling: <PASS|FAIL|N/A — reason>
- Dependency scanning: <PASS|FAIL|N/A — reason>
- Sensitive operations logged: <PASS|FAIL|N/A — reason>
- Encryption (transit & rest): <PASS|FAIL|N/A — reason>
- Data access restrictions: <PASS|FAIL|N/A — reason>

CONCERNS:
- <specific concern, or 'None identified'>

REQUIRED_ACTIONS:
- <concrete action, or 'None'>

SIGN_OFF_REQUIRED: <YES — human security review needed|NO — all checks passed, low risk>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  RISK=$(echo "$SEC_REVIEW" | grep '^RISK_LEVEL:' | sed 's/^RISK_LEVEL: //')
  SIGN_OFF=$(echo "$SEC_REVIEW" | grep '^SIGN_OFF_REQUIRED:' | sed 's/^SIGN_OFF_REQUIRED: //')
  FAIL_COUNT=$(echo "$SEC_REVIEW" | sed -n '/^CHECKLIST:/,/^CONCERNS:/p' | grep -c 'FAIL' || true)

  SENSITIVE_NOTE=""
  [ "$IS_SENSITIVE" -gt 0 ] && SENSITIVE_NOTE="
⚠ SENSITIVE AREA DETECTED: This story touches auth/PII/payments/storage/integrations.
Per Engineering Constitution §4 and Governance §7, human security review is MANDATORY."

  COMMENT="[SECURITY] Security Review — Risk: ${RISK:-UNKNOWN} | Failures: $FAIL_COUNT/7

§4 Checklist:
$(echo "$SEC_REVIEW" | sed -n '/^CHECKLIST:/,/^CONCERNS:/p' | grep '^-' | sed 's/^- /• /')

Concerns:
$(echo "$SEC_REVIEW" | sed -n '/^CONCERNS:/,/^REQUIRED_ACTIONS:/p' | grep '^-' | sed 's/^- /⚠ /')

Required Actions:
$(echo "$SEC_REVIEW" | sed -n '/^REQUIRED_ACTIONS:/,/^SIGN_OFF_REQUIRED:/p' | grep '^-' | sed 's/^- /→ /')

Human Sign-off Required: ${SIGN_OFF:-YES}$SENSITIVE_NOTE

Engineering Constitution §4: Mandatory security checklist.
AI agents may not approve security-sensitive changes. Human review is final authority."

  extract_standard "$SEC_REVIEW"
  COMMENT="$COMMENT
$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"

  # Escalate HIGH/CRITICAL risk to TPM (Agent Interaction Protocols §3 — security/legal escalation)
  if echo "$RISK" | grep -qiE 'HIGH|CRITICAL'; then
    escalate_to_tpm "$KEY" \
      "Security review flagged $RISK risk ($FAIL_COUNT/7 checks failed). §4 conflict resolution: Security beats all other priorities. Human sign-off required before proceeding." \
      "SECURITY AGENT"
  fi

  echo "Security Agent: $KEY reviewed (Risk: ${RISK:-UNKNOWN}, Failures: $FAIL_COUNT, Sign-off: ${SIGN_OFF:-YES})"

done
exit 0
