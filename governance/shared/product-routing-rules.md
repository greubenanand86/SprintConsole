# Product Routing Rules — Portfolio TPM

For every new request, the Portfolio TPM must answer six questions before routing. Work does not move forward until all six are resolved.

If context is insufficient to answer any question, stop and ask for clarification. Routing on incomplete context causes misrouted work, duplicated effort, and cross-product interference.

---

## The six routing questions

### 1. Which product does this belong to?

Resolve in this order:

1. **Explicit product stated** — requester names the product. Accept it, confirm the Jira prefix.
2. **Jira key provided** — resolve prefix from `products/registry.json` (e.g. `SC-` → SprintConsole).
3. **Feature description only** — match against each product's `product-brief.md` capability list. If exactly one product owns that capability area, route there.
4. **Ambiguous or cross-product** — do not guess. Ask: *"Which product is this request for?"*

**Routing outcomes:**

| Situation | Action |
|---|---|
| Single product identified | Proceed to Q2 |
| Two products equally plausible | Ask requester to clarify before proceeding |
| New product not yet in registry | Escalate to human — new product onboarding requires a governance decision |
| "All products" or platform-level | Treat as shared platform work — see Q2 |

> **Example:** A request to "add keyboard navigation to the release gate view" → SprintConsole owns the release gate view → `SC` board.
>
> **Example:** A request to "improve the estimation flow" with no product named → two products could plausibly have estimation features → ask which product before routing.

---

### 2. Is this shared platform work or product-specific work?

Use the tests from `shared-vs-product-specific-rules.md`. Key signal:

| Signal | Classification |
|---|---|
| Would this change apply to every product? | Shared platform |
| Would two products reasonably implement this differently? | Product-specific |
| Does it touch `/packages`, `/governance/shared`, or agent prompts? | Shared platform |
| Does it touch one product's source tree, roadmap, or memory? | Product-specific |
| Is it a standard being extracted from one product to apply everywhere? | Shared platform — requires Architecture Agent review |

**Routing outcomes:**

| Classification | Routing target |
|---|---|
| Product-specific | Route to that product's TPM Agent and Jira board |
| Shared platform | Route to shared backlog; assign Architecture Agent to scope it; flag cross-product impact |
| Mixed (product feature that may become shared) | Start as product-specific; flag for extraction review after delivery |

> **Example:** "Add a `Button` component to the design system so both web and mobile can use it" → shared platform → `packages/ui`, Architecture Agent scopes it.
>
> **Example:** "Change the card layout on SprintConsole's Readiness Tracker" → product-specific → `SC` board, UX Agent reviews.
>
> **Example:** "Add structured logging to SprintConsole" → starts product-specific, but if the logging pattern is worth extracting to `packages/`, flag for Architecture Agent after delivery.

---

### 3. Which product memory should be used?

| Work type | Memory location |
|---|---|
| Product-specific feature decision | `products/{product-id}/product-memory/product-decisions/` |
| UX decision for one product | `products/{product-id}/product-memory/ux-decisions/` |
| Architecture decision for one product | `products/{product-id}/product-memory/architecture-decisions/` |
| Technical debt logged for one product | `products/{product-id}/product-memory/technical-debt/` |
| Release learning for one product | `products/{product-id}/product-memory/release-learnings/` |
| Incident in one product | `products/{product-id}/product-memory/incidents/` |
| Shared platform decision (affects all products) | `governance/shared/` — update or create the relevant governance document |
| Cross-product dependency resolution | Record in both affected products' memories and link them |

Never write a product-specific decision into shared governance. Never write a shared governance decision into only one product's memory.

> **Example:** Architecture Agent decides SprintConsole will use Next.js App Router → `products/sprintconsole/product-memory/architecture-decisions/2025-05-26-nextjs-app-router.md`
>
> **Example:** Portfolio TPM resolves that all products must use the shared `packages/validation` library for form schemas → update `governance/shared/shared-package-strategy.md`.
>
> **Example:** SprintConsole and a second product both depend on the same API endpoint → record the dependency in both products' `architecture-decisions/` with a cross-reference link.

---

### 4. Which Jira project and board should be used?

Resolve from `products/registry.json` and each product's `jira-mapping.md`.

| Situation | Board |
|---|---|
| Product-specific story | That product's Jira project (e.g. `SC` for SprintConsole) |
| Shared platform story | Shared platform backlog — if none exists, flag to human to create it |
| Cross-product dependency story | Primary product's board; dependency linked as a blocking issue on the secondary board |
| Spike to determine ownership | Route to the most likely product's board; re-route if spike changes the answer |

Stories must not be filed on the wrong board to "keep it simple." Misrouted stories break agent ownership, WIP accounting, and release tracking.

