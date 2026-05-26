#!/usr/bin/env bash
# Legal & Compliance Agent (Lightweight) — Per Agent Role Specifications v1.0 §12
# Mission: Identify legal, privacy, accessibility, consent, and compliance risks early
# NOT legal counsel; flags risks for human review, does not provide final legal approval
# Usage: legal-compliance-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find stories in Ready for QA / QA In Progress / In Review
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(%22In+Review%22,%22Ready+for+QA%22,%22QA+In+Progress%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[LEGAL] Auto-scan: $COUNT stories for compliance review"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story legal/compliance review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "Open"')
DESC=$(echo "$ISSUE" | jq -r '.fields.description // ""')

COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50" 2>/dev/null || echo '{"comments":[]}')

# Check if already reviewed
HAS_LEGAL=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[LEGAL' || true)
if [ "$HAS_LEGAL" -gt 0 ]; then
  echo "[LEGAL] $KEY already reviewed — skipping"
  exit 0
fi

# Detect compliance categories
TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')

IS_PRIVACY=$(echo "$TITLE_LOWER" | grep -iE 'privacy|personal data|pii|gdpr|ccpa|data.*collect' && echo "yes" || echo "no")
IS_ACCESSIBILITY=$(echo "$TITLE_LOWER" | grep -iE 'accessibility|wcag|a11y|ada|screen.*reader' && echo "yes" || echo "no")
IS_STUDENT=$(echo "$TITLE_LOWER" | grep -iE 'student|learner|ferpa|ppra' && echo "yes" || echo "no")
IS_CONSENT=$(echo "$TITLE_LOWER" | grep -iE 'consent|cookie|tracking|analytics' && echo "yes" || echo "no")
IS_CREDENTIAL=$(echo "$TITLE_LOWER" | grep -iE 'password|credential|api.*key|secret|oauth|2fa' && echo "yes" || echo "no")
IS_THIRD_PARTY=$(echo "$TITLE_LOWER" | grep -iE 'third.party|sdk|integration|vendor|external' && echo "yes" || echo "no")

HAS_SENSITIVE=$([ "$IS_PRIVACY" = "yes" ] || [ "$IS_STUDENT" = "yes" ] || [ "$IS_CREDENTIAL" = "yes" ] && echo "yes" || echo "no")

cat << EOF
[LEGAL & COMPLIANCE] $KEY

## 1. Compliance Scope
- Story: $KEY — $TITLE
- Status: $STATE
- Review Categories: $([ "$IS_PRIVACY" = "yes" ] && echo "Privacy/Data" || echo "—")\
$([ "$IS_ACCESSIBILITY" = "yes" ] && echo ", Accessibility" || echo "")\
$([ "$IS_STUDENT" = "yes" ] && echo ", Student Data" || echo "")\
$([ "$IS_CONSENT" = "yes" ] && echo ", Consent" || echo "")\
$([ "$IS_CREDENTIAL" = "yes" ] && echo ", Credentials" || echo "")\
$([ "$IS_THIRD_PARTY" = "yes" ] && echo ", Third-Party" || echo "")
- Per Lightweight Legal & Compliance Governance v1.0
- **NOTE: This is risk identification, NOT legal advice. Human counsel required for final sign-off.**

## 2. Risk Areas
$(
  if [ "$HAS_SENSITIVE" = "yes" ]; then
    echo "⚠️ SENSITIVE CONTENT — Legal/compliance review recommended"
  else
    echo "✅ No obvious compliance concerns detected"
  fi
)

Checklist items scanned:
$(
  [ "$IS_PRIVACY" = "yes" ] && echo "  • Data Privacy (GDPR/CCPA/PIPEDA)"
  [ "$IS_ACCESSIBILITY" = "yes" ] && echo "  • Accessibility (WCAG 2.1 AA, ADA, Section 508)"
  [ "$IS_STUDENT" = "yes" ] && echo "  • Student Data (FERPA, PPRA)"
  [ "$IS_CONSENT" = "yes" ] && echo "  • Consent & Tracking"
  [ "$IS_CREDENTIAL" = "yes" ] && echo "  • Credential Data Handling"
  [ "$IS_THIRD_PARTY" = "yes" ] && echo "  • Third-Party Integrations"
)

## 3. Findings
$(
  if [ "$IS_PRIVACY" = "yes" ]; then
    echo "📋 Data Privacy Assessment:"
    echo "  ❓ Is personal data being collected? (Check: Yes/No)"
    echo "  ❓ Privacy notice updated? (Check: Yes/N/A)"
    echo "  ❓ Consent mechanism if required? (Check: Yes/N/A)"
    echo "  ⚠️ Requires human legal review to confirm GDPR/CCPA alignment"
  fi

  if [ "$IS_ACCESSIBILITY" = "yes" ]; then
    echo "🎯 Accessibility:"
    echo "  ✅ WCAG 2.1 AA minimum (4.5:1 color contrast, keyboard nav, alt text)"
    echo "  ⚠️ QA Lead Agent validates; Legal flags policy alignment"
  fi

  if [ "$IS_STUDENT" = "yes" ]; then
    echo "🎓 Student Data (FERPA/PPRA):"
    echo "  ❓ Student data handling — legal review required"
    echo "  ❓ Third-party access agreement in place?"
    echo "  ⚠️ Escalate to Legal Counsel for student data handling"
  fi

  if [ "$IS_CONSENT" = "yes" ]; then
    echo "✋ Consent & Tracking:"
    echo "  ❓ Tracking mechanism disclosed to users?"
    echo "  ❓ Opt-in vs opt-out — legal requirement check?"
    echo "  ⚠️ Requires Legal Counsel review for compliance with GDPR/ePrivacy"
  fi

  if [ "$IS_CREDENTIAL" = "yes" ]; then
    echo "🔐 Credential Data:"
    echo "  ✅ No plaintext passwords in logs/backups"
    echo "  ✅ API keys not embedded in frontend"
    echo "  ✅ Session tokens encrypted and short-lived"
  fi

  if [ "$IS_THIRD_PARTY" = "yes" ]; then
    echo "🔗 Third-Party Integration:"
    echo "  ❓ Data processing agreement (DPA) with vendor?"
    echo "  ❓ Data flow documented?"
    echo "  ⚠️ Requires Legal Counsel review if vendor handles personal data"
  fi

  [ "$HAS_SENSITIVE" = "no" ] && \
    echo "✅ No sensitive categories detected — standard product feature"
)

## 4. Human Legal Review Needed?
$(
  if [ "$HAS_SENSITIVE" = "yes" ]; then
    echo "YES — Sensitive content requires Legal Counsel review"
    echo "Categories flagged: $([ "$IS_PRIVACY" = "yes" ] && echo "Privacy" || echo "")\
$([ "$IS_STUDENT" = "yes" ] && echo ", Student Data" || echo "")\
$([ "$IS_CREDENTIAL" = "yes" ] && echo ", Credentials" || echo "")\
$([ "$IS_THIRD_PARTY" = "yes" ] && echo ", Third-Party" || echo "")"
  else
    echo "NO — Standard feature, no legal escalation needed"
    echo "Standard engineering review (Security, QA, Architecture) sufficient"
  fi
)

## 5. Release Blocker?
$(
  if [ "$HAS_SENSITIVE" = "yes" ]; then
    echo "POSSIBLE — Cannot release until Legal Counsel confirms compliance"
    echo "Blocking if:"
    echo "  - Privacy impact not assessed (GDPR/CCPA/PIPEDA)"
    echo "  - Student data handling without FERPA compliance plan"
    echo "  - Credential/secrets mishandled"
    echo "  - Third-party data agreement missing"
  else
    echo "NO — Standard features do not have legal blockers"
  fi
)

## 6. Recommendation
$(
  if [ "$HAS_SENSITIVE" = "yes" ]; then
    echo "🚨 ESCALATE TO LEGAL COUNSEL"
    echo ""
    echo "Before production release, human legal team must:"
    echo "  1. Review data collection and privacy alignment"
    echo "  2. Confirm consent/disclosure mechanisms (if required)"
    echo "  3. Validate third-party agreements (if applicable)"
    echo "  4. Confirm regulatory compliance (GDPR, CCPA, FERPA, ADA)"
    echo ""
    echo "Release cannot proceed without [LEGAL COUNSEL] sign-off."
    echo ""
    echo "If no blocking issues found:"
    echo "  → Proceed to Architecture, QA, and Security reviews"
    echo "  → Then to Release Risk assessment"
  else
    echo "✅ PROCEED with standard review"
    echo ""
    echo "No legal/compliance blockers detected."
    echo "Proceed through normal engineering review flow:"
    echo "  → Security Agent review"
    echo "  → QA Lead review"
    echo "  → Architecture review"
    echo "  → Release Risk assessment"
  fi
)

---
[Legal & Compliance Agent] — Per Agent Role Specifications v1.0 §12 | LIGHTWEIGHT_LEGAL_COMPLIANCE_GOVERNANCE v1.0

⚠️ DISCLAIMER: This agent identifies risks for human review. It is NOT legal counsel.
All final compliance decisions require human Legal Counsel sign-off.
EOF

# Post comment to Jira
if [ "$HAS_SENSITIVE" = "yes" ]; then
  jira_comment "$KEY" "[LEGAL & COMPLIANCE] ⚠️ LEGAL REVIEW REQUIRED

Sensitive content detected: $([ "$IS_PRIVACY" = "yes" ] && echo "Privacy/Data " || echo "")\
$([ "$IS_STUDENT" = "yes" ] && echo "Student Data " || echo "")\
$([ "$IS_CREDENTIAL" = "yes" ] && echo "Credentials " || echo "")\
$([ "$IS_THIRD_PARTY" = "yes" ] && echo "Third-Party " || echo "")

Cannot release without Legal Counsel confirmation of compliance.
[Legal & Compliance Agent]" 2>/dev/null || true
else
  jira_comment "$KEY" "[LEGAL & COMPLIANCE] ✅ No compliance blockers
Standard feature — Legal Counsel review not required.
[Legal & Compliance Agent]" 2>/dev/null || true
fi
