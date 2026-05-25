#!/usr/bin/env bash
# Security Agent
# Reviews "In Review" stories touching sensitive areas per governance §7
# Posts security assessment — does NOT approve; flags for mandatory human review

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status=%22In+Review%22&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Sensitive areas per governance §7
SENSITIVE_PATTERN="auth|login|logout|password|credential|token|session|permission|role|payment|billing|charge|invoice|pii|personal data|learner data|gdpr|privacy|encrypt|certificate|secret|api.key|integration|webhook|oauth|2fa|mfa"

echo "Security Agent: Scanning $COUNT in-review stories for sensitive areas"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  # Skip if already reviewed
  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_SEC=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[SECURITY\]' || true)
  [ "$HAS_SEC" -gt 0 ] && continue

  SUMMARY_LOWER=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]')
  echo "$SUMMARY_LOWER" | grep -qE "$SENSITIVE_PATTERN" || continue

  echo "Security Agent: Sensitive area detected in $KEY — running review"

  SEC_REVIEW=$(claude --print \
"You are the Security Agent for SprintOps Console (governance §7).

Story: $SUMMARY

Sensitive areas requiring review: authentication, authorization, payments, credentials,
learner data, PII handling, integrations, webhooks, session management.

Read relevant source files and assess this story for security concerns.

Output EXACTLY this format:

RISK_LEVEL: <LOW|MEDIUM|HIGH>

CONCERNS:
- <specific concern or 'None identified'>

REQUIRED_ACTIONS:
- <concrete action required or 'None'>

SIGN_OFF_REQUIRED: <YES|NO>" \
    --allowedTools "Read,Glob,Grep" \
    --no-conversation 2>/dev/null)

  RISK=$(echo "$SEC_REVIEW" | grep '^RISK_LEVEL:' | sed 's/^RISK_LEVEL: //')
  SIGN_OFF=$(echo "$SEC_REVIEW" | grep '^SIGN_OFF_REQUIRED:' | sed 's/^SIGN_OFF_REQUIRED: //')

  COMMENT="[SECURITY] Security Review — Risk: ${RISK:-UNKNOWN}

Concerns:
$(echo "$SEC_REVIEW" | sed -n '/^CONCERNS:/,/^REQUIRED_ACTIONS:/p' | grep '^-' | sed 's/^- /⚠ /')

Required Actions:
$(echo "$SEC_REVIEW" | sed -n '/^REQUIRED_ACTIONS:/,/^SIGN_OFF_REQUIRED:/p' | grep '^-' | sed 's/^- /→ /')

Human Sign-off Required: ${SIGN_OFF:-YES}

GOVERNANCE NOTE: Per §7, AI agents may not approve security-sensitive changes.
Human security review is mandatory before this story proceeds to production."

  jira_comment "$KEY" "$COMMENT"
  echo "Security Agent: Posted review for $KEY (Risk: ${RISK:-UNKNOWN}, Sign-off: ${SIGN_OFF:-YES})"

done
exit 0
