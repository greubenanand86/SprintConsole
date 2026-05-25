#!/usr/bin/env bash
# Legal & Compliance Agent — Lightweight risk identification (NOT AI attorney)
# Jira Workflow Governance §4 | Lightweight Legal & Compliance Governance v1.0
# Reviews for: data privacy, accessibility, student data, credential exposure,
# third-party SDK risks, consent flows, policy alignment
# Identifies risks and escalates to human counsel; does NOT provide legal sign-off
# May block release if critical checks missing (consent, privacy review, accessibility)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+issuetype=Story+AND+status+in+(%22In+Review%22,%22Ready+for+QA%22,%22QA+In+Progress%22)&maxResults=10&fields=summary,description")
COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Sensitive areas that trigger legal/compliance review (per governance §2)
SENSITIVE_PATTERN="privacy|personal data|pii|gdpr|ccpa|ferpa|ppra|student data|learner|consent|cookie|tracking|analytics|payment|billing|credential|password|oauth|third.party|sdk|integration|accessibility|wcag|ada|survey|anonymous"

echo "Legal & Compliance Agent: Scanning $COUNT in-review stories"

echo "$STORIES" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r KEY SUMMARY; do

  COMMENTS=$(jira_get "issue/$KEY/comments?maxResults=50")
  HAS_LEGAL=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[LEGAL & COMPLIANCE\]' || true)
  [ "$HAS_LEGAL" -gt 0 ] && continue

  SUMMARY_LOWER=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]')
  IS_SENSITIVE=$(echo "$SUMMARY_LOWER" | grep -cE "$SENSITIVE_PATTERN" || true)

  LEGAL_CHECK=$(claude --print \
"Role: You are the Legal & Compliance Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Identify legal and compliance risks for this story. Flag issues for human legal review. Do NOT provide legal interpretation or final sign-off (human counsel required).

Inputs:
- Story: $SUMMARY
- Source files readable via Read and Glob tools
- Note: You are a risk-identification layer, not an AI attorney

Lightweight Legal & Compliance Governance v1.0 risk checklist:

Data Privacy (GDPR/CCPA/PIPEDA):
1. New personal data collection — documented and impact assessed?
2. Privacy notice updated (or no new collection)?
3. Privacy policy aligns with proposed data uses?
4. Consent flow designed (if required by law)?
5. Right to access implemented?
6. Right to deletion / erasure implemented (if GDPR/CCPA)?
7. Data retention policy defined?
8. Cross-border data transfer implications reviewed?
9. Third-party data processor agreements in place?

Accessibility (WCAG 2.1 AA, ADA, Section 508):
10. New UI — accessibility review completed?
11. Color contrast meets WCAG AA (4.5:1)?
12. Alt text for images?
13. Keyboard navigation functional?
14. Screen reader compatible?

Student/Learner Data (FERPA, PPRA):
15. Student data handling — legal implications reviewed?
16. FERPA confidentiality requirements met?
17. PPRA parental notification in place (if surveys)?
18. Third-party access to student data — agreement in place?

Credential & Authentication Data:
19. No plaintext passwords in logs/backups/errors?
20. No API keys embedded in frontend/mobile?
21. Session tokens encrypted and short-lived?

Third-Party SDK / Integration:
22. New SDK — privacy impact assessed?
23. New SDK — security posture verified?
24. Vendor agreement / DPA in place (if GDPR)?
25. Data flow through SDK documented?

Terms of Service / Privacy Policy Alignment:
26. Feature aligns with published ToS?
27. Data use aligns with privacy policy?

Output format — output EXACTLY these sections:

RISK_LEVEL: <GREEN — no legal/compliance issues|YELLOW — medium risk, recommend review|RED — high risk, blocks release>

RISK_SUMMARY:
- <risk 1, or 'None identified'>
- <risk 2>

BLOCKING_ISSUES:
- <issue that blocks release, or 'None'>

HUMAN_REVIEW_REQUIRED: <YES — flag for legal counsel|NO — low risk>

REQUIRED_ACTIONS:
- <action needed, or 'None'>

COUNSEL_ESCALATION: <YES — legal hold, blocks release|NO — proceed with caution>

GOVERNANCE_NOTES:
- <relevant governance note from Lightweight Legal & Compliance v1.0>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX" \
    --allowedTools "Read,Glob" \
    --no-conversation 2>/dev/null)

  RISK_LEVEL=$(echo "$LEGAL_CHECK" | grep '^RISK_LEVEL:' | sed 's/^RISK_LEVEL: //')
  BLOCKING=$(echo "$LEGAL_CHECK" | grep '^BLOCKING_ISSUES:' -A 1 | tail -1 | grep -v '^--$' | grep -v 'None' | wc -l | tr -d ' ')
  HUMAN_REVIEW=$(echo "$LEGAL_CHECK" | grep '^HUMAN_REVIEW_REQUIRED:' | grep -i 'YES' | wc -l | tr -d ' ')
  COUNSEL_ESCALATION=$(echo "$LEGAL_CHECK" | grep '^COUNSEL_ESCALATION:' | grep -i 'YES' | wc -l | tr -d ' ')
  extract_standard "$LEGAL_CHECK"

  case "$RISK_LEVEL" in
    GREEN)  RISK_ICON="✅" ;;
    YELLOW) RISK_ICON="⚠️" ;;
    RED)    RISK_ICON="🚫" ;;
    *)      RISK_ICON="❓" ; RISK_LEVEL="UNKNOWN" ;;
  esac

  COMMENT="[LEGAL & COMPLIANCE] $RISK_ICON Risk Level: $RISK_LEVEL

