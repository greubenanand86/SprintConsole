#!/usr/bin/env bash
# Product Memory Agent — Per Agent Role Specifications v1.0 §13 and Product Memory System v1.0
# Mission: Maintain durable organizational memory (decisions, rationale, learnings, constraints)
# Stores: Architecture decisions, UX rationale, technical debt, release learnings, incident learnings
# Does NOT store: Brainstorming, temporary conversations, status chatter, low-confidence assumptions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_FILE="$REPO_ROOT/PRODUCT_MEMORY.md"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

KEY="${1:-}"

# Initialize memory file if needed
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'EOF'
# Product Memory — SprintOps Console

Durable organizational intelligence: decisions, rationale, learnings, constraints.

Per Product Memory System v1.0 and Product Constitution §7.

---

## Archive
(Entries recorded chronologically below)
EOF
fi

# If no key provided, summarize recent entries
if [ -z "$KEY" ]; then
  echo "[PRODUCT MEMORY] Current state of Product Memory:"
  tail -50 "$MEMORY_FILE" | head -20
  exit 0
fi

# Single-entry record mode: Record a decision or learning
cat << EOF
[PRODUCT MEMORY] $KEY — Entry Template

## 1. Memory Category
Select one: Architecture Decision | UX Rationale | Technical Debt | Release Learning | Incident Learning | Risk/Constraint

## 2. Decision / Learning
<Concise title — 1 sentence>

## 3. Context
<What triggered this? What problem does it solve?>
<Span: 2-3 sentences>

## 4. Rationale
<Why was this decision made?>
<Include: constraints, trade-offs, evidence>
<Span: 2-5 sentences>

## 5. Alternatives Considered
- <Alternative 1 — why rejected>
- <Alternative 2 — why rejected>
(Or: "None — only viable option")

## 6. Risks
- <Risk 1 — mitigation>
- <Risk 2 — mitigation>
(Or: "None identified")

## 7. Owner
<Who decided? Who maintains this decision?>
<Format: Name or [AGENT] or "Human">

## 8. Related Jira / PR
- Jira: $KEY (this ticket)
- PR: (if applicable)
- Related: (other linked decisions)

## 9. Follow-up Actions
- <Action 1 — owner — due date>
- <Action 2>
(Or: "None — decision is stable")

---

## Example Entries

### Architecture Decision: React 18 → React + TypeScript Migration Path

**1. Category:** Architecture Decision
**2. Decision:** Commit to TypeScript migration as highest-priority tech debt; target Next.js for web, React Native + Expo for mobile.
**3. Context:** Current prototype uses Babel in-browser (JSX transpilation), no build step, no types. This limits scalability, makes refactoring dangerous, and violates Engineering Constitution §2.
**4. Rationale:** TypeScript enforces type safety at compile time, reducing runtime bugs. Next.js provides built-in SSR, image optimization, and bundling. Architecture Blueprint v1.0 mandates TS for both web and mobile stacks.
**5. Alternatives:** Keep Babel (rejected — no toolchain, no scalability); TypeScript without Next.js (rejected — loses SSR, optimization benefits). Rust (rejected — out of scope).
**6. Risks:** Migration is multi-sprint effort (15-20% capacity). Must maintain feature velocity during refactor.
**7. Owner:** [ARCHITECT AGENT] + TPM + Human approval
**8. Related:** PR #12 (started), ARCHITECTURE.md v1.0, Engineering Constitution §2
**9. Follow-up:**
   - [ ] Complete TypeScript migration for core components (Sprint 5)
   - [ ] Publish Next.js POC (Sprint 6)
   - [ ] Plan mobile React Native setup (Sprint 7)
   - [ ] Sunset Babel prototype (Sprint 8)

---

### Release Learning: "We Missed Staging Validation for Hotfix #45"

