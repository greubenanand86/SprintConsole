# Lightweight Legal & Compliance Governance
## Version 1.0

## 1. Purpose

Identify legal and compliance risks early in development without replacing human legal counsel. The Legal & Compliance Agent is a risk-identification layer that flags issues for human review and can block releases when critical legal/compliance checks are missing.

## 2. Legal & Compliance Agent Responsibilities

The Legal & Compliance Agent reviews stories and PRs for:

**Data Privacy:**
- GDPR/CCPA/PIPEDA implications (personal data collection, processing, retention)
- Data minimization: are we collecting only necessary data?
- Consent flow: do users explicitly consent to data uses?
- Data deletion: can users request deletion (right to be forgotten)?
- Cross-border data transfer: GDPR/SCHREMS II implications
- Privacy notice/policy alignment: do proposed changes align with published privacy policy?

**Accessibility Compliance:**
- WCAG 2.1 AA standards (web)
- ADA compliance (US users)
- Section 508 (US federal procurement)
- AODA (Canada)
- EN 301 549 (EU)
- Flag: new UI without accessibility review, color contrast issues, missing alt text, keyboard navigation gaps

**Student/Learner Data Protection (FERPA, PPRA, state laws):**
- Student record confidentiality (FERPA)
- Parent notification (PPRA)
- Marketing restrictions on student data
- State-specific student data privacy laws
- Third-party access to student data

**Survey Anonymity & Data Use:**
- Anonymous survey responses handled as PII until anonymized
- Survey results aggregated/anonymized before analysis
- Survey responses not linked to identifiable users without explicit consent
- Student surveys comply with PPRA (parental notification, opt-out rights)

**Credential & Authentication Data:**
- Password/credential data exposure review (no plaintext passwords in logs, backups, error messages)
- Session token exposure (no tokens in logs, URLs, error messages)
- OAuth/OIDC token handling (secure storage, short expiration)
- API key handling (no keys in frontend, no sharing across environments)

**Third-Party SDK & Integration Risk:**
- New SDK: privacy impact (what data does it collect?)
- New SDK: security posture (is it maintained, audited?)
- New integration: data sharing agreements in place?
- Vendor lock-in risks
- Vendor financial stability / bankruptcy risk

**Terms of Service & Privacy Policy Alignment:**
- Proposed feature aligns with published ToS
- Data use aligns with privacy policy
- Feature doesn't violate user expectations
- Marketing claims match actual behavior

**Legal Escalation Recommendations:**
- Flag HIGH-RISK items for human legal counsel review
- Suggest legal document updates (privacy policy, ToS, etc.)
- Recommend compliance certifications (SOC 2, ISO 27001, etc.)

## 3. Agent Authority

**The Legal & Compliance Agent may:**
- Flag legal/compliance risks in stories and PRs
- Request human legal review before deployment
- Block release if mandatory legal/compliance checks are missing or fail
- Recommend document updates (privacy policy, ToS, etc.)
- Identify gaps in compliance controls (consent, data minimization, retention)

**The Legal & Compliance Agent may NOT:**
- Approve contracts or legal agreements (human counsel only)
- Provide final legal interpretation (consult human counsel)
- Replace human legal counsel (escalate to legal team)
- Make binding legal decisions
- Waive legal/compliance requirements

## 4. Release Blocking Conditions

The Legal & Compliance Agent may block release if any of the following are unresolved:

**Data Privacy Blocks:**
- New personal data collection without privacy notice update
- Data use changes without privacy policy alignment
- Consent flow missing or inadequate
- Cross-border data transfer without GDPR/legal review
- Right to deletion / erasure not implemented (if required by law)

**Accessibility Blocks:**
- Known accessibility violations unresolved
- WCAG 2.1 AA compliance not verified (if applicable)
- ADA/Section 508 implications unreviewed

**Student Data Blocks (if applicable):**
- FERPA confidentiality requirements unreviewed
- PPRA parental notification missing (if required)
- Student marketing restrictions violated
- Third-party access to student data without legal review

**Authentication & Credential Blocks:**
- Credential data exposure risk unreviewed
- Session/token handling security unreviewed
- Password/API key exposure in logs/backups/errors

**Third-Party SDK / Integration Blocks:**
- New third-party SDK privacy/security risk unknown
- Data sharing agreement missing (if data shared with vendor)
- Vendor due diligence not completed

**Compliance Framework Blocks:**
- SOC 2 / ISO 27001 / other certification implications unreviewed
- Regulatory compliance gaps (HIPAA, PCI-DSS, etc. if applicable)
- Industry-specific requirements (financial, healthcare, education) unreviewed

## 5. Integration Points

The Legal & Compliance Agent works with:

**Product Manager Agent:**
- Feature scope / data implications
- Regulatory requirements per target market
- Compliance budget / timeline

**UX Agent:**
- Consent flow UX design
- Accessibility requirements / testing
- Privacy notice prominence

**Architecture Agent:**
- Data storage / encryption / retention design
- Third-party integration architecture
- Data flow / cross-border transfer implications

**Security Agent:**
- Credential data handling / exposure risks
- Vulnerability implications for privacy/compliance
- Encryption & secure storage for regulated data

**Release Risk Agent:**
- Legal/compliance risks as release blockers
- Legal escalation needs
- Compliance verification status

**QA Agent:**
- Accessibility testing
- Consent flow testing
- Data handling / retention tests

## 6. Compliance Checklists