Risk Summary:
$(echo "$LEGAL_CHECK" | sed -n '/^RISK_SUMMARY:/,/^BLOCKING_ISSUES:/p' | grep '^-' | sed 's/^- /• /')

Human Review Required: $(echo "$LEGAL_CHECK" | grep '^HUMAN_REVIEW_REQUIRED:' | sed 's/^HUMAN_REVIEW_REQUIRED: //')

$([ "$BLOCKING" -gt 0 ] && echo "
Blocking Issues (prevent release):
$(echo "$LEGAL_CHECK" | sed -n '/^BLOCKING_ISSUES:/,/^HUMAN_REVIEW_REQUIRED:/p' | grep '^-' | sed 's/^- /🚫 /')")

Required Actions:
$(echo "$LEGAL_CHECK" | sed -n '/^REQUIRED_ACTIONS:/,/^COUNSEL_ESCALATION:/p' | grep '^-' | sed 's/^- /→ /')

$([ "$COUNSEL_ESCALATION" -gt 0 ] && echo "
⚠ LEGAL HOLD — Escalation to human legal counsel required.
Per Lightweight Legal & Compliance Governance §9, high-risk items require counsel review before release.")

$([ "$HUMAN_REVIEW" -gt 0 ] && [ "$BLOCKING" -eq 0 ] && echo "
⚡ RECOMMENDATION: Flag for legal review before production deployment.
This does NOT block release, but legal counsel should review.")

Governance Note: Agent is risk-identification layer, NOT AI attorney.
Flag issues for human counsel; agent does NOT provide legal sign-off.
Per Lightweight Legal & Compliance Governance §11: trust, but verify with human counsel.

$(standard_fields_block)"

  jira_comment "$KEY" "$COMMENT"

  # Escalate to TPM if counsel escalation needed
  if [ "$COUNSEL_ESCALATION" -gt 0 ]; then
    escalate_to_tpm "$KEY" \
      "Legal hold — counsel review required before release. Lightweight Legal & Compliance Governance §9." \
      "LEGAL & COMPLIANCE"
  fi

  echo "Legal & Compliance Agent: $RISK_ICON $KEY — Level=$RISK_LEVEL Counsel=$([ "$COUNSEL_ESCALATION" -gt 0 ] && echo 'REQUIRED' || echo 'N/A')"

done

echo "Legal & Compliance Agent: Risk assessment complete"
exit 0