**1. Category:** Release Learning
**2. Learning:** Hotfix releases that skip staging can hide integration bugs. Always validate in staging first, even for "simple" fixes.
**3. Context:** Hotfix for SEV-2 bug in authentication was merged to main and released directly without staging. A second bug was caught by users 2h post-release.
**4. Rationale:** Staging mirrors production (per Environment Governance §6) and catches integration edge cases. Even "one-line" fixes should go through staging. Pressure to release fast does not override safety.
**5. Alternatives:** None — staging is mandatory per Release Management Playbook §8.
**6. Risks:** Skipping staging to save 30 min costs 4h in postmortem and rollback.
**7. Owner:** Release Risk Agent + TPM (policy), Human (enforcement)
**8. Related:** Jira HOT-45 [INCIDENT], RELEASE_MANAGEMENT_PLAYBOOK.md §8
**9. Follow-up:**
   - [ ] Update release checklist: "Staging validation MANDATORY for all releases"
   - [ ] Add CI gate: block merge to main if staging untested

---

### Technical Debt: "Shared Component Library Not Used Consistently"

**1. Category:** Technical Debt
**2. Learning:** sprintops-shared.jsx defines Button, Badge, Card, Modal, StatusIcon. But new features often create one-off duplicates instead of using the library.
**3. Context:** This causes visual fragmentation and maintenance burden. Each duplicate needs independent bug fixes and style updates.
**4. Rationale:** Shared components reduce cognitive load, ensure consistency, and speed up feature work. Every duplicate is technical debt.
**5. Alternatives:** None — shared library is the standard per Engineering Constitution §3.
**6. Risks:** Fragmentation accumulates. By Sprint 8, we'll have 30+ variants of Button.
**7. Owner:** [ARCHITECT AGENT] + [UX DESIGNER] (enforce in code review)
**8. Related:** sprintops-shared.jsx, Engineering Constitution §3, ARCHITECTURE.md
**9. Follow-up:**
   - [ ] Code review checklist: reject new components that could use shared library
   - [ ] Audit existing components (estimate effort for consolidation)
   - [ ] Plan consolidation sprint (probably Sprint 6, 10-15% capacity)

---

## Guidelines for Recording

**DO RECORD:**
- Architecture decisions (stack, structure, migration paths)
- UX rationale (why this design, not another)
- Technical debt (known limitations, plans to address)
- Release learnings (what went wrong, how to prevent)
- Incident learnings (root cause, prevention)
- Known constraints (API limits, business rules, regulatory)
- Risks identified by agents (flagged for human decision)

**DO NOT RECORD:**
- Brainstorming (use Jira comments, not memory)
- Temporary conversations (e.g., "we discussed ...today")
- Status chatter ("story merged", "deployment successful")
- Low-confidence assumptions ("probably caused by X")
- Routine work (features ship, bugs are closed)
- Intermediate thinking (drafts, revisions)

**Quality Bar:**
- Durable: Still relevant in 6 months?
- Actionable: Can someone reading this take action?
- Owned: Is it clear who decided / who maintains?
- Linked: Is it connected to Jira and code?

---

[Product Memory Agent] — Per Agent Role Specifications v1.0 §13 | PRODUCT_MEMORY_SYSTEM v1.0
EOF

# Append to memory file if provided
if [ -n "$KEY" ] && [ "$KEY" != "init" ]; then
  {
    echo ""
    echo "### $TITLE (recorded $TIMESTAMP)"
    echo ""
    echo "**Category:** (specify)"
    echo "**Decision:** (title)"
    echo "**Context:** (problem, trigger)"
    echo "**Rationale:** (why this choice)"
    echo "**Alternatives:** (what else was considered)"
    echo "**Risks:** (known risks, mitigations)"
    echo "**Owner:** (who decided, who maintains)"
    echo "**Related:** Jira $KEY"
    echo "**Follow-up:** (actions needed)"
  } >> "$MEMORY_FILE"

  git -C "$REPO_ROOT" add PRODUCT_MEMORY.md 2>/dev/null || true
  git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null || \
    git -C "$REPO_ROOT" commit -m "chore: record organizational learning in Product Memory [§13]" 2>/dev/null || true

  echo "[PRODUCT MEMORY] Entry template appended to PRODUCT_MEMORY.md"
  echo "Edit the template fields and commit to finalize recording."
fi

exit 0