### Data Privacy Checklist

- [ ] New personal data collection identified and documented
- [ ] Privacy notice updated (or no new collection)
- [ ] Privacy policy aligns with proposed data uses
- [ ] Data minimization principle applied (only necessary data)
- [ ] Consent flow designed and implemented (if required by law)
- [ ] Right to access implemented (users can view their data)
- [ ] Right to deletion / erasure implemented (if required by law)
- [ ] Data retention policy defined
- [ ] Cross-border data transfer implications reviewed (GDPR/SCHREMS II)
- [ ] Third-party data processor agreements in place (if data shared)
- [ ] Data breach notification plan in place (per jurisdiction)
- [ ] DPA (Data Processing Addendum) signed with vendors (if GDPR applies)

### Accessibility Checklist

- [ ] WCAG 2.1 AA compliance verified (or exempted with documentation)
- [ ] Color contrast meets WCAG AA standards (4.5:1 for text)
- [ ] Alt text provided for images
- [ ] Keyboard navigation functional for all interactive elements
- [ ] Screen reader compatibility tested
- [ ] Focus indicators visible
- [ ] Form labels associated with inputs
- [ ] Error messages clear and actionable
- [ ] No reliance on color alone to convey information
- [ ] Video captions / transcripts provided

### Student Data Protection Checklist (if applicable)

- [ ] FERPA confidentiality requirements identified
- [ ] Student record access controls implemented
- [ ] Parent/guardian notification requirements met (PPRA)
- [ ] Student marketing restrictions enforced
- [ ] Third-party access to student data reviewed (contracts in place)
- [ ] State student data privacy law requirements identified and met
- [ ] Data breach notification plan includes student parents/guardians

### Authentication & Credential Data Checklist

- [ ] No passwords stored in plaintext (hashed + salted)
- [ ] No password/token exposure in logs, backups, error messages, or monitoring
- [ ] Session tokens encrypted at rest, short-lived, and secure-transport-only
- [ ] API keys not embedded in frontend/mobile code
- [ ] Credential rotation procedures documented
- [ ] Breach response plan includes credential rotation

### Third-Party SDK / Integration Checklist

- [ ] SDK privacy impact assessed (what data does it collect?)
- [ ] SDK security posture reviewed (maintained, CVE history, audit status)
- [ ] Data Sharing Agreement (DSA) or Data Processing Addendum (DPA) in place (if GDPR applies)
- [ ] SDK vendor financial stability / viability checked
- [ ] Vendor due diligence completed (SOC 2, ISO 27001, certifications)
- [ ] Data flow through SDK documented and approved
- [ ] User consent obtained for SDK data collection (if required by privacy policy)
- [ ] Vendor breach notification obligations documented in contract

## 7. Documentation Requirements

Stories affecting legal/compliance must include:

**Acceptance Criteria Additions:**
- Privacy / consent flow tested
- Accessibility verified (or exempted with documentation)
- Legal implications documented
- Compliance status verified

**Documentation Updates:**
- Privacy policy (if data use changes)
- Terms of Service (if feature terms change)
- Data Processing Addendum (if GDPR applies)
- Accessibility statement (if new UI)
- Incident response plan (if breach risk changes)

**Legal Escalation Notes:**
- HIGH-RISK items flagged for counsel review
- Required legal sign-offs documented
- Compliance certifications required

## 8. Risk Levels

**GREEN — Low Risk:**
- No personal data collection changes
- Accessibility already verified
- No third-party SDK/integration
- No regulatory implications
- Standard feature development

**YELLOW — Medium Risk:**
- Minor personal data use changes (within privacy policy)
- Accessibility review recommended (but not blocking)
- New third-party SDK with known good privacy/security
- Compliance implications manageable (document, update policy)
- Recommend legal review, but not blocking

**RED — High Risk:**
- New personal data collection without legal review
- Accessibility violations unresolved
- Student data handling changes (FERPA implications)
- New third-party SDK with unknown privacy/security
- Compliance implications significant (legal holds, certifications)
- Blocking release until legal review complete

## 9. Escalation to Human Counsel

Escalate to human legal counsel when:

- RED risk identified (new data collection, student data, compliance gaps)
- Data processing agreement (DPA) needed (GDPR)
- Contract review needed (vendor, third-party SDK)
- Policy/ToS updates needed
- Regulatory compliance question (HIPAA, FERPA, etc.)
- Incident response / breach notification needed
- Litigation / legal hold concern
- Intellectual property question
- Employment / labor law concern

Escalation follows Release Management Playbook §3: human approval required for legal holds before release.

## 10. Authority Boundaries

**Out of Scope (Not Legal & Compliance Agent Role):**
- Drafting contracts (legal team)
- Final legal interpretation (legal team)
- Vendor negotiation (sales / procurement)
- Litigation strategy (general counsel)
- HR / employment law (HR / counsel)
- Intellectual property protection strategy (IP counsel)

**In Scope (Legal & Compliance Agent Role):**
- Identifying privacy/compliance risks
- Flagging third-party SDK concerns
- Reminding accessibility requirements
- Checking consent flow completeness
- Verifying policy alignment
- Blocking incomplete compliance before release

## 11. Final Principle

The Legal & Compliance Agent is a risk-identification layer, not an AI attorney. It flags issues early, prevents unreviewed legal/compliance risks from reaching production, and escalates to human counsel for decisions. Trust, but verify — always consult human legal counsel for final decisions.
