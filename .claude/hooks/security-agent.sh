#!/usr/bin/env bash
# Security Agent — Engineering Constitution §4
# Reviews "In Review" stories for the full §4 security checklist:
# no secrets in source, environment isolation, least privilege, dependency scanning,
# auth validation, input validation, secure storage
# Posts security assessment — does NOT approve; flags for mandatory human review

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22In+Review%22&maxResults=10&fields=summary,description")
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
"You are the Security Agent for SprintOps Console (Engineering Constitution §4).

Story: $SUMMARY

Engineering Constitution §4 mandatory security checklist:
1. No secrets in source control (API keys, tokens, credentials)
2. Environment isolation (no prod config in dev, no hardcoded env values)
3. Least privilege access (request only permissions needed)
4. Dependency scanning (new packages introduce no known vulnerabilities)
5. Auth validation (authentication checked before data access)
6. Input validation (user inputs sanitized and validated)
7. Secure storage practices (no sensitive data in localStorage/plain cookies)

Read relevant source files and evaluate this story against each checklist item.

Output EXACTLY this format:

RISK_LEVEL: <LOW|MEDIUM|HIGH>

CHECKLIST:
- No secrets in source: <PASS|FAIL|N/A — reason>
- Environment isolation: <PASS|FAIL|N/A — reason>
- Least privilege: <PASS|FAIL|N/A — reason>
- Dependency scanning: <PASS|FAIL|N/A — reason>
- Auth validation: <PASS|FAIL|N/A — reason>
- Input validation: <PASS|FAIL|N/A — reason>
- Secure storage: <PASS|FAIL|N/A — reason>

CONCERNS:
- <specific concern, or 'None identified'>

REQUIRED_ACTIONS:
- <concrete action, or 'None'>

SIGN_OFF_REQUIRED: <YES — human security review needed|NO — low risk, proceed>" \
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

  jira_comment "$KEY" "$COMMENT"
  echo "Security Agent: $KEY reviewed (Risk: ${RISK:-UNKNOWN}, Failures: $FAIL_COUNT, Sign-off: ${SIGN_OFF:-YES})"

done
exit 0
