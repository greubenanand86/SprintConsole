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
  ├─ Green: "ready for production (low risk)"
  ├─ Yellow: "ready for production with staged rollout (e.g., 25% → 50% → 100%)"
  └─ Red: "not ready; escalate to TPM"
  ↓
[TPM Agent reviews Release Risk verdict & recommends action]
  ├─ Recommends Proceed (Green agrees, no blockers)
  ├─ Recommends Proceed with Staged Rollout (Yellow agrees, no blockers)
  ├─ Recommends Delay (Red verdict or unresolved blockers; explains why)
  └─ Detects governance violation (missing AC, skipped gate) → recommends block + remediation
  ↓
[Deploy Agent executes checklist & prepares for deployment]
  ├─ Validates pre-release checklist (see below)
  ├─ If any item fails → returns story to "Ready for Release" with blocker; awaits fix
  ├─ If all items pass → initiates staging deployment
  ├─ Waits for Monitoring Agent to validate Staging ↔ Production parity
  └─ If parity confirmed → prepares for production (does not deploy autonomously)
  ↓
[HUMAN APPROVAL (Mandatory Gate)]
  ├─ Human reviews story + Release Risk verdict + TPM recommendation + Deploy checklist
  ├─ Human may:
  │  ├─ Approve → "Deploy to production" (Deploy Agent proceeds)
  │  ├─ Block → "Do not deploy" (returns to "Ready for Release"; must fix blocker)
  │  └─ Delay → "Wait, resubmit later" (removes from release queue)
  └─ This is the final production gate; cannot be overridden by agents
  ↓
[Deploy Agent executes production deployment (if human approved)]
  ├─ Deploys to production (standard or staged per Release Risk recommendation)
  ├─ Transitions story to "Released"
  └─ Notifies Monitoring Agent to begin post-release monitoring
  ↓
[Monitoring Agent takes ownership]
  ├─ Monitors: crashes, API failures, auth issues, performance, analytics
  ├─ Duration: 24–48 hours post-release (configurable per feature)
  ├─ If issue detected → escalates to Incident Agent
  └─ If clean → transitions to "Stable" → then "Done"
