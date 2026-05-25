# Governance Clarifications v1.0
## Resolving Critical Ambiguities for Agent Formalization

**Date:** 2026-05-25  
**Scope:** Production deployment approval chain, Deploy Agent authority, TPM authority, Security timing, Product Memory storage, Mobile release integration  
**Authority:** Derived from Release Management Playbook v1.0, Agent Role Specifications v1.0, Incident Management Playbook v1.0, Product Memory System v1.0

---

## I. Production Deployment Approval Chain

### Operational Flow

```
Story in "Ready for Release" status
  ↓
[Release Risk Agent performs assessment]
  ├─ Green: "proceed to production"
  ├─ Yellow: "require staged rollout (e.g., 25% → 50% → 100%)"
  └─ Red: "block; escalate to TPM"
  ↓
[TPM Agent reviews Release Risk verdict]
  ├─ Agrees with Green → forwards to Deploy Agent
  ├─ Agrees with Yellow → forwards with staged rollout gate to Deploy Agent
  ├─ Disagrees with Red → escalates to Human; awaits decision
  └─ Detects blocker (unresolved dependency, governance violation) → escalates to Human
  ↓
[Deploy Agent receives approval]
  ├─ Validates pre-release checklist (see below)
  ├─ Initiates staging deployment
  ├─ Waits for Monitoring Agent to validate Staging ↔ Production parity
  └─ If parity confirmed → transitions story to "Released" → deploys to production
  ↓
[Human approval (async, optional gate)]
  ├─ IF Deploy Agent requires explicit human sign-off (e.g., high-risk feature, compliance-sensitive)
  │   └─ Human reviews story + Release Risk summary + Deploy checklist → approves/blocks
  └─ IF standard release → human approval assumed (TPM approval sufficient)
  ↓
[Monitoring Agent takes ownership]
  ├─ Monitors: crashes, API failures, auth issues, performance, analytics
  ├─ Duration: 24–48 hours post-release (configurable per feature)
  ├─ If issue detected → escalates to Incident Agent
  └─ If clean → transitions to "Stable" → then "Done"
```

### Pre-Release Checklist (Deploy Agent Validation)

Before production deployment, Deploy Agent **must** verify:

1. ✅ **QA Passed** — QA Agent marked story as tested; no blockers
2. ✅ **Product Acceptance Complete** — Product Acceptance Agent approved feature
3. ✅ **Release Risk Review Done** — Release Risk Agent assessed as Green/Yellow/Red
4. ✅ **Rollback Available & Validated** — Rollback procedure documented and dry-run confirmed
5. ✅ **Release Notes Prepared** — Customer-facing release notes ready
6. ✅ **Analytics Events Firing** — Feature analytics instrumented and validated (if applicable)
7. ✅ **Monitoring Enabled** — Crash reporting, error tracking, performance monitoring active
8. ✅ **Security Sign-Off** — Security Agent reviewed code/auth/data access (if security-sensitive per Security Baseline §12)
9. ✅ **Compliance Review** — Legal & Compliance Agent flagged no blocking risks (if applicable)
10. ✅ **Environment Parity Confirmed** — Staging configuration mirrors Production (validated by Deploy Agent)

**If ANY checklist item fails:** Story transitions back to "Ready for Release" with blocker comment; Deploy Agent awaits fix.

---

## II. Deploy Agent Authority Boundaries

### What Deploy Agent May Do

✅ **Authorized Actions:**
1. Deploy to staging (Development + Staging environments)
2. Validate staging deployment (logs, errors, connectivity)
3. Validate staging ↔ production parity (config, secrets isolation, monitoring)
4. Execute rollback to previous staging deployment
5. Coordinate with Monitoring Agent for production readiness
6. Gate production deployment pending checklist completion (blocking gate)
7. Create and validate feature flags for staged rollout (if applicable)
8. Execute staged rollout (25% → 50% → 100%) per Release Risk Agent recommendation

❌ **NOT Authorized:**
1. **Deploy directly to production without approval chain** (approval = TPM + checklist validation)
2. Deploy to production without Monitoring Agent staging validation
3. Skip the pre-release checklist
4. Override Release Risk Agent's Red verdict
5. Override Security Agent's blocking concerns
6. Bypass rollback validation (dry-run required)
7. Deploy without release notes
8. Make autonomous decisions on staged rollout % or timing (must follow Release Risk Agent recommendation)

### Production Deployment Gate

