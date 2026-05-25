# Blocking Ambiguities for Human Decision
## Governance Gaps That Require Stakeholder Input

**Date:** 2026-05-25  
**Status:** Must be resolved before or during agent formalization / sprint execution  
**Type:** Strategic decisions, operational trade-offs, threshold definitions

---

## I. Production Deployment & Approval

### Ambiguity 1.1: Human Approval Authority & Process

**What's unclear:**
- Who is the "human approver"? (TPM? PM? Founder? Designated release manager?)
- How does human approval work operationally? (Jira comment? Slack button? in-person sign-off?)
- What must human verify before approving? (just checklist completion? or active review?)
- What happens if human is unavailable? (async approval? required-present approval? delegation?)

**Current governance:**
- Release Management Playbook §3: "Human Approval required"
- Agent Role Specs §10: "AI agents may NOT deploy to production without human approval"
- Governance Clarifications §I: Implicit flow, but no operational definition

**Decision needed:**
1. Name the human approver role (e.g., "Release Manager," "TPM," "Founder")
2. Define approval workflow (Jira comment `[APPROVED]`? Slack reaction? Both?)
3. Define approval checklist (checklist complete? or active review of code/design/risk?)
4. Define escalation if approver unavailable (who else can approve?)
5. Define audit trail (log all approvals, why, when)

**Impact:**
- If undefined: Deploy Agent waits indefinitely; releases block
- If too strict: Approval becomes bottleneck; slow shipping
- If too loose: Risk of unreviewed deployments

---

### Ambiguity 1.2: High-Risk Release Definition

**What's unclear:**
- What makes a release "high-risk"? (API change? database migration? security-sensitive? mobile feature?)
- Do all releases need human approval, or only high-risk?
- Who decides if a release is high-risk? (Release Risk Agent? Deploy Agent? TPM?)
- Can high-risk classification be overridden? (if so, by whom?)

**Current governance:**
- Governance Clarifications §I: "if high-risk or compliance-sensitive; otherwise TPM approval sufficient"
- No explicit definition of "high-risk"

**Decision needed:**
1. Define "high-risk" with explicit criteria:
   - API breaking changes? (always high-risk)
   - Database migrations? (always high-risk)
   - Mobile releases? (always high-risk)
   - Features touching auth/data-access? (always high-risk)
   - Security-sensitive changes? (always high-risk)
   - Regulatory/compliance changes? (always high-risk)
   - Everything else? (low-risk)

2. Define who classifies release as high-risk (Release Risk Agent? Or automated?)
3. Define if high-risk classification can be appealed or overridden (by whom?)

**Impact:**
- If too many things are "high-risk": All releases need human approval; bottleneck
- If too few: Risk of skipped human review on actually risky features

---

## II. Staged Rollout & Deployment Strategy

### Ambiguity 2.1: Default Staged Rollout Percentages & Timing

**What's unclear:**
- When Release Risk Agent recommends staged rollout (Yellow verdict), what should the default be?
  - 25% → 50% → 100%? (conservative, 3 stages)
  - 10% → 50% → 100%? (very conservative, 3 stages)
  - 50% → 100%? (moderate, 2 stages)
  - Other?
- How long between stages?
  - 6 hours? (fast iteration, deployed same day)
  - 24 hours? (careful validation, deployed over 2 days)
  - Configurable per feature?

**Current governance:**
- Governance Clarifications §VI: "typically 25% → 50% → 100% over 3–7 days" (mobile-specific; no web default)
- No fixed default for web features

**Decision needed:**
1. Define default staged rollout for web features
   - Default percentages
   - Default timing
   - Conditions where different strategy applied (e.g., critical fixes get 50% → 100%)

2. Define staged rollout for mobile features (currently 25% → 50% → 100%, but confirm timing)

3. Define who can override default (TPM? Release Risk Agent? Human?)

4. Define metrics to validate between stages (e.g., "crashes must stay <0.5% or rollback")

**Impact:**
- If percentages too conservative: Slow shipping (3 days to fully deploy)
- If percentages too aggressive: High risk of widespread impact if issue detected
- If timing unclear: Deploy Agent doesn't know when to advance stage

---

### Ambiguity 2.2: Feature Flags vs. Staged Rollout vs. Canary Deployment

**What's unclear:**
- Are feature flags an alternative to staged rollout, or complementary?
- When should we use feature flags (on/off toggle) vs. staged rollout (% deployment)?
- Does a feature that's feature-flagged still need staged rollout? (yes? no? depends?)