```

### Pre-Release Checklist (Deploy Agent Validation & Gating)

Before production deployment, Deploy Agent **must** verify:

1. ✅ **QA Passed** — QA Agent validated correctness; no functional blockers
2. ✅ **Product Acceptance Complete** — Product Manager Agent approved feature meets product requirements
3. ✅ **Release Risk Review Done** — Release Risk Agent assessed risk as Green/Yellow/Red
4. ✅ **Rollback Available & Validated** — Rollback procedure documented and dry-run confirmed
5. ✅ **Release Notes Prepared** — Customer-facing release notes approved and ready
6. ✅ **Analytics Events Firing** — Feature analytics instrumented and validated (if applicable)
7. ✅ **Monitoring Enabled** — Crash reporting, error tracking, performance monitoring active
8. ✅ **Security Sign-Off** — Security Agent reviewed code/auth/data access (if security-sensitive per Security Baseline §12)
9. ✅ **Compliance Review** — Legal & Compliance Agent flagged no blocking risks (if applicable)
10. ✅ **Environment Parity Confirmed** — Staging configuration mirrors Production (validated by Deploy Agent)

**If ANY checklist item fails:** Story returns to "Ready for Release" with specific blocker reason; Deploy Agent awaits remediation.

**If ALL checklist items pass:** Deploy Agent prepares for production deployment (does NOT deploy autonomously).
- Deploy Agent communicates: "Checklist complete. Ready for human approval."
- Awaits human review and final approval before proceeding to production.

---

## II. Deploy Agent Authority Boundaries

### What Deploy Agent May Do

✅ **Authorized Actions:**
1. Deploy to staging (Development + Staging environments)
2. Validate staging deployment (logs, errors, connectivity)
3. Validate staging ↔ production parity (config, secrets isolation, monitoring)
4. Execute rollback to previous staging deployment
5. Validate pre-release checklist completeness
6. Gate progression: prevent deployment unless all checklist items pass
7. Prepare for production deployment (staging validated, checklist complete, ready for human approval)
8. Create and validate feature flags for staged rollout (if applicable)
9. Execute production deployment (only after explicit human approval)

❌ **NOT Authorized:**
1. **Deploy to production without explicit human approval** (human approval is mandatory gate)
2. Deploy to production without Monitoring Agent staging validation
3. Skip or waive pre-release checklist items
4. Override Release Risk Agent's Red verdict
5. Override Security Agent's blocking concerns
6. Bypass rollback validation (dry-run required)
7. Deploy without release notes
8. Make autonomous decisions on staged rollout % or timing (must follow Release Risk Agent recommendation)
9. Approve or reject stories for production (human approver only)

### Production Deployment Gate (Human-Controlled)

**Explicit gate:** Deploy Agent may deploy to production **only when**:
1. Story status = "Ready for Release"
2. Release Risk verdict ≠ Red (or Red resolved with human acknowledgment of risk)
3. Pre-release checklist 100% complete (all 10 items verified)
4. TPM Agent has reviewed and **recommends** (not approves) deployment
5. Monitoring Agent confirmed Staging ↔ Production parity
6. **HUMAN explicitly approves** (mandatory final gate; cannot be skipped or delegated to agents)

**If gate conditions fail:** Deploy Agent returns story to "Ready for Release" with specific blocker reason; awaits remediation before re-submission.

**If all gate conditions pass:** Deploy Agent prepares for production but **does NOT deploy autonomously**. 
- Communicates: "[DEPLOY READY] Checklist complete, Release Risk assessed, TPM recommends proceed. Awaiting human approval."
- Waits for explicit human approval before executing production deployment.

---

## III. TPM Agent Authority Boundaries

### What TPM Agent May Do

✅ **Authorized Actions:**
1. Receive escalations from any agent (governance violations, blockers, conflicts)
2. Review Release Risk verdicts and **recommend** production deployment (Green/Yellow) or **recommend** delay (Red)
3. Coordinate cross-agent resolution (e.g., if Architect and Security disagree, TPM arbitrates per Decision Hierarchy)
4. Recommend escalation to human when TPM cannot resolve (conflicting verdicts, strategic questions, unacceptable risk)
5. Recommend release delay (if blocker unresolvable by target date)
6. Request architecture, security, or compliance review
7. Track metrics (velocity, predictability, incident frequency) and report to human
8. Manage sprint rhythm and sprint goals
9. Identify and escalate governance violations (agent overreach, skipped gates)
10. Provide context to human approver ("Release Risk recommends Green; I recommend proceed" vs. "Red verdict; risk is X")

❌ **NOT Authorized:**
1. **Approve or deny production deployment** (human approver makes final decision)
2. Override governance rules (e.g., "deploy anyway despite QA blockers")
3. Override Security Agent's blocking concerns without escalating to human
4. Override Architecture Agent's rejection of unsafe design without escalating to human
5. Deploy to production directly (only Deploy Agent may deploy if human approved)
6. Make final product decisions (roadmap, scope, deprecations — Product Manager decides)
7. Make final technical decisions (architecture, API design — Architect decides)
8. Skip required agents' reviews (e.g., "ship without Security review")
9. Waive pre-release checklist items

### TPM Decision Hierarchy & Conflict Arbitration

When agents conflict, TPM arbitrates using Decision Hierarchy (Architecture Blueprint §15):

1. **Security** > Stability > Maintainability > Scalability > Developer productivity > Performance > Sophistication

**TPM arbitration examples:**
- Architect wants feature A, Security says "A is unsafe" → **TPM recommends Security wins** (escalates to human if override requested)
- QA says "not ready," Product says "ship it" → **TPM recommends QA wins** (escalates to human if PM insists)
- Release Risk says Yellow (staged), Deploy says "deploy 100%" → **TPM recommends Release Risk wins** (enforces staged rollout recommendation)

**Key principle:** TPM arbitrates conflicts per hierarchy but does NOT make final overrides. If TPM's arbitration is disagreed with, TPM escalates to human with context:
- "Hierarchy says Security > Architect, so I recommend Design A is rejected. If you (human) want to override this, acknowledge the risk."
- Human makes final decision (override or not); TPM executes per human decision.

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

## VII. Product Acceptance Ownership

### QA Agent vs. Product Manager Agent

**Clear separation of concerns:**

**QA Agent validates:**
- ✅ Correctness: Does code implement AC exactly as written?
- ✅ Edge cases: Are all specified error conditions handled?
- ✅ Regression: Do existing features still work?
- ✅ Performance: Does feature meet performance requirements?
- ✅ Accessibility: Does feature meet WCAG 2.1 AA?

QA verdict: Feature works correctly **according to AC** (binary: pass/fail)

**Product Manager Agent approves:**
- ✅ Product value: Does feature deliver promised value?
- ✅ UX acceptability: Is the experience usable and delightful?
- ✅ Scope alignment: Does feature match original intent (or should scope be adjusted)?
- ✅ Release readiness: Are release notes, monitoring, analytics in place?
- ✅ Customer impact: How will customers perceive this feature?

PM verdict: Feature meets **product requirements and acceptance criteria** (approve/reject)

### Workflow Integration

```
[In Development]
  ↓