**Explicit gate:** Deploy Agent may deploy to production **only when**:
1. Story status = "Ready for Release"
2. Release Risk verdict ≠ Red (or Red resolved + TPM approved override)
3. Pre-release checklist 100% complete
4. TPM Agent explicitly confirmed (via comment: `[TPM APPROVAL] Proceed to production`)
5. Monitoring Agent confirmed Staging ↔ Production parity
6. Human approval obtained (if high-risk or compliance-sensitive; otherwise TPM approval sufficient)

**If gate conditions fail:** Deploy Agent transitions story back to "Ready for Release" with blocker reason; awaits resolution.

---

## III. TPM Agent Authority Boundaries

### What TPM Agent May Do

✅ **Authorized Actions:**
1. Receive escalations from any agent (governance violations, blockers, conflicts)
2. Review Release Risk verdicts and approve/override with justification
3. Approve production deployment (via explicit `[TPM APPROVAL]` comment)
4. Escalate to human when TPM cannot resolve (e.g., conflicting agent verdicts, strategic questions)
5. Recommend release delay (if blocker unresolvable by target date)
6. Coordinate cross-agent resolution (e.g., if Architect and Security disagree, TPM arbitrates per Decision Hierarchy)
7. Request architecture, security, or compliance review
8. Track metrics (velocity, predictability, incident frequency) and report to human
9. Manage sprint rhythm and sprint goals
10. Identify and escalate governance violations (agent overreach, skipped gates)

❌ **NOT Authorized:**
1. **Override governance rules** (e.g., "deploy anyway despite QA blockers")
2. Override Security Agent's blocking concerns without human approval
3. Override Architecture Agent's rejection of unsafe design without human approval
4. Deploy to production directly (only Deploy Agent may deploy; TPM approves)
5. Make final product decisions (roadmap, scope, deprecations — Product Manager decides)
6. Make final technical decisions (architecture, API design — Architect decides)
7. Skip required agents' reviews (e.g., "ship without Security review")

### TPM Decision Hierarchy

When agents conflict, TPM arbitrates using Decision Hierarchy (Architecture Blueprint §15):

1. **Security** > Stability > Maintainability > Scalability > Developer productivity > Performance > Sophistication

**Example conflicts & TPM resolution:**
- Architect wants feature A, Security says "A is unsafe" → **Security wins** (TPM blocks feature A)
- QA says "not ready," Product says "ship it" → **QA wins** (TPM blocks release)
- Release Risk says Yellow (staged), Deploy says "deploy 100%" → **Release Risk wins** (TPM enforces staged rollout)

---

## IV. Security Review Timing & Authority

### Security Review Gates (Two-Stage)

**Stage 1: Design-Time Review (with Architect Agent)**
- **When:** Story in "Ready for Refinement" → "Refined"
- **What:** Architect Agent presents technical design (API, auth, data access, integrations)
- **Security checks:** Auth strategy safe? Data access controls adequate? Integrations vetted? Dependencies known?
- **Authority:** Security Agent may recommend design changes; if blocker, escalates to TPM
- **Outcome:** Approved design proceeds to development; concerns filed as tech debt or design change

**Stage 2: Code-Time Review (during code review)**
- **When:** Story in "Code Review" status
- **What:** Security Agent reviews actual implementation (code, config, logging, error handling)
- **Security checks:** No hardcoded secrets? Input validation present? Auth validation enforced? Parameterized queries? Safe error messages?
- **Authority:** Security Agent may block code review; require remediation before merge
- **Outcome:** Approved code merges; concerns block merge until fixed

**Stage 3: Pre-Release Review (right before production deployment)**
- **When:** Story in "Ready for Release" status; Deploy Agent performing checklist
- **What:** Security Agent confirms no new vulnerabilities, secrets, or auth issues introduced
- **Authority:** Security Agent may block production deployment (forces return to "Ready for Release")
- **Outcome:** Approved → production deployment proceeds

### Security Agent Authority

✅ **May:**
1. Request design changes during design review (Architect must respond; if blocked, escalates)
2. Block code review pending remediation
3. Block production deployment if new vulnerabilities or auth concerns detected
4. Escalate to TPM if Architect disagrees (TPM arbitrates per Decision Hierarchy)
5. Escalate to human if blocking is unresolvable (e.g., "design is fundamentally unsafe")

❌ **May NOT:**
1. Deploy code without code review approval
2. Override QA verdict ("it's not safe to test yet")
3. Bypass Architect Agent's design approval (Security reviews design *after* Architect approves)
4. Unilaterally change code (Security only blocks; developers fix)

---

## V. Product Memory Storage Rules

### What Gets Stored (Durable Knowledge)