> **Example:** "Fix keyboard navigation on the Estimation Planner" → `SC` board, QA Lead Agent owns validation.
>
> **Example:** "Define the shared API error format" → shared platform backlog, Architecture Agent scopes it, all product TPM Agents notified.
>
> **Example:** SprintConsole's mobile release depends on `packages/ui` shipping first → story on `SC` board; blocking dependency linked to the shared packages backlog story.

---

### 5. Are there cross-product dependencies?

Check for dependencies before any story is accepted for a sprint:

**Signals that a cross-product dependency exists:**
- Story touches `/packages` — any change there affects every consumer
- Story requires an API contract change — consumers must update in a coordinated release
- Story references a shared component, config value, or governance document
- Two products are targeting the same release window and share infrastructure
- A team capacity constraint on one product delays a dependency another product needs

**Dependency handling:**

| Dependency type | Action |
|---|---|
| Packages change | Block all consumer stories until package story is scoped and scheduled; Architecture Agent reviews API contract |
| API contract change | Notify all affected product TPM Agents before sprint planning; version the contract per `api-contract-standards.md` |
| Shared governance change | Portfolio TPM authors the change; all product TPM Agents acknowledge before merge |
| Capacity constraint | Escalate to human — do not silently delay a dependent product's sprint |
| Circular dependency (A blocks B, B blocks A) | Escalate to human immediately — do not attempt autonomous resolution |

> **Example:** SprintConsole wants to ship a new shared `Card` component and also consume it in the same sprint → the `packages/ui` story must ship and be versioned before the consumer story can be considered done. Flag this as a same-sprint dependency risk.
>
> **Example:** A second product wants to use SprintConsole's Jira integration library → that library must first be extracted to `/packages/api-client`, which is an Architecture Agent task that blocks both products' stories.

---

### 6. Does this require a human priority decision?

Escalate to a human before routing when any of the following are true:

| Condition | Why human required |
|---|---|
| Two products compete for the same shared resource (capacity, package, platform slot) | Priority between products is a business decision, not an agent call |
| A story would change shared governance in a way that affects another product's roadmap | Cross-product roadmap impact requires human alignment |
| A security or legal flag is raised on a story | Security Baseline and Legal Governance require human sign-off |
| A cross-product dependency cannot be resolved within existing sprint capacity | Scope or timeline trade-off — human decides which product yields |
| Agents disagree on routing, classification, or priority | Conflict resolution is a human decision; agents present options, not verdicts |
| A new product is being added to the registry | Governance onboarding requires human approval |
| A story would introduce a new shared package (first time a capability moves to `/packages`) | Architectural investment requiring human commitment |

When escalating, the Portfolio TPM must provide:

```
[PORTFOLIO TPM — ESCALATION REQUIRED]

Situation:   {What is the request and what makes it ambiguous or contested}
Options:     {Two or three concrete paths with trade-offs}
Recommended: {Which path and why — if a clear recommendation exists}
Blocked on:  {The specific decision the human must make}
Affects:     {Which products, sprints, or governance documents are involved}
```

Never hold work silently waiting for resolution. Escalate, record the escalation, and let the human unblock it.

> **Example:** SprintConsole and a new product both need a real-time notification system. Shared infrastructure or built twice? → Escalate. Portfolio TPM presents: (A) shared `/packages/notifications` now, (B) each product builds their own and extracts later. Human decides.
>
> **Example:** Security Agent flags a third-party SDK in a story as requiring legal review → escalate before the story proceeds past Code Review. Do not route to QA until resolved.

---

## Clarification rule

If product context is unclear on any of the six questions, the Portfolio TPM must ask before routing. The clarification request must be specific:

**Wrong:** "Can you provide more context?"
**Right:** "I can't determine which product this belongs to. Is this for SprintConsole (`SC`) or a different product? The capability described could fit either."

**Wrong:** "Is this shared or product-specific?"
**Right:** "This looks like it could be either a shared `packages/ui` change or a SprintConsole-only UI pattern. Does this need to work across all products, or only in SprintConsole?"

Routing on assumptions wastes sprint capacity. One clarifying question is cheaper than a misrouted story.

---

## Routing output format

When routing is complete, the Portfolio TPM records:

```
[PORTFOLIO TPM — ROUTING DECISION]

Request:      {Brief description of the work}
Product:      {product-id} / shared platform
Jira board:   {PROJECT-KEY} / shared backlog
Memory:       {products/{id}/product-memory/{category}/ or governance/shared/}
Dependencies: {None / list with linked stories}
Human needed: {No / Yes — reason and escalation block above}
Routed to:    {Product TPM Agent / Architecture Agent / Human}
```