**Current governance:**
- Governance Clarifications §V: "Deploy Agent may create and validate feature flags for staged rollout"
- No clear distinction between feature flags and staged rollout

**Decision needed:**
1. Define when to use feature flags:
   - Always for risky features? (gate behind flag, then staged flag rollout)
   - Only for A/B testing? (not for risk mitigation)
   - Never (use staged rollout only)?

2. If feature flags are used, how does staged rollout interact?
   - Deploy 100% with flag off, then staged flag rollout? (e.g., flag on for 25% users)
   - Or deploy staged (25% users get code), then flag on for all users?
   - Both? (flag off → deploy 100% → flag on for 25% → flag on for 100%)

3. Who manages feature flags? (Deploy Agent? A separate flag-management agent?)

4. What's the flag lifecycle? (created pre-release, cleaned up when?)

**Impact:**
- If unclear: Inconsistent flag usage; some releases use flags, others don't
- If too complex: Dev team spends time on flag management vs. feature work

---

## III. Monitoring & Release Finality

### Ambiguity 3.1: Monitoring Window Duration

**What's unclear:**
- Is 24–48 hour monitoring window fixed, or configurable?
- If configurable, who decides? (Monitoring Agent? Release Risk Agent? TPM?)
- What criteria determine duration?
  - UI-only features: shorter?
  - Database-touching features: longer?
  - Mobile releases: longer?
  - Infrastructure changes: much longer?

**Current governance:**
- Governance Clarifications §I: "24–48 hours post-release (configurable per feature)"
- Doesn't specify default or decision criteria

**Decision needed:**
1. Set default monitoring duration (24h or 48h)
2. Define criteria for longer monitoring (database, infrastructure, sensitive data, etc.)
3. Define who decides duration (Release Risk Agent during assessment? or Monitoring Agent?)
4. Define what happens if issue is detected (after monitoring ends):
   - Can the issue wait for next sprint?
   - Must it be hotfixed?
   - Does it trigger postmortem anyway?

**Impact:**
- If duration too short: Subtle issues (low error rate, slow performance) might not be detected
- If duration too long: Releases slow down; time-to-customer increases

---

### Ambiguity 3.2: Definition of "Stable" State

**What's unclear:**
- What metrics/conditions must be met for a release to transition from "Monitoring" → "Stable"?
- Is it all metrics normal? Or some baseline?
- Does "stable" mean "ready to close ticket" or "ready for next release"?

**Current governance:**
- Monitoring Workflow: Released → Monitoring → Stable → Done
- No explicit "Stable" criteria

**Decision needed:**
1. Define "Stable" (measurable criteria):
   - Crash rate <X%?
   - Error rate <Y errors/1000 requests?
   - No high-severity incidents?
   - Metrics within X% of baseline?

2. Does "Stable" require active validation, or is it inferred from silence (no incidents)?

3. Can a release transition to "Stable" early (e.g., 12h if no issues) or is duration fixed?

**Impact:**
- If criteria too strict: Releases stay in Monitoring longer; delayed story closure
- If criteria too loose: Release marked Stable despite underlying issues

---

## IV. Security & Compliance

### Ambiguity 4.1: Security Review Escalation Threshold

**What's unclear:**
- When Security Agent blocks production deployment (security concern), does this always escalate to TPM/human?
- Or can Deploy Agent waive certain categories of security concerns?
- What types of concerns are non-negotiable? (auth? data-access? secrets? dependencies?)

**Current governance:**
- Security Baseline §12: "Mandatory Security Agent review before production"
- No explicit escalation rules if block occurs

**Decision needed:**
1. Define security concerns that always escalate (non-waivable):
   - Hardcoded secrets? (always escalate)
   - Auth bypass risk? (always escalate)
   - PII exposure? (always escalate)
   - Dependency vulnerability (High/Critical)? (always escalate)
   - Input validation gap? (always escalate? or sometimes waivable?)

2. Define concerns that may be accepted (with risk acknowledgment):
   - Dependency vulnerability (Low/Medium)? (maybe accept with monitoring)
   - Technical debt security issue? (maybe accept with repayment plan)

3. Define who accepts risk (TPM? Human? Must be explicit)

**Impact:**
- If too strict: All security blocks escalate; bottleneck
- If too loose: Security blocks don't get human attention; vulnerabilities ship

---

### Ambiguity 4.2: Compliance Review Scope

**What's unclear:**
- When does Legal & Compliance Agent participate? (all features? only data-sensitive? only regulatory-sensitive?)
- What's the default compliance checklist? (GDPR? CCPA? FERPA? All? None?)
- Who decides if compliance review is needed? (Legal Agent? PM? automatic trigger?)