**Store these (high confidence, reusable):**
- Architecture decisions (API design, state management, scaling decisions)
- Product decisions (feature scope, roadmap rationale, rejected alternatives)
- UX decisions (navigation patterns, accessibility considerations, mobile-specific UX)
- Technical debt (compromises, repayment cost, roadmap)
- Release learnings (rollback decisions, monitoring gaps, automation wins)
- Incident postmortems (root cause, prevention steps, organizational learning)
- Customer context (contract constraints, integration requirements)
- Governance decisions (why we chose this standard, alternatives rejected)

**Do NOT store (low confidence, temporary):**
- Brainstorming conversations (store only the *decision*, not the debate)
- Daily standup updates (use Jira comments for operational coordination)
- Individual opinions unrelated to decisions
- Low-confidence assumptions ("probably safe" — wait for validation)
- Transient bugs ("found this issue on my machine" — use Jira bug)

### Storage Triggers

**Real-Time Storage (during development):**
- Architecture decisions (as soon as Architect Agent approves, store decision + rationale)
- Security decisions (as soon as Security Agent flags a risk or approves a trade-off)
- UX decisions (as soon as UX Agent finalizes a pattern)
- Governance violations detected (store what happened + resolution)

**Post-Release Storage (after feature ships):**
- Release learnings (what went well? what surprised us?)
- Rollback decisions (why did we rollback? what should change?)
- Monitoring gaps (what monitoring did we lack?)
- Incident postmortems (root cause + prevention steps)

**Quarterly Storage (review cycle):**
- Mark superseded decisions as stale
- Identify emerging patterns (should this become a standard?)
- Update roadmap-related decisions

### Who Decides Storage?

- **Product Memory Agent** owns storage execution
- **Any agent** may flag "this should be stored"
- **Product Memory Agent** uses threshold above to assess "is this durable knowledge?"
- If in doubt, **store it** (quarterly review will trim; better over-store than lose context)

### Storage Format

All entries include:
- **Decision/Learning:** What was decided or learned
- **Rationale:** Why (context, alternatives, trade-offs)
- **Owner:** Who owns follow-up
- **Date:** When recorded
- **Governance refs:** Which standards govern this decision
- **Review cycle:** When to revisit (e.g., "end of H1 2026")

---

## VI. Mobile Release Integration into Main Lifecycle

### Mobile Release Lifecycle (Integrated)

Mobile features follow the same release workflow as web features, with **mobile-specific gates**:

```
Story Ready for Development
  ↓
[Development Phase]
  ├─ Web team: React implementation
  └─ Mobile team: React Native implementation (parallel, shared validation logic via /packages/validation)
  ↓
[Code Review Phase]
  ├─ Web code review (Architect + Security)
  └─ Mobile code review (Architect + Security + mobile-specific checks: Keychain/Keystore auth, HTTPS/TLS, certificate pinning, safe deep linking)
  ↓
[QA Phase]
  ├─ Web QA (regression, E2E, accessibility)
  ├─ Mobile QA (device matrix, iOS + Android, mobile-specific flows, crash testing)
  └─ [Mobile-only gate]: Crash-free beta validation required
  ↓
[Product Acceptance]
  ├─ Product acceptance (feature acceptance, feature flag validation if applicable)
  └─ Mobile acceptance (mobile UX, app store metadata review)
  ↓
[Ready for Release Phase]
  ├─ Release Risk assessment (includes mobile-specific risk: app store submission, beta availability)
  └─ [Mobile-only gate]: TestFlight beta stable; internal testing passed
  ↓
[Production Release Phase]
  ├─ Web: Full deployment or staged rollout (per Release Risk verdict)
  ├─ Mobile: Staged rollout (typically 25% → 50% → 100% over 3–7 days)
  │  └─ Cannot skip stages; must validate crash-free metrics between stages
  └─ [Coordination]: Web and mobile deploy in parallel OR sequentially (per Release Risk Agent recommendation)
     └─ If coordinated: Deploy Agent gates both web + mobile to go live simultaneously
     └─ If sequential: Web deploys first; mobile follows after web validation
  ↓
[App Store Submission (Mobile-Only)]
  ├─ TestFlight → Internal Testing → Staged Release → Full Release
  ├─ Metadata review (screenshots, description, keywords)
  └─ [Monitoring]: Crash-free sessions 99%+; reject staged increase if <99%
  ↓
[Monitoring Phase]
  ├─ Web: 24–48 hour monitoring window (crashes, API errors, performance)
  └─ Mobile: 5–7 day monitoring window (crashes, beta feedback, staged rollout health)
  ↓
[Done]
  └─ Release notes published; postmortem if issues found
```