[Code Review] — Architect + Security review
  ↓
[QA Phase] — QA Agent validates correctness
  ├─ QA Pass: "Feature works per AC"
  └─ QA Fail: "Feature doesn't implement AC; return to dev"
  ↓
[Product Acceptance] — Product Manager Agent reviews & approves
  ├─ PM Approve: "Feature meets product requirements; ready for release"
  ├─ PM Reject: "AC met but product doesn't match intent; return to dev for scope adjustment"
  └─ PM Block: "Feature value no longer justified; cancel or defer"
  ↓
[Ready for Release] — Only if QA PASS + PM APPROVE
```

**Critical:** QA Pass + PM Reject = Return to In Development (PM may request design change, scope adjustment, or additional validation).

Only **both** QA Pass AND PM Approve allows progression to "Ready for Release".

---

## IX. Governance Reference

All clarifications above derive from:
- **Release Management Playbook v1.0** (§3 readiness, §7 rollback, §8 monitoring, §9 hotfix)
- **Environment Governance v1.0** (§4–6 deployment flow, parity, access control)
- **Agent Role Specifications v1.0** (§1 TPM, §2 PM, §10–11 Deploy, §13 Security)
- **Incident Management Playbook v1.0** (§3 workflow, §4 ownership, §5 rollback, §6 postmortem)
- **Product Memory System v1.0** (§3 memory rules, §6 retrieval rule)
- **Architecture Blueprint v1.0** (§15 decision hierarchy)
- **Security Baseline v1.0** (§11–12 security reviews, §4 auth, §5 API security)

---

## X. Final Principle

**Approvals should be fast, clear, and traceable.**

- Fast: Deploy Agent doesn't wait for approval; TPM approval is async; Deploy Agent starts checklist while Release Risk assesses
- Clear: Every agent knows their authority boundary; checklists are objective (pass/fail, not subjective)
- Traceable: Every approval comment is tagged `[AGENT NAME]` and timestamped; Product Memory records why

---

## XI. Remaining Ambiguities Needing Human Decision

**These require human input before agent formalization; cannot be resolved by governance alone:**

1. **Staged rollout defaults:** What % progression (25%→50%→100% vs. 10%→50%→100%)? How long between stages (hours vs. days)?
2. **Monitoring window duration:** 24 hours (fast shipping) or 48 hours (high confidence)? Configurable per feature?
3. **Mobile pre-release timeline:** Deploy mobile same day as web? Next day? Different sprint?
4. **Cost threshold for FinOps escalation:** At what estimated/actual cost does FinOps escalate? ($100? $1000?)
5. **Human approval for standard releases:** Always required, or only high-risk? Define "high-risk" explicitly.
6. **Rollback dry-run scope:** All releases, or only production mobile/infrastructure? Test in staging or production?
7. **Security escalation to human:** At what severity does Security escalate (all blocks, or only if TPM override requested)?

These should be decided with stakeholders before formalizing Deploy Agent and Release Risk Agent prompts.