**Current governance:**
- Legal & Compliance Governance v1.0: Defines risk categories (privacy, accessibility, student data, etc.)
- Governance Clarifications §I: Mentions "Compliance review (if applicable)" in checklist

**Decision needed:**
1. Define when compliance review is mandatory:
   - All stories? (adds review cycle to every release)
   - Only stories touching data? (user data, PII, student data, etc.)
   - Only stories with customer/legal implications?
   - Specific regulatory context (FERPA if education, HIPAA if health, etc.)?

2. Define default compliance checklist (what must be checked?)

3. Define who triggers compliance review (Legal Agent auto-checks? PM flags? Developer?

4. Define escalation if compliance concern found:
   - Always escalate to human? Or Legal Agent can clear?

**Impact:**
- If compliance review mandatory for all: Slow releases, time-consuming reviews
- If compliance review skipped: Risk of regulatory violation

---

## V. Mobile Release Coordination

### Ambiguity 5.1: Mobile-Web Release Timing

**What's unclear:**
- Should mobile and web releases be:
  - Simultaneous? (complex coordination, but single release story)
  - Sequential? (mobile 24–48h after web; simpler, but UX inconsistency risk)
  - Independent? (teams move at own pace; easy, but product fragmentation)

**Current governance:**
- Governance Clarifications §VI: "Parallel OR sequential (per Release Risk Agent recommendation)"
- No default strategy

**Decision needed:**
1. Define default release strategy (parallel vs. sequential)
2. If sequential, define timing (mobile immediately after? next day? next sprint?)
3. Define who decides (Release Risk Agent? TPM? PM?)
4. Define what happens if one platform has issue (does other platform rollback? or independent?)

**Impact:**
- If always parallel: Coordination overhead, but single feature launch story
- If always sequential: Simple process, but users see feature on one platform first

---

### Ambiguity 5.2: Mobile Beta Validation Requirements

**What's unclear:**
- How long must a feature be in TestFlight/beta before production release?
- What constitutes "stable beta"? (no crashes for 24h? some threshold?)
- Can we deploy to production if beta has <100% coverage (e.g., only tested on iPhone, not Android)?

**Current governance:**
- Release Management Playbook §6: "TestFlight validation, crash-free beta validation"
- Governance Clarifications §VI: "Crash-free sessions >99% in TestFlight"

**Decision needed:**
1. Define minimum beta duration (24h? 48h? configurable?)
2. Define minimum device coverage before production (all supported iOS versions? all Android versions?)
3. Define crash-free threshold (99%? 99.5%? 100%?)
4. Define beta user count requirement (internal only? beta group?)

**Impact:**
- If requirements too strict: Mobile releases very slow, high confidence
- If requirements too loose: Production crashes from untested device combinations

---

## VI. Cost & Infrastructure

### Ambiguity 6.1: FinOps Escalation Threshold

**What's unclear:**
- At what estimated/actual cost does FinOps Agent escalate?
- Is every story reviewed for cost, or only infrastructure/backend changes?
- Who decides budget? (FinOps Agent? TPM? Human?)

**Current governance:**
- Agent Role Specs §17: FinOps Agent owns "cloud cost analysis, AI token monitoring, infrastructure optimization"
- No escalation thresholds or cost budget

**Decision needed:**
1. Define cost escalation thresholds:
   - Estimated cost >$X per month? Escalate
   - Estimated tokens >Y per request? Escalate
   - Actual cost >Z% over estimate? Escalate

2. Define who reviews cost (all stories? infrastructure-only? backend-only?)

3. Define cost budget/constraints (unlimited? monthly cap? per-feature budget?)

4. Define escalation action (recommend optimization? block feature? require approval?)

**Impact:**
- If no cost review: Infrastructure costs may spiral (unused resources, inefficient queries)
- If cost review too strict: Delays features unnecessarily

---

## VII. Rollback & Incident Response

### Ambiguity 7.1: Rollback Dry-Run Requirement

**What's unclear:**
- Should all releases dry-run their rollback procedure before shipping?
- Or only high-risk releases (database changes, infrastructure changes)?
- If dry-run required, who validates? (Deploy Agent? Human? Release Risk Agent?)
- What constitutes a "successful" dry-run? (reverts to previous version? verified deployment?)

**Current governance:**
- Release Management Playbook §7: "Rollback procedure documented and dry-run confirmed"
- Governance Clarifications §I: "Rollback procedure documented and dry-run confirmed" in checklist

**Decision needed:**
1. Define when dry-run is mandatory (all releases? or high-risk only?)
2. Define dry-run scope (test in staging? test in production pre-release? mock only?)
3. Define success criteria (feature reverted? monitoring confirms old version? customer-facing validation?)
4. Define who validates dry-run (Deploy Agent? Release Risk Agent? Separate validation agent?)

**Impact:**
- If dry-run mandatory for all: Release cycle longer, but high confidence in rollback
- If dry-run skipped: Risk of broken rollback discovered during incident (high pressure situation)

---

### Ambiguity 7.2: Incident Severity Quantitative Thresholds

**What's unclear:**
- Current definitions of SEV-1 through SEV-4 are vague (e.g., "production outage" = 100% down or 50%+ down?)
- How quickly must different severities be escalated/resolved?

**Current governance:**
- Incident Management Playbook §2: SEV-1 "Production outage / major data risk", SEV-2 "Major feature degradation", etc.
- No quantitative thresholds

**Decision needed:**
1. Define SEV-1 quantitatively:
   - % of users affected? (e.g., >50%? >75%? 100%?)
   - Duration threshold? (immediate impact, or >5 min?)
   - Data impact? (any data loss = SEV-1?)

2. Define SEV-2, SEV-3, SEV-4 quantitatively:
   - SEV-2: X% degradation, Y% users affected
   - SEV-3: Partial degradation (specific %), non-critical feature
   - SEV-4: Cosmetic, one user, minimal impact

3. Define response time expectations:
   - SEV-1: Respond within X minutes? 30? 15?
   - SEV-2: Respond within Y minutes? 1h? 4h?
   - etc.

4. Define escalation paths per severity:
   - SEV-1: Incident Agent → TPM → Human immediately
   - SEV-2: Incident Agent → TPM (async)
   - etc.

**Impact:**
- If thresholds unclear: Severity classification inconsistent; escalation chaotic during incidents
- If thresholds too strict: False alarms (minor issues treated as SEV-1)

---

## VIII. Summary Table: Decisions Required

| Ambiguity | Impact | Blocker? | Needed By |
|-----------|--------|----------|-----------|
| Human approver role & process | Deployment bottleneck | YES | Before first production release |
| High-risk release definition | Approval bottleneck | YES | Before first production release |
| Staged rollout defaults (%, timing) | Release strategy unclear | HIGH | Before Release Risk Agent formalization |
| Feature flags vs. staged rollout | Inconsistent deployment strategy | MEDIUM | Before Deploy Agent formalization |
| Monitoring window duration | Release timing, risk tolerance | HIGH | Before Monitoring Agent formalization |
| Stable state criteria | Release finality unclear | MEDIUM | Before Monitoring Agent formalization |
| Security escalation threshold | Security bottleneck or risk | HIGH | Before Security Agent formalization |
| Compliance review scope | Review bottleneck or risk | MEDIUM | Before Legal Agent formalization |
| Mobile-web release timing | Coordination complexity | MEDIUM | Before mobile feature releases |
| Mobile beta validation | Mobile release safety | MEDIUM | Before mobile feature releases |
| FinOps escalation threshold | Cost control | LOW | Optional; can skip if cost unconstrained |
| Rollback dry-run requirement | Incident response safety | MEDIUM | Before first production incident |
| Incident severity thresholds | Incident response coordination | HIGH | Before any production incidents |

---

## IX. Recommended Decision Priority

**Must decide before starting sprints (Blocking):**
1. Human approver role & process (needed for first production deployment)
2. High-risk release definition (needed for approval clarity)
3. Incident severity quantitative thresholds (needed for incident response)

**Should decide before Tier 2 agent formalization (High):**
4. Staged rollout defaults
5. Feature flags strategy
6. Monitoring window duration
7. Security escalation threshold

**Can decide during observation phase (Medium):**
8. Stable state criteria
9. Compliance review scope
10. Mobile release timing
11. Mobile beta validation
12. Rollback dry-run requirement

**Optional; can skip or defer (Low):**
13. FinOps escalation threshold

---

## X. Decision Process

**For each ambiguity, stakeholders must decide:**

1. **What's the default?** (e.g., "default monitoring window is 48h")
2. **When can it vary?** (e.g., "can be 24h for UI-only features")
3. **Who decides variations?** (e.g., "Release Risk Agent decides per-feature")
4. **What's the fallback if decision-maker unavailable?** (e.g., "default 48h if Monitoring Agent unavailable")

**These decisions should be documented in a operational handbook for agents and humans.**