### Mobile-Specific Gates (Release Risk Agent Assessment)

Release Risk Agent must assess mobile-specific factors:

1. ✅ **iOS TestFlight Beta Stable** — no crashes, no "version incompatible" errors
2. ✅ **Android Internal Testing Passed** — all devices, minimum OS version, crash-free
3. ✅ **App Store Metadata Ready** — screenshots, description, keywords approved
4. ✅ **Keychain/Keystore Auth** — tokens stored securely, not in preferences
5. ✅ **HTTPS/TLS 1.2+** — all network calls encrypted; certificate pinning if required
6. ✅ **Deep Linking Safe** — no arbitrary deep link execution; validation enforced
7. ✅ **Minimal Permissions** — no over-requesting (camera, location, etc.)
8. ✅ **Staged Rollout Plan** — 25% → 50% → 100% timeline, with rollback ready
9. ✅ **Crash-Free Metrics Baseline** — current crash rate <1%; target post-release <0.5%

If any mobile-specific gate fails: Release Risk verdict = **Red (block)** pending resolution.

### Deploy Agent Mobile Execution

**Mobile deployment authority:**
- Deploy Agent may deploy to TestFlight (staging for iOS)
- Deploy Agent may deploy to internal testing track (staging for Android)
- Deploy Agent may initiate App Store staged release (25% → 50% → 100%)
- Deploy Agent may NOT skip stages or deploy 100% without Release Risk approval

**Mobile-specific checklist items:**
- TestFlight stable for 24+ hours
- Internal testing passed on all supported devices
- Crash-free sessions >99% in TestFlight
- App Store metadata approved
- Staged rollout plan confirmed
- Rollback procedure ready (revert to previous version in App Store)

### Mobile–Web Coordination Decision

**Release Risk Agent decides:** Parallel or sequential deployment?

- **Parallel:** Both web and mobile deploy simultaneously
  - Requires: Both teams ready, both release gates pass
  - Risk: Coordinated rollback if issue affects both
  - Win: Single release communication, coordinated feature launch

- **Sequential:** Web deploys first; mobile follows after web validation
  - Requires: Web stable 24 hours; mobile deploys next sprint or immediately after
  - Risk: Feature works differently web vs. mobile (user confusion)
  - Win: Isolated rollback if mobile issue (web unaffected)

**Default:** Sequential (mobile 24–48 hours after web validation), unless Release Risk Agent recommends parallel.

---

## VII. Governance Reference

All clarifications above derive from:
- **Release Management Playbook v1.0** (§3 readiness, §7 rollback, §8 monitoring, §9 hotfix)
- **Environment Governance v1.0** (§4–6 deployment flow, parity, access control)
- **Agent Role Specifications v1.0** (§1 TPM, §10–11 Deploy, §13 Security)
- **Incident Management Playbook v1.0** (§3 workflow, §4 ownership, §5 rollback, §6 postmortem)
- **Product Memory System v1.0** (§3 memory rules, §6 retrieval rule)
- **Architecture Blueprint v1.0** (§15 decision hierarchy)
- **Security Baseline v1.0** (§11–12 security reviews, §4 auth, §5 API security)

---

## VIII. Final Principle

**Approvals should be fast, clear, and traceable.**

- Fast: Deploy Agent doesn't wait for approval; TPM approval is async; Deploy Agent starts checklist while Release Risk assesses
- Clear: Every agent knows their authority boundary; checklists are objective (pass/fail, not subjective)
- Traceable: Every approval comment is tagged `[AGENT NAME]` and timestamped; Product Memory records why

---

## IX. Remaining Ambiguities Needing Human Decision

**These require human input before agent formalization; cannot be resolved by governance alone:**

1. **Staged rollout defaults:** What % progression (25%→50%→100% vs. 10%→50%→100%)? How long between stages (hours vs. days)?
2. **Monitoring window duration:** 24 hours (fast shipping) or 48 hours (high confidence)? Configurable per feature?
3. **Mobile pre-release timeline:** Deploy mobile same day as web? Next day? Different sprint?
4. **Cost threshold for FinOps escalation:** At what estimated/actual cost does FinOps escalate? ($100? $1000?)
5. **Human approval for standard releases:** Always required, or only high-risk? Define "high-risk" explicitly.
6. **Rollback dry-run scope:** All releases, or only production mobile/infrastructure? Test in staging or production?
7. **Security escalation to human:** At what severity does Security escalate (all blocks, or only if TPM override requested)?

These should be decided with stakeholders before formalizing Deploy Agent and Release Risk Agent prompts.
