# FeatureForge — Jira Story Backlog v1.0

**Generated:** 2026-05-26
**Product:** FeatureForge — AI-powered spec generator
**Status:** MVP scaffolded. Backlog covers everything needed to reach paid-product readiness.
**Governance:** Jira Workflow Governance v1.1 applies. All stories start at **Triage**.

---

## Epic Index

| Epic | Name | Theme |
|------|------|-------|
| EP-01 | Auth & Identity | Secure, frictionless access |
| EP-02 | Credit System & Billing | Monetisation foundation |
| EP-03 | Generation Engine | Core AI value delivery |
| EP-04 | Output Experience | Copy, export, re-use |
| EP-05 | History & Persistence | DB-backed generation records |
| EP-06 | Observability & FinOps | Token cost, usage metrics, logging |
| EP-07 | Infrastructure & Tech Debt | DB, testing, CI/CD, deployment |

---

## Sprint Allocation Targets (Jira Workflow Governance §9)

| Category | Target | Stories in this backlog |
|---|---|---|
| Feature | 50–60% | FF-001–FF-019, FF-021–FF-022 |
| Tech Debt | 15–20% | FF-028–FF-034 |
| Design Debt | 10–15% | FF-023–FF-025 |
| Bug | 15–20% | FF-026–FF-027 |

---

---

# EP-01 — Auth & Identity

> Secure, frictionless authentication for Google OAuth users and demo-mode visitors. Session management, token hygiene, and access control gates.

---

### FF-001 · Harden Demo Mode Isolation

**Epic:** EP-01 — Auth & Identity
**Title:** As a product owner, I want demo-mode users to be fully isolated from production data and rate-limited so that demo abuse cannot exhaust AI API quotas or pollute metrics.
**Priority:** Critical
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `auth` `infra` `credits`

**Business Objective:**
Demo mode is an unauthenticated bypass that currently shares the same in-memory credit store logic as real users. Before the product accepts paid users, demo sessions must be sandboxed, rate-limited, and clearly flagged in observability pipelines to prevent abuse-driven API cost overruns.

**Acceptance Criteria:**
- [ ] Demo session user ID is always `demo-user-001` (already set); no other demo IDs can be created
- [ ] Demo users have a hard cap of 3 generations per browser session (not per server restart)
- [ ] Demo credit balance resets on each new session; it never persists across sessions
- [ ] All API calls from demo sessions are tagged with `x-featureforge-demo: true` in server logs
- [ ] Demo users attempting to exceed their session cap receive a clear upgrade prompt, not a generic error
- [ ] Demo mode does not appear in billing, history, or usage metrics dashboards
- [ ] Automated test: demo user blocked after 3 generations in the same session

**UX Expectations:**
- DemoBanner component already exists; extend it to show remaining demo generations (e.g., "2 of 3 demo generations used")
- On cap hit: show a modal with "Sign in with Google to get 10 free credits" CTA — not a toast
- Banner must be visible on every authenticated page for demo users

**Edge Cases:**
- User refreshes page mid-session: session count must survive page refresh (store in session cookie, not server memory)
- Server restart: demo count resets — acceptable for MVP; document the limitation
- User opens multiple tabs in demo mode: all tabs share the same session cap
- Demo user manipulates client-side state: server-side enforcement is the authoritative gate

**Dependencies:** None (self-contained)

**API Considerations:**
- `GET /api/credits` must return `isDemo: true` flag in the response body for demo sessions
- `POST /api/generate` must enforce the 3-generation session cap server-side before calling the AI provider

**QA Notes:**
- Test: 3 generations succeed, 4th is blocked with correct error message
- Test: DemoBanner shows correct count after each generation
- Test: Upgrade modal renders and links to sign-in correctly
- Test: Demo user cannot access `/history` or `/usage` pages in a meaningful way (empty state is acceptable)

---

### FF-002 · Google OAuth Session Persistence & Token Refresh

**Epic:** EP-01 — Auth & Identity
**Title:** As a signed-in user, I want my session to stay valid for a reasonable duration without forcing repeated sign-ins so that I can work across multiple browser sessions without friction.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `auth` `backend`

**Business Objective:**
NextAuth JWT sessions currently use default settings (24-hour expiry). Paid users who return the next day will be silently logged out and lose any in-flight context. Configuring session lifetime and providing graceful re-authentication improves retention and reduces support tickets.

**Acceptance Criteria:**
- [ ] JWT session maxAge set to 30 days (configurable via `SESSION_MAX_AGE_DAYS` env var)
- [ ] Session token is refreshed on each request if it has less than 7 days remaining
- [ ] On session expiry, user is redirected to sign-in page with a `?reason=session_expired` query param
- [ ] Sign-in page shows a human-readable "Your session expired — please sign in again" message when that param is present
- [ ] `NEXTAUTH_SECRET` is validated at startup; server throws a clear error if it matches the dev default in a non-development environment
- [ ] Session user ID (`token.sub`) is stable across token refreshes — no new IDs generated on refresh

**UX Expectations:**
- No loading spinner should appear on page load if a valid session cookie exists (SSR session check)
- Session expiry warning is not shown unless expiry is within 24 hours (future enhancement — flag as out of scope for this story)

**Edge Cases:**
- User revokes Google OAuth consent: next API call returns 401; redirect to sign-in with `?reason=revoked`
- Multiple browser tabs: session refresh in one tab must not invalidate others
- User changes Google account password: Google revokes token; handle gracefully (same as consent revocation)

**Dependencies:** FF-028 (environment variable governance — `SESSION_MAX_AGE_DAYS` must be in `.env.example`)

**API Considerations:**
- No new API endpoints required
- Ensure all API routes return `401` (not `500`) when session is missing or expired

**QA Notes:**
- Test: sign in, wait (mocked) past expiry, confirm redirect with correct reason param
- Test: `NEXTAUTH_SECRET` dev default triggers startup warning in staging/production environments
- Test: session user ID is identical before and after token refresh

---

### FF-003 · Role-Based Access Guard (Admin vs. User)

**Epic:** EP-01 — Auth & Identity
**Title:** As an administrator, I want role-based access control so that admin-only pages (usage analytics, plan overrides) are protected from regular users.
**Priority:** Medium
**Story Points:** 2
**Sprint Allocation Category:** Feature
**Labels:** `auth` `backend` `infra`

**Business Objective:**
As the product grows, operational needs (viewing aggregate usage, overriding plans for sales demos, inspecting error logs) require an admin interface. Without RBAC, there is no safe way to expose these capabilities. This story lays the minimal RBAC foundation.

**Acceptance Criteria:**
- [ ] `ADMIN_EMAILS` environment variable accepts a comma-separated list of email addresses
- [ ] Users whose email is in `ADMIN_EMAILS` receive `role: 'admin'` in their JWT and session
- [ ] `AuthGuard` component accepts an optional `requiredRole` prop; redirects non-admin users to `/dashboard` with a toast
- [ ] A protected `/admin` route (page stub is acceptable) requires admin role to access
- [ ] Admin role is checked server-side on every request to admin API routes — not only on the client

**UX Expectations:**
- Non-admin users navigating to `/admin` should be silently redirected — no error page shown
- Admin indicator (e.g., a small badge in the sidebar) visible only to admin users

**Edge Cases:**
- `ADMIN_EMAILS` is empty or not set: no users have admin role; admin routes are inaccessible to all
- Admin user signs out and signs back in with a different account: role reflects the new account

**Dependencies:** FF-028 (env var governance)

**API Considerations:**
- Admin API routes must validate `session.user.role === 'admin'` server-side
- Do not expose admin role to client-side session if it can be avoided

**QA Notes:**
- Test: admin user can access `/admin`; non-admin user is redirected
- Test: removing email from `ADMIN_EMAILS` immediately removes access on next session refresh
- Test: direct API call to admin endpoint without admin session returns 403

---

---

# EP-02 — Credit System & Billing

> Database-backed credits, Stripe payment integration, plan upgrade/downgrade flows, and billing portal. This epic is the direct revenue enabler.

---

### FF-004 · Migrate Credit Store from In-Memory to Database (Prisma + PostgreSQL)

**Epic:** EP-02 — Credit System & Billing
**Title:** As a platform operator, I want credit balances persisted in a database so that credits survive server restarts and can be reliably billed against.
**Priority:** Critical
**Story Points:** 8
**Sprint Allocation Category:** Tech Debt
**Labels:** `backend` `infra` `credits` `database`

**Business Objective:**
The current `Map<string, CreditBalance>` in `/lib/credits/index.ts` is wiped on every server restart. This is the single most critical blocker to charging real money. No Stripe integration can be reliable without durable credit storage. This story is a prerequisite for every billing story.

**Acceptance Criteria:**
- [ ] Prisma ORM installed and configured with a PostgreSQL connection (`DATABASE_URL` env var)
- [ ] `CreditBalance` model in Prisma schema with fields: `id`, `userId`, `total`, `used`, `remaining`, `plan`, `createdAt`, `updatedAt`
- [ ] `getOrCreateBalance`, `deductCredits`, `addCredits`, `setPlan` functions in `/lib/credits/index.ts` replaced with Prisma-backed equivalents
- [ ] Database migrations generated and committed (`prisma/migrations/`)
- [ ] Credit operations are atomic (Prisma transactions used for deduct-and-create-record operations)
- [ ] All existing API routes (`/api/credits`, `/api/generate`) pass existing behaviour tests after migration
- [ ] Seed script creates a free-plan balance for any new user on first sign-in

**UX Expectations:**
- No visible change to the user — credit balance displayed on dashboard and generate page must remain accurate
- If the database is unreachable, the API returns 503 with a user-readable message ("Service temporarily unavailable — please try again")

**Edge Cases:**
- Two simultaneous generation requests from the same user: Prisma transaction with `select for update` prevents double-spend
- User signs in for the first time: balance row is created with `free` plan and 10 credits on first `/api/credits` call
- Database migration fails mid-deploy: old in-memory code must still run (maintain a feature flag `USE_DB_CREDITS=true`)

**Dependencies:** FF-028 (environment governance), FF-032 (CI/CD must run `prisma migrate deploy`)

**API Considerations:**
- No breaking changes to API response shape
- Add `updatedAt` timestamp to `/api/credits` response for cache-busting

**QA Notes:**
- Test: deduct credits, restart server, confirm balance persisted
- Test: concurrent requests cannot overdraw credits below zero
- Test: new user gets 10 credits on first sign-in
- Test: database down returns 503, not 500 or unhandled error

---

### FF-005 · Stripe Checkout Integration — Plan Upgrade Flow

**Epic:** EP-02 — Credit System & Billing
**Title:** As a free-plan user, I want to upgrade to a paid plan through a Stripe checkout so that I can get more credits and continue generating specs.
**Priority:** Critical
**Story Points:** 8
**Sprint Allocation Category:** Feature
**Labels:** `billing` `stripe` `credits` `backend`

**Business Objective:**
This is the primary revenue mechanism. Without Stripe checkout, the product cannot generate revenue. All four plans (Free/Starter/Pro/Team) need purchasable upgrade paths. Free-to-Starter is the highest-priority conversion funnel.

**Acceptance Criteria:**
- [ ] Stripe SDK installed (`stripe` npm package)
- [ ] `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` configured as environment variables
- [ ] Price IDs for Starter ($9), Pro ($19/mo), and Team ($49/mo) configured via env vars (`STRIPE_PRICE_STARTER`, etc.)
- [ ] `POST /api/billing/checkout` creates a Stripe Checkout Session and returns a `url` for redirect
- [ ] On successful payment, Stripe webhook (`POST /api/billing/webhook`) updates the user's plan and credits in the database
- [ ] Webhook endpoint validates Stripe signature (`STRIPE_WEBHOOK_SECRET` env var) — rejects requests without valid signature
- [ ] Successful upgrade: user's `plan` and `remaining` credits are updated atomically
- [ ] User is redirected to `/dashboard?upgraded=true` after successful checkout; dashboard shows a success toast
- [ ] Failed or cancelled checkout returns user to `/settings` with no credit change

**UX Expectations:**
- Settings page "Plan & Credits" section: each non-current plan card shows an "Upgrade" button (currently static)
- Upgrade button triggers checkout redirect — no modal needed for MVP
- Post-upgrade: dashboard shows the new plan badge and updated credit balance immediately
- Failed payment: show a toast "Payment was not completed — your plan has not changed"

**Edge Cases:**
- User is already on a higher plan; downgrade path is out of scope for this story (flag for EP-02 backlog)
- Webhook arrives before checkout redirect (race condition): idempotency key on the webhook handler
- Duplicate webhook delivery: Stripe sends each event at least once; handler must be idempotent (check `stripeEventId` in DB before processing)
- User closes browser during checkout: no credit change, Stripe session expires after 24 hours

**Dependencies:** FF-004 (DB-backed credits required before billing can update balances)

**API Considerations:**
- `POST /api/billing/checkout` — body: `{ plan: PlanType }`, response: `{ url: string }`
- `POST /api/billing/webhook` — raw body required; must not be parsed as JSON before signature verification
- `GET /api/billing/status` — returns current plan and next renewal date (future story; flag dependency)

**QA Notes:**
- Test with Stripe test mode keys and test card `4242 4242 4242 4242`
- Test: successful checkout updates plan in DB and redirects correctly
- Test: cancelled checkout returns to settings with no state change
- Test: webhook with invalid signature returns 400
- Test: duplicate webhook for the same event is a no-op (idempotent)
- Test: Starter checkout grants exactly 50 credits; Pro grants 150; Team grants 500

---

### FF-006 · Credit Balance UI — Real-Time Display & Low-Credit Warnings

**Epic:** EP-02 — Credit System & Billing
**Title:** As a user, I want to see my current credit balance and receive clear warnings when credits are running low so that I am never surprised by a blocked generation.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `credits` `ui`

**Business Objective:**
The dashboard already renders a credit bar from server-side data. The generate page fetches balance separately. There is no real-time update after a generation, no persistent low-credit warning across pages, and no upgrade CTA tied to specific credit thresholds. This story makes the credit experience clear and conversion-optimised.

**Acceptance Criteria:**
- [ ] After any generation completes, the credit balance displayed on the generate page updates immediately (no page reload required)
- [ ] Credit badge in the sidebar (or navbar) shows live remaining credits on all authenticated pages
- [ ] At ≤3 credits: amber warning banner appears on the dashboard with an upgrade CTA
- [ ] At 0 credits: generate button is disabled; a modal prompts upgrade before attempting generation
- [ ] Credit balance is fetched client-side on mount and after each generation via `GET /api/credits`
- [ ] Balance refetch does not block the output display — optimistic update is acceptable

**UX Expectations:**
- Credit badge: small pill in the sidebar showing remaining credits and a lightning icon (matches existing `CreditBadge` component style)
- Low-credit banner: non-blocking (dismissible per session), amber, with "Upgrade plan" link pointing to `/settings`
- Zero-credit state on generate page: disable the Generate button, show inline message "You're out of credits. Upgrade to continue."
- No spinner on balance fetch — show stale value while refreshing

**Edge Cases:**
- User has 2 credits and tries to run Full Package (10 credits): button must be disabled before submission, not rejected after
- Balance fetch fails (network error): show last known balance with a "⚠ Balance may be out of date" indicator
- Demo user: show demo-specific message ("Demo credits — sign in for real credits"), not upgrade CTA

**Dependencies:** FF-004 (DB credits), FF-005 (Stripe — not blocking; upgrade CTA can link to `/settings` in the interim)

**API Considerations:**
- `GET /api/credits` response shape unchanged; add `updatedAt` field if not already present
- No new endpoints required

**QA Notes:**
- Test: run a generation, verify credit count decreases without page reload
- Test: at 3 credits remaining, warning banner appears on dashboard
- Test: at 0 credits, Generate button is disabled
- Test: Full Package button disabled if remaining < 10; other types enabled/disabled per their cost

---

### FF-007 · Monthly Credit Reset & Billing Cycle Management

**Epic:** EP-02 — Credit System & Billing
**Title:** As a paid subscriber, I want my credits to reset at the start of each billing cycle so that my subscription provides consistent value every month.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Feature
**Labels:** `billing` `stripe` `credits` `backend`

**Business Objective:**
Paid plans are monthly subscriptions. Credits must reset each billing cycle. Without this, users who exhaust credits in week 1 have no incentive to remain subscribed — they would churn immediately or raise support tickets.

**Acceptance Criteria:**
- [ ] Stripe `invoice.paid` webhook event triggers a credit reset for the user associated with the subscription
- [ ] Credit reset replaces `remaining` with the full plan allocation; `used` is reset to 0; `total` is set to plan allocation
- [ ] `CreditBalance` schema includes `resetAt` (timestamp of last reset) and `nextResetAt` (next scheduled reset)
- [ ] `GET /api/credits` response includes `nextResetAt` so the UI can display "resets in X days"
- [ ] Usage page displays "Credits reset on [date]" based on `nextResetAt`
- [ ] Free plan users do not receive monthly resets (credits are one-time allocation)

**UX Expectations:**
- Usage page: add a "Next reset" row showing days until reset and the reset date
- Post-reset: dashboard shows updated balance without requiring a sign-out/sign-in

**Edge Cases:**
- User upgrades mid-cycle: credits are topped up immediately (FF-005 handles this); reset cycle starts from upgrade date
- User cancels subscription: credits are not reset; remaining credits are available until end of current period
- Webhook arrives late (Stripe retry): idempotency check on `stripeInvoiceId` prevents double-reset
- User has carried-over credits from a bonus (future feature): reset must not zero out bonus credits — out of scope; document as known limitation

**Dependencies:** FF-004 (DB credits), FF-005 (Stripe webhook infrastructure)

**API Considerations:**
- New webhook event handler: `invoice.paid` in `/api/billing/webhook`
- `GET /api/credits` response: add `nextResetAt: string | null`

**QA Notes:**
- Test: simulate `invoice.paid` webhook; verify credit reset in DB
- Test: free plan user is not affected by `invoice.paid` handler
- Test: duplicate `invoice.paid` event does not double-reset
- Test: usage page shows correct next reset date after reset

---

### FF-008 · Billing Portal — Subscription Management

**Epic:** EP-02 — Credit System & Billing
**Title:** As a paid subscriber, I want to access a self-service billing portal so that I can update my payment method, view invoices, and cancel my subscription without contacting support.
**Priority:** Medium
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `billing` `stripe` `ui`

**Business Objective:**
Stripe provides a hosted Customer Portal that handles plan changes, payment method updates, and cancellations. Exposing this reduces support burden and is required for subscription self-service compliance in most jurisdictions.

**Acceptance Criteria:**
- [ ] `POST /api/billing/portal` creates a Stripe Customer Portal session and returns a redirect URL
- [ ] Settings page "Plan & Credits" section shows a "Manage billing" button for paid users
- [ ] Button opens the Stripe portal in the current tab (not a new tab, to maintain UX continuity)
- [ ] Free users see "Upgrade plan" instead of "Manage billing"
- [ ] After returning from the portal, `/settings` re-fetches the current plan from the database

**UX Expectations:**
- "Manage billing" button: secondary style, positioned below the plan cards
- Return URL configured in Stripe portal to redirect back to `/settings`
- On return: show a toast "Billing updated successfully" if `?billing_updated=true` is in the query string

**Edge Cases:**
- User cancels in the portal: plan remains active until period end; UI should not immediately downgrade
- User has no Stripe customer record (downgraded to free manually): "Manage billing" button should not appear

**Dependencies:** FF-005 (Stripe customer ID must be stored in DB when checkout is created)

**API Considerations:**
- `POST /api/billing/portal` — no body; response: `{ url: string }`
- Stripe customer ID must be stored on the `User` model in the DB

**QA Notes:**
- Test: paid user sees "Manage billing" button; free user sees "Upgrade plan"
- Test: portal session creation fails gracefully (503 message, not crash)
- Test: return URL redirects correctly to `/settings`

---

---

# EP-03 — Generation Engine

> AI provider reliability, streaming output, retry logic, input validation, and generation quality improvements.

---

### FF-009 · Streaming Generation Output

**Epic:** EP-03 — Generation Engine
**Title:** As a user, I want to see the AI-generated output appear word-by-word as it streams so that I am not staring at a blank screen for 20–30 seconds during large generations.
**Priority:** High
**Story Points:** 8
**Sprint Allocation Category:** Feature
**Labels:** `ai` `ui` `backend`

**Business Objective:**
Full Package generations can take 20–30 seconds with powerful models. Without streaming, users see a spinner for the entire duration and may abandon or retry (wasting credits). Streaming reduces perceived latency by showing progress immediately, which is the industry standard for AI applications and directly impacts retention.

**Acceptance Criteria:**
- [ ] `POST /api/generate` supports streaming via Server-Sent Events (SSE) or Next.js `ReadableStream` response
- [ ] Anthropic, OpenAI, and Gemini provider implementations updated to use their respective streaming APIs
- [ ] `OutputViewer` component renders streamed content in real-time as chunks arrive
- [ ] A "Stop generation" button appears during streaming; clicking it aborts the stream and retains whatever has been generated
- [ ] Credits are deducted only after a generation completes successfully (not at stream start)
- [ ] If the stream is aborted by the user, credits are not deducted
- [ ] If the stream fails mid-way (provider error), credits are not deducted and an error state is shown
- [ ] Streaming works for all 7 generation types

**UX Expectations:**
- During streaming: output area shows content building up with a blinking cursor at the end
- Stop button: small, secondary style, appears below the output area during generation
- After completion: "Stop" button disappears; copy/export buttons appear
- If generation fails mid-stream: show the partial content (if > 20% complete) with a warning banner; otherwise show a clean error state

**Edge Cases:**
- User closes the browser tab mid-stream: server aborts the AI call; no credits deducted
- Network interruption mid-stream: show "Connection lost — your generation was not saved" with a retry option (retry costs credits)
- Provider returns an empty stream: treat as an error — do not show an empty output
- Very fast responses (gap-check, AC): streaming may complete in under 2 seconds; skip cursor animation for sub-2-second completions

**Dependencies:** FF-004 (DB credits must be deducted only on completion, not on stream start — requires transactional write after stream closes)

**API Considerations:**
- Response: `Content-Type: text/event-stream` (SSE) or `application/octet-stream` (ReadableStream)
- Event format: `data: {"chunk": "...", "done": false}` / `data: {"done": true, "tokensIn": N, "tokensOut": N}`
- Client uses `EventSource` or `fetch` with `response.body.getReader()`

**QA Notes:**
- Test: Full Package streams correctly with each provider
- Test: Abort mid-stream — credits not deducted, partial content shown
- Test: Provider error mid-stream — clean error state, no credit deduction
- Test: Stream completes — credits deducted, copy/export buttons appear
- Test: "Stop" button keyboard accessible (focusable, Enter triggers stop)

---

### FF-010 · Provider Fallback & Retry Logic

**Epic:** EP-03 — Generation Engine
**Title:** As a user, I want generation to automatically retry with a fallback provider if my selected provider is unavailable so that I do not lose credits or have to manually retry.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Feature
**Labels:** `ai` `backend` `infra`

**Business Objective:**
AI providers experience rate limits, timeouts, and outages. Currently, any provider failure returns a 502 error to the user with no recourse. Automatic retry and fallback reduces generation failure rates, protects user credits, and makes the product feel reliable.

**Acceptance Criteria:**
- [ ] On provider error (rate limit, timeout, 5xx), the system retries the same provider once after a 2-second delay
- [ ] If retry fails, the system attempts the next available provider (configurable fallback order via `PROVIDER_FALLBACK_ORDER` env var)
- [ ] Credits are deducted only from the final successful generation — not for failed attempts
- [ ] Error response distinguishes between "all providers failed" (503) and "generation produced no output" (502)
- [ ] Provider fallback is logged with structured context: `{ originalProvider, fallbackProvider, reason, durationMs }`
- [ ] User is informed which provider was ultimately used in the generation result metadata
- [ ] Rate limit responses (HTTP 429) from providers trigger an exponential backoff (2s, 4s) before retry

**UX Expectations:**
- If fallback occurred: show a subtle note in the output metadata: "Generated with [fallback provider] (your selected provider was unavailable)"
- No UX disruption during retry — the spinner/streaming state continues seamlessly
- If all providers fail: show a clear error with a "Try again" button (does not cost credits if not yet deducted)

**Edge Cases:**
- User has specifically selected Gemini (e.g., for long-context work) and Gemini is down: fallback to another provider, but notify the user
- All three providers are rate-limited simultaneously: return 503 with "AI services are currently busy — please try again in a few minutes"
- Provider returns a malformed response (not an error, but unparseable): treat as provider failure and trigger retry

**Dependencies:** None (independent of DB migration, can ship on in-memory credits temporarily)

**API Considerations:**
- Add `provider` and `fallbackOccurred: boolean` to the generation result response
- `PROVIDER_FALLBACK_ORDER` env var: e.g., `anthropic,openai,gemini`

**QA Notes:**
- Test: mock provider 1 to return 429; confirm retry then fallback to provider 2
- Test: all providers mocked to fail; confirm 503 response and no credit deduction
- Test: fallback metadata appears in response body
- Test: exponential backoff timing (unit test with mocked timers)

---

### FF-011 · Input Validation & Prompt Safety Layer

**Epic:** EP-03 — Generation Engine
**Title:** As a platform operator, I want all user-submitted feature ideas to pass through a validation and safety layer so that the product is not used to generate harmful content or abuse the AI APIs.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `ai` `backend` `infra`

**Business Objective:**
The current validation is purely structural (length check). There is no prompt injection guard, no profanity/abuse filter, and no detection of attempts to jailbreak the system prompt. As a paid product with API costs, abuse protection is a business requirement, not a stretch goal.

**Acceptance Criteria:**
- [ ] Input is checked for known prompt injection patterns before being passed to any AI provider (blocklist of patterns like "ignore previous instructions", "system prompt", etc.)
- [ ] Input exceeding 3000 characters is rejected (already implemented — confirm and add test)
- [ ] Input shorter than 10 characters is rejected with a specific message: "Please describe your feature in at least a few sentences"
- [ ] A configurable blocklist of banned keywords/phrases is checked server-side (`CONTENT_BLOCKLIST` env var, newline-separated)
- [ ] All blocked requests are logged with structured context (userId, input hash — not full input — reason)
- [ ] Blocked requests return 400 with a user-facing message that does not reveal the specific rule that was triggered
- [ ] Context field (`context`) validated: max 1000 characters, same injection checks

**UX Expectations:**
- Client-side: character counter on the idea textarea, turns amber at 2700, red at 3000
- Client-side: "Generate" button disabled if textarea is empty or < 10 characters
- Error messages from server validation appear inline below the textarea, not as a toast

**Edge Cases:**
- Legitimate technical writing that contains phrases like "ignore the following" in a spec: false positive risk — blocklist should be narrow and regex-based, not substring-based
- Non-English input: the product accepts it; AI providers handle multilingual content
- Very long context field: truncate silently at 1000 characters rather than rejecting (UX is better than an error)

**Dependencies:** None

**API Considerations:**
- Validation runs before credit check — a blocked request does not consume credits
- Log blocked requests to the structured logging pipeline (FF-029)

**QA Notes:**
- Test: known injection pattern in input returns 400
- Test: input exactly 10 characters is accepted; 9 characters is rejected
- Test: input exactly 3000 characters is accepted; 3001 is rejected
- Test: context field > 1000 characters is silently truncated
- Test: blocked request does not deduct credits

---

### FF-012 · Generation Quality: System Prompt Versioning & A/B Testing

**Epic:** EP-03 — Generation Engine
**Title:** As a product team, I want to version and A/B test system prompts so that we can continuously improve generation quality without deploying new code for each prompt change.
**Priority:** Medium
**Story Points:** 5
**Sprint Allocation Category:** Feature
**Labels:** `ai` `backend` `infra`

**Business Objective:**
The current prompts are hardcoded in `/lib/prompts/index.ts`. Improving generation quality requires code deploys for every prompt change, which is slow and risky. Externalising prompts enables rapid iteration and controlled quality experiments.

**Acceptance Criteria:**
- [ ] Prompts are stored in a database table (`Prompt` model: `id`, `type`, `version`, `body`, `isActive`, `createdAt`)
- [ ] `buildPrompt()` function fetches the active prompt for each generation type from the database (with a fallback to hardcoded prompts if DB is unavailable)
- [ ] A/B test flag: each generation can be randomly assigned to a `promptVariant` (A or B); variant is logged in the generation record
- [ ] `GenerationRecord` schema includes `promptVersion` and `promptVariant` fields
- [ ] Admin UI stub (or direct DB seed script) allows creating new prompt versions
- [ ] Prompt cache: active prompts are cached in memory for 5 minutes to avoid DB calls on every generation

**UX Expectations:**
- No user-visible change — prompt versioning is entirely a backend concern

**Edge Cases:**
- DB unavailable: fall back to hardcoded prompts silently; log a warning
- A/B split: 50/50 by default; configurable via `AB_TEST_SPLIT` env var
- New prompt version deployed while requests are in flight: in-flight requests use the cached version; new requests use the new version after cache expiry

**Dependencies:** FF-004 (DB required), FF-028 (env var governance)

**API Considerations:**
- No new public API endpoints
- Internal: `buildPrompt(type, idea, context)` becomes async

**QA Notes:**
- Test: active prompt fetched from DB; hardcoded fallback when DB is down
- Test: `promptVersion` and `promptVariant` are stored in the generation record
- Test: cache prevents more than 1 DB read per 5-minute window for the same type

---

---

# EP-04 — Output Experience

> Copy, export, markdown rendering, regeneration, and output format improvements.

---

### FF-013 · Markdown Rendering in OutputViewer

**Epic:** EP-04 — Output Experience
**Title:** As a user, I want AI-generated outputs rendered as formatted markdown so that I can read structured documents naturally rather than as raw text.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `ui` `ai`

**Business Objective:**
All seven generation types produce markdown-formatted output (headers, bullet lists, code blocks, tables). The current `OutputViewer` component renders raw text in a `<pre>` block. This makes the output look unpolished and harder to read, reducing perceived quality and shareability.

**Acceptance Criteria:**
- [ ] `react-markdown` (or equivalent) installed and used in `OutputViewer` to render markdown
- [ ] GitHub Flavored Markdown (GFM) plugin enabled — supports tables and task list checkboxes
- [ ] Code blocks are syntax-highlighted using `rehype-highlight` or `react-syntax-highlighter`
- [ ] Heading hierarchy (`h1`–`h3`) is styled to match the FeatureForge design system tokens
- [ ] Tables are styled with borders and alternating row shading using design system tokens
- [ ] Task list items (GFM checkboxes) render as styled checkboxes (read-only)
- [ ] Rendered output is contained within a scrollable area — does not expand the page layout
- [ ] Raw markdown toggle: a "View raw" button switches between rendered and raw view

**UX Expectations:**
- Rendered view: clean, document-like appearance; headings use `--ff-text`, code blocks use `--ff-surface-alt`
- Raw view: monospace font, same `<pre>` behaviour as current implementation
- Toggle button: small, positioned top-right of the output area, labelled "View raw" / "View formatted"
- Inline code: styled with a pill background using `--ff-surface-alt`

**Edge Cases:**
- Provider returns HTML instead of markdown: render it as code block, not as raw HTML (security — no `dangerouslySetInnerHTML`)
- Very long output (Full Package): virtual scroll or pagination is out of scope; ensure rendered content does not OOM the browser tab
- Provider returns nothing: empty state already handled by OutputViewer — ensure it still triggers correctly after this change

**Dependencies:** None (can ship independently of DB migration)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: PRD output with headers, lists, and tables renders correctly
- Test: QA test cases with checkboxes render as styled checkboxes
- Test: "View raw" toggle switches to plaintext and back
- Test: XSS attempt in output (e.g., `<script>`) is not executed — `react-markdown` default behaviour

---

### FF-014 · Export to PDF and Markdown File

**Epic:** EP-04 — Output Experience
**Title:** As a user, I want to export generated output as a PDF or a .md file so that I can share specs with my team without requiring them to use FeatureForge.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Feature
**Labels:** `ui` `output`

**Business Objective:**
Copy-to-clipboard is the only current export mechanism. PMs need to share specs with engineering teams in Notion, Confluence, Jira, and email. PDF and markdown file exports dramatically expand the utility of every generation and reduce friction for team adoption.

**Acceptance Criteria:**
- [ ] "Export as Markdown" button downloads a `.md` file with the generation title as the filename (e.g., `prd-2026-05-26.md`)
- [ ] "Export as PDF" button generates a PDF of the rendered markdown content
- [ ] PDF export uses a print-friendly stylesheet (no dark backgrounds, adequate margins)
- [ ] Both exports are available in the `OutputViewer` action bar
- [ ] Filename for PDF: same pattern as markdown (e.g., `prd-2026-05-26.pdf`)
- [ ] Export buttons are keyboard accessible and have descriptive ARIA labels

**UX Expectations:**
- Action bar (below output): "Copy" | "Export .md" | "Export PDF" | "Regenerate" | "New generation"
- Export buttons: secondary style with an icon (download icon from FontAwesome)
- PDF export: triggers browser print dialog with a print-optimised view (using `window.print()` with a `@media print` stylesheet, or a library like `html2pdf.js`)
- No server-side PDF generation required for MVP — client-side is acceptable

**Edge Cases:**
- User exports before output is complete (if streaming — FF-009): export buttons disabled during streaming
- Very long output causes PDF to have many pages: acceptable; no pagination required
- Browser blocks the download (pop-up blocker): show a fallback link "Click here to download"

**Dependencies:** FF-013 (markdown rendering — PDF export should use rendered output, not raw text)

**API Considerations:**
- No API changes required — exports are client-side

**QA Notes:**
- Test: .md download contains correct markdown content and filename
- Test: PDF download triggers print dialog or saves file
- Test: export buttons disabled during streaming (once FF-009 is complete)
- Test: ARIA labels present on all export buttons

---

### FF-015 · Copy-to-Clipboard with Format Options

**Epic:** EP-04 — Output Experience
**Title:** As a user, I want to copy my generated output in different formats (markdown, plain text, or HTML) so that I can paste it directly into Notion, Confluence, or a text editor without reformatting.
**Priority:** Medium
**Story Points:** 2
**Sprint Allocation Category:** Feature
**Labels:** `ui` `output`

**Business Objective:**
The current "Copy" button copies raw markdown, which pastes as plaintext in most tools. Notion, Google Docs, and Confluence all accept rich-text paste. Providing format options removes the reformatting step that PMs currently do manually.

**Acceptance Criteria:**
- [ ] "Copy" button becomes a split button: primary action copies markdown; dropdown offers "Copy as plain text" and "Copy as rich text (HTML)"
- [ ] Rich text copy uses the `ClipboardItem` API with `text/html` MIME type
- [ ] Plain text copy strips all markdown formatting (bold, headers, bullets become indented text)
- [ ] Copy success state: button label changes to "Copied!" for 2 seconds, then reverts
- [ ] If `ClipboardItem` API is not available (Firefox <87): rich text option is hidden; user sees a tooltip explaining why

**UX Expectations:**
- Split button: main button + small chevron dropdown
- Dropdown: "Markdown" (default, checked), "Plain text", "Rich text"
- Keyboard: dropdown accessible via arrow keys

**Edge Cases:**
- Clipboard API denied (user blocked permissions): show a textarea with the content pre-selected for manual copy
- Streaming in progress: copy button disabled until generation completes

**Dependencies:** FF-013 (HTML copy requires rendered HTML, not raw markdown)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: markdown copy pastes correctly into a plain text editor
- Test: rich text copy pastes with formatting into a rich text area (jsdom test or manual)
- Test: "Copied!" state reverts after 2 seconds
- Test: graceful degradation when ClipboardItem unavailable

---

### FF-016 · Regenerate with Modified Input

**Epic:** EP-04 — Output Experience
**Title:** As a user, I want to regenerate output with a modified version of my original input so that I can iterate on my spec without starting from scratch.
**Priority:** Medium
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `ui` `ai` `credits`

**Business Objective:**
Currently, "New generation" clears the form entirely. Users who want to tweak their idea and regenerate must retype everything. A "Regenerate with edits" flow preserves the original input, allows modification, and re-runs the same generation type — reducing friction for iterative spec work.

**Acceptance Criteria:**
- [ ] "Regenerate" button in the `OutputViewer` action bar populates the `GenerateForm` with the original input and generation type
- [ ] User can modify the idea text, context, provider, or generation type before re-running
- [ ] Re-running costs the same credits as the original generation (shown in the form)
- [ ] Original output is preserved in a "Previous output" collapsible panel below the new output
- [ ] If the user has insufficient credits, the Regenerate button is disabled with a tooltip explaining why

**UX Expectations:**
- "Regenerate" button: secondary style in action bar, with a "refresh" icon
- On click: form scrolls into view with original values pre-populated; output area remains visible below
- Previous output panel: collapsed by default with a "Show previous output" toggle

**Edge Cases:**
- User clicks Regenerate with 0 credits: disabled state, not a server-side rejection
- User changes generation type (e.g., from PRD to Full Package): credit cost updates dynamically in the form
- Multiple regeneration cycles: only the immediately previous output is shown in the collapsible panel (not the full history — that is FF-020)

**Dependencies:** FF-006 (real-time credit balance), FF-013 (output rendering)

**API Considerations:**
- No new API endpoints — uses existing `POST /api/generate`

**QA Notes:**
- Test: Regenerate pre-populates form with original values
- Test: credit cost reflects the generation type selected
- Test: previous output panel shows the last output after regeneration
- Test: insufficient credits disables button without server call

---

---

# EP-05 — History & Persistence

> Database-backed generation history, search, filtering, and re-use of past outputs.

---

### FF-017 · Generation History Persistence (DB Write)

**Epic:** EP-05 — History & Persistence
**Title:** As a user, I want every generation I run to be saved to my account so that I can access past specs without needing to copy them immediately.
**Priority:** Critical
**Story Points:** 5
**Sprint Allocation Category:** Feature
**Labels:** `backend` `database` `history`

**Business Objective:**
The History page currently shows an empty state with a placeholder message. Users who generate a spec and close the tab lose it permanently. History persistence is a foundational product feature that enables re-use, search, and team sharing. It is also required for FinOps reporting (FF-022).

**Acceptance Criteria:**
- [ ] `GenerationRecord` model in Prisma schema: `id`, `userId`, `type`, `provider`, `idea`, `output`, `creditsUsed`, `promptVersion`, `tokensIn`, `tokensOut`, `durationMs`, `createdAt`
- [ ] Every successful generation writes a `GenerationRecord` to the database (in the same transaction as the credit deduction)
- [ ] `GET /api/history` returns paginated generation records for the current user (20 per page, cursor-based pagination)
- [ ] History page renders the list of past generations with: type badge, idea summary (truncated to 100 chars), date, provider, credits used
- [ ] Each history item links to a detail view at `/history/[id]` that shows the full output rendered as markdown
- [ ] Demo users' generations are not persisted (they have no DB-backed user record)

**UX Expectations:**
- History list: card-based layout, most recent first
- Each card: generation type coloured badge, truncated idea text, relative timestamp ("2 hours ago"), provider pill, credit cost
- Empty state (new user): illustration + "Your generations will appear here" — keep existing empty state design
- Loading state: skeleton cards (3–5) while fetching

**Edge Cases:**
- Generation succeeds but DB write fails: credit is deducted but no history record — log the failure; do not roll back the credit (AI cost already incurred)
- User has hundreds of history records: pagination must work correctly; test with 100+ records
- Output is very large (Full Package): store the full output; no truncation in the DB record

**Dependencies:** FF-004 (DB infrastructure), FF-013 (markdown rendering for detail view)

**API Considerations:**
- `GET /api/history?cursor=<id>&limit=20` — response: `{ records: GenerationRecord[], nextCursor: string | null }`
- `GET /api/history/[id]` — response: `GenerationRecord` (or 404 if not found / not owned by user)

**QA Notes:**
- Test: generate a spec, navigate to History, confirm it appears
- Test: pagination returns correct records and nextCursor
- Test: accessing another user's history record returns 404
- Test: demo user generation does not appear in history
- Test: history detail page renders full output as markdown

---

### FF-018 · History Search & Filter

**Epic:** EP-05 — History & Persistence
**Title:** As a user, I want to search and filter my generation history by type, date, or keyword so that I can quickly find a spec I generated previously.
**Priority:** Medium
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `ui` `backend` `history`

**Business Objective:**
Once history persistence is live (FF-017), users will accumulate records quickly. A PM running 3–5 generations per day will have 60–100 records within a month. Without search, the History page becomes a scrolling wall that users stop engaging with.

**Acceptance Criteria:**
- [ ] Search input filters history by keyword match on the `idea` field (server-side, not client-side)
- [ ] Filter by generation type: dropdown with all 7 types + "All" option
- [ ] Filter by date range: "Last 7 days", "Last 30 days", "All time"
- [ ] Filters and search are combinable (AND logic)
- [ ] URL reflects current filter state (`?q=keyword&type=prd&range=7d`) — shareable and browser-back-compatible
- [ ] Results count shown ("12 results for 'checkout flow'")

**UX Expectations:**
- Filter bar above the history list: search input (left), type dropdown (middle), date range dropdown (right)
- Empty filtered state: "No results for your search — clear filters to see all history"
- Debounced search input (300ms) to avoid excessive API calls

**Edge Cases:**
- Search term with special regex characters: sanitise before DB query
- All filters active with no results: clear filters CTA visible
- Very long search query (>200 chars): truncate to 200 chars before sending to API

**Dependencies:** FF-017 (history persistence required)

**API Considerations:**
- `GET /api/history?q=<keyword>&type=<type>&range=<range>&cursor=<id>` — extend existing endpoint

**QA Notes:**
- Test: search by keyword returns matching records only
- Test: filter by type "PRD" returns only PRD records
- Test: combined search + type filter works correctly
- Test: URL state reflects filters after applying them

---

### FF-019 · History Record Deletion

**Epic:** EP-05 — History & Persistence
**Title:** As a user, I want to delete individual generation history records so that I can keep my history clean and remove sensitive specs.
**Priority:** Low
**Story Points:** 2
**Sprint Allocation Category:** Feature
**Labels:** `ui` `backend` `history`

**Business Objective:**
Users may generate specs containing sensitive product information (unreleased features, competitive analysis) that they do not want stored indefinitely. Providing deletion capability reduces data retention risk and gives users control over their data — a baseline GDPR requirement.

**Acceptance Criteria:**
- [ ] Each history card has a "Delete" icon button (trash icon)
- [ ] Clicking delete shows a confirmation dialog: "Delete this generation? This cannot be undone."
- [ ] Confirmed deletion calls `DELETE /api/history/[id]` and removes the record from the list without a page reload
- [ ] Users can only delete their own records (server-side ownership check)
- [ ] Deleted records are hard-deleted (not soft-deleted) — no recovery mechanism for MVP

**UX Expectations:**
- Delete button: visible on hover/focus of the history card, icon-only with ARIA label "Delete generation"
- Confirmation dialog: uses the existing Modal component pattern
- After deletion: the card animates out (fade + collapse); count updates

**Edge Cases:**
- User double-clicks delete: second request returns 404; UI handles gracefully (already removed)
- Deleting a record that is currently open in a detail view tab: the detail view shows a "This record no longer exists" message

**Dependencies:** FF-017 (history persistence)

**API Considerations:**
- `DELETE /api/history/[id]` — returns 204 on success, 404 if not found or not owned

**QA Notes:**
- Test: delete button removes record from UI without reload
- Test: attempting to delete another user's record returns 404
- Test: delete confirmation dialog is keyboard navigable (Tab, Enter, Escape)

---

---

# EP-06 — Observability & FinOps

> Token tracking, cost per generation, usage dashboards, structured logging, and AI cost governance.

---

### FF-020 · Per-Generation Token & Cost Tracking

**Epic:** EP-06 — Observability & FinOps
**Title:** As a platform operator, I want to track token consumption and estimated API cost for every generation so that I can understand the unit economics of each generation type.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `finops` `backend` `database`

**Business Objective:**
AI API costs are the primary variable cost of the business. Currently, `tokensIn` and `tokensOut` are returned in the API response but not stored persistently. Without cost tracking, the operator cannot calculate margins per plan, identify expensive generation types, or detect anomalous usage patterns (runaway costs).

**Acceptance Criteria:**
- [ ] `GenerationRecord` schema includes `tokensIn`, `tokensOut`, `durationMs`, `estimatedCostUsd` (computed at write time)
- [ ] Cost estimation uses configurable per-token pricing from env vars (`ANTHROPIC_COST_PER_1K_IN`, `ANTHROPIC_COST_PER_1K_OUT`, etc. — one pair per provider)
- [ ] `GET /api/admin/metrics` (admin-only) returns: total generations, total tokens, total estimated cost, cost breakdown by provider and generation type
- [ ] Estimated cost is stored in the `GenerationRecord` at write time (not computed dynamically) so historical records reflect pricing at time of generation
- [ ] Usage page for regular users: shows total tokens used and an approximate "value generated" metric (tokens used * context value — simplified display)

**UX Expectations:**
- Admin metrics endpoint: JSON only for MVP; no admin UI required in this story
- User usage page: add a "Tokens used this period" metric card alongside credits

**Edge Cases:**
- Provider does not return token counts (Gemini edge case): store 0 and log a warning — do not fail the generation
- Pricing env vars not set: default to 0 cost (log a warning during startup)
- Extremely long generation (Full Package with very long context): cost could be significant; no cap required for MVP — flag for future rate limiting

**Dependencies:** FF-004 (DB), FF-017 (GenerationRecord schema)

**API Considerations:**
- `GET /api/admin/metrics` — admin role required (FF-003)
- No changes to public generation API response

**QA Notes:**
- Test: generation record contains correct tokensIn, tokensOut, estimatedCostUsd
- Test: cost calculated correctly for each provider using configured pricing
- Test: admin metrics endpoint returns 403 for non-admin users
- Test: token count of 0 stored gracefully when provider omits it

---

### FF-021 · User-Facing Usage Dashboard

**Epic:** EP-06 — Observability & FinOps
**Title:** As a user, I want a usage dashboard showing my generation history statistics so that I can understand how I am using my credits and which generation types I use most.
**Priority:** Medium
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `ui` `finops` `backend`

**Business Objective:**
The current Usage page shows only credit balance and a static cost table. For power users and teams, understanding usage patterns (which types they use most, how many generations per week) is valuable for justifying the subscription cost and optimising their workflow.

**Acceptance Criteria:**
- [ ] Usage page shows: total generations this period, generations by type (bar chart or table), average generation duration, most-used provider
- [ ] Data is scoped to the current billing period (since last `resetAt`)
- [ ] Chart library: use a lightweight option (e.g., `recharts` — already commonly available in Next.js ecosystems) or a CSS-only bar chart for MVP
- [ ] Data is fetched from `GET /api/usage/stats` which aggregates the user's `GenerationRecord` rows
- [ ] Empty state: "No generations yet this period — start generating to see your stats"

**UX Expectations:**
- Stats section above the existing credit cost table
- Generation by type: horizontal bar chart or simple table with type label, count, and percentage
- Cards: total generations, credits used, average response time (ms)

**Edge Cases:**
- User has 0 generations this period: empty state shown, not a chart with all zeros
- Billing period not yet set (free user): scope stats to "all time" with a label clarifying this

**Dependencies:** FF-017 (GenerationRecord DB), FF-007 (billing cycle / resetAt field)

**API Considerations:**
- `GET /api/usage/stats` — response: `{ totalGenerations, byType: {type, count}[], avgDurationMs, mostUsedProvider, periodStart, periodEnd }`

**QA Notes:**
- Test: stats update after each generation
- Test: stats scoped correctly to current billing period
- Test: empty state renders when no generations exist

---

### FF-022 · Rate Limiting Per User

**Epic:** EP-06 — Observability & FinOps
**Title:** As a platform operator, I want per-user API rate limiting on the generation endpoint so that a single user cannot exhaust AI API quotas or destabilise the service for others.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Feature
**Labels:** `infra` `backend` `finops`

**Business Objective:**
Without rate limiting, a user (or a compromised account) could make hundreds of generation requests in a short period, consuming significant AI API budget and degrading performance for other users. Rate limiting protects the business economically and ensures service fairness.

**Acceptance Criteria:**
- [ ] Rate limit: 10 generation requests per user per minute (configurable via `RATE_LIMIT_GENERATIONS_PER_MINUTE` env var)
- [ ] Rate limit implemented using a sliding window algorithm (Redis preferred; in-memory Map acceptable for MVP with a clear upgrade path note in code)
- [ ] Rate-limited requests return HTTP 429 with a `Retry-After` header indicating seconds until the window resets
- [ ] Rate limit response body: `{ error: "Too many requests. Please wait X seconds before generating again." }`
- [ ] Rate limit does not deduct credits from the user
- [ ] Admin users are exempt from rate limiting (configurable: `RATE_LIMIT_EXEMPT_ROLES=admin`)
- [ ] Rate limit events are logged with structured context

**UX Expectations:**
- On 429 response: show an inline error below the generate button with the wait time ("Please wait 23 seconds before generating again")
- Countdown timer in the error message: counts down in real-time

**Edge Cases:**
- User exhausts credits and is also rate-limited simultaneously: credit exhaustion message takes priority (checked first)
- Rate limit window reset during a generation: generation that was in-flight completes normally
- Redis unavailable (if using Redis): fall back to in-memory rate limiter with a warning log — do not block all generations

**Dependencies:** FF-028 (env var governance for config)

**API Considerations:**
- Middleware or route-level check in `POST /api/generate`
- `Retry-After` header on 429 responses

**QA Notes:**
- Test: 11th request within 60 seconds returns 429
- Test: `Retry-After` header is present and accurate
- Test: credits not deducted on rate-limited request
- Test: after window resets, generation succeeds

---

---

# EP-07 — Infrastructure & Tech Debt

> Database setup, automated testing, CI/CD pipeline, structured logging, and deployment configuration.

---

### FF-023 · Landing Page — Conversion-Optimised Marketing Page

**Epic:** EP-07 (Design Debt)
**Title:** As a potential user visiting FeatureForge for the first time, I want a clear, compelling landing page so that I understand what the product does and am motivated to sign up.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Design Debt
**Labels:** `ui` `marketing`

**Business Objective:**
The current `page.tsx` (root) renders only a sign-in form. There is no product explanation, feature list, pricing information, or social proof. A PM or founder who lands on the page has no context for why they should sign up. This directly limits top-of-funnel conversion.

**Acceptance Criteria:**
- [ ] Landing page sections: Hero (headline + sub-headline + CTAs), How It Works (3 steps), Generation Types (7 cards with descriptions), Pricing (4 plan cards with CTA buttons), FAQ (5–8 questions), Footer
- [ ] "Sign in with Google" and "Try Demo" CTAs are prominent in the Hero section
- [ ] Pricing section shows plan names, credit amounts, prices, and feature lists
- [ ] Page is responsive: mobile-first, works at 375px and above
- [ ] Page load performance: Lighthouse score ≥ 85 on mobile (performance)
- [ ] All text passes WCAG AA contrast ratio requirements
- [ ] Sign-in form moves to a dedicated modal triggered by the CTA, not rendered inline

**UX Expectations:**
- Hero: large headline, short sub-headline, two CTAs (primary: "Start for free", secondary: "Try demo")
- How it works: numbered steps — "1. Describe your feature" / "2. Choose output type" / "3. Get instant specs"
- Pricing cards: highlight the Pro plan as "Most popular"
- Responsive nav: hamburger menu on mobile

**Edge Cases:**
- Authenticated user visits `/`: redirect to `/dashboard` (already implemented — confirm this still works after landing page redesign)
- User clicks pricing CTA while not signed in: redirect to sign-in, then to checkout after sign-in (deep link)

**Dependencies:** FF-005 (Stripe pricing must be live for accurate pricing page)

**API Considerations:**
- No API changes required
- Pricing data should be sourced from `PLAN_CREDITS` and configured price constants, not hardcoded

**QA Notes:**
- Test: authenticated user redirected to dashboard from `/`
- Test: "Try demo" button signs in as demo user
- Test: all pricing CTA buttons link to correct sign-in or checkout flow
- Test: page passes Lighthouse accessibility audit (no critical violations)

---

### FF-024 · Dark Mode Polish & Design Token Audit

**Epic:** EP-07 (Design Debt)
**Title:** As a user, I want dark mode to look polished and consistent across all pages so that I can use FeatureForge comfortably in low-light environments.
**Priority:** Low
**Story Points:** 3
**Sprint Allocation Category:** Design Debt
**Labels:** `ui` `design-debt`

**Business Objective:**
Dark mode is scaffolded via Tailwind's `dark:` variant and the `ThemeToggle` component, but dark-mode values for several components are inconsistent or missing (hardcoded hex values exist in some components). Before launch, a design token audit ensures the product looks intentional and professional in both modes.

**Acceptance Criteria:**
- [ ] Full audit of all `.tsx` files for hardcoded hex values and `px` magic numbers — replace with design system tokens
- [ ] All `dark:` variants checked for missing or broken styles: buttons, cards, modals, forms, badges, tables
- [ ] `ThemeToggle` persists the chosen theme across page navigations and browser sessions (localStorage)
- [ ] System preference (`prefers-color-scheme`) respected on first visit before any user preference is set
- [ ] No white flicker on dark mode page load (anti-flash script in `<head>`)

**UX Expectations:**
- Consistent surface colours across all pages in both modes
- No text that is unreadable in dark mode (check `--ff-text-muted` on dark backgrounds)

**Edge Cases:**
- User changes system preference while the app is open: app does not change (user preference takes priority)
- User clears localStorage: app reverts to system preference

**Dependencies:** None

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: toggle dark mode, navigate to all pages, confirm consistent appearance
- Test: theme persists across page reload
- Test: first visit respects system preference

---

### FF-025 · Accessibility Audit & WCAG AA Remediation

**Epic:** EP-07 (Design Debt)
**Title:** As any user, I want FeatureForge to be fully keyboard-navigable and screen-reader compatible so that the product is accessible to users with disabilities.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Design Debt
**Labels:** `accessibility` `design-debt`

**Business Objective:**
The Engineering Constitution §5 mandates WCAG AA compliance. The current codebase has no documented accessibility audit. Pre-launch accessibility remediation is significantly cheaper than post-launch. For B2B customers (especially enterprise and education), accessibility is often a procurement requirement.

**Acceptance Criteria:**
- [ ] Run `axe-core` automated audit on all 6 pages; zero critical violations before release
- [ ] All interactive elements reachable and operable via keyboard (Tab, Enter, Space, Escape, arrow keys)
- [ ] All icon-only buttons have `aria-label` attributes
- [ ] Form inputs have associated `<label>` elements or `aria-label`
- [ ] Dynamic content changes (generation result, credit update, toast) announced to screen readers via `aria-live` regions
- [ ] Focus management: after modal opens, focus moves to the modal; after modal closes, focus returns to trigger
- [ ] Colour contrast ratio ≥ 4.5:1 for all normal text; ≥ 3:1 for large text

**UX Expectations:**
- No visual changes required if contrast and focus indicators are already sufficient
- Focus ring visible on all interactive elements (do not remove the default outline without replacing it)

**Edge Cases:**
- PrimeReact components may have their own accessibility issues: document any PrimeReact-specific findings as separate tickets
- Streaming output (FF-009): `aria-live="polite"` region announces completion, not every chunk

**Dependencies:** FF-013 (markdown renderer must not introduce inaccessible elements)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: axe-core audit on all pages shows zero critical violations
- Test: full keyboard navigation of generate form and output viewer
- Test: screen reader announces generation result when it appears
- Test: modal focus management works correctly on open and close

---

### FF-026 · Bug — Demo User Credit Balance Resets on Server Restart

**Epic:** EP-07 (Bug)
**Title:** As a demo user, I should not see my credit balance fluctuate unpredictably, so that the demo experience accurately represents the product.
**Priority:** High
**Story Points:** 1
**Sprint Allocation Category:** Bug
**Labels:** `auth` `credits` `bug`

**Business Objective:**
The in-memory credit store resets whenever the Next.js development server restarts (including Vercel cold starts in production). Demo users who have used some credits will see their balance reset to 10, which makes the credit system appear broken during sales demos and investor evaluations.

**Acceptance Criteria:**
- [ ] Demo user credit balance is stored in a server-side session cookie (not server memory) as a stop-gap until FF-004 (DB) is complete
- [ ] Balance persists across server restarts within the same browser session
- [ ] Balance resets when the demo session expires (correct behaviour)
- [ ] Note in code: "Replace with DB-backed balance when FF-004 ships"

**UX Expectations:**
- No visible change — credit balance should simply be stable

**Edge Cases:**
- User clears cookies: balance resets to 10 — acceptable; document as known behaviour

**Dependencies:** None (stop-gap fix; superseded by FF-004)

**API Considerations:**
- Session cookie: signed, HttpOnly, SameSite=Strict

**QA Notes:**
- Test: demo user uses 2 credits, server restarted (simulated), balance remains at 8
- Test: new demo session starts at 10

---

### FF-027 · Bug — Generate Page Credits Not Refreshed After Navigation

**Epic:** EP-07 (Bug)
**Title:** As a user, I want my credit balance on the Generate page to reflect my actual remaining credits after navigating away and returning so that I am not shown stale data.
**Priority:** Medium
**Story Points:** 1
**Sprint Allocation Category:** Bug
**Labels:** `ui` `credits` `bug`

**Business Objective:**
The `GenerateForm` receives `creditsRemaining` as a prop from the parent page, which fetches balance on mount. If a user generates a spec, navigates to History, then returns to Generate, the balance shown can be stale (showing pre-generation credits because the component is remounted from Next.js router cache).

**Acceptance Criteria:**
- [ ] Credit balance is re-fetched on every mount of the Generate page, not only on session load
- [ ] Next.js `router.refresh()` called after a successful generation to invalidate the server component cache
- [ ] `creditsRemaining` prop passed to `GenerateForm` always reflects the most recently fetched balance

**UX Expectations:**
- Balance updates without a full page reload — optimistic update is acceptable

**Edge Cases:**
- Network request to `/api/credits` fails on remount: show last known value with a staleness indicator

**Dependencies:** None

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: generate a spec, navigate away, return to Generate, confirm updated balance
- Test: stale cache scenario — balance shown after navigation matches post-generation value

---

### FF-028 · Environment Variable Governance & .env.example

**Epic:** EP-07 (Tech Debt)
**Title:** As a developer onboarding to FeatureForge, I want a complete `.env.example` file and documented environment variables so that I can configure the app without reading the source code.
**Priority:** High
**Story Points:** 2
**Sprint Allocation Category:** Tech Debt
**Labels:** `infra` `developer-experience`

**Business Objective:**
There is no `.env.example` file in the repository. Multiple environment variables are referenced in the code (`ANTHROPIC_API_KEY`, `NEXTAUTH_SECRET`, `GOOGLE_CLIENT_ID`, `DATABASE_URL`, `STRIPE_SECRET_KEY`, etc.) with no central documentation. This makes onboarding slow and deployment error-prone.

**Acceptance Criteria:**
- [ ] `.env.example` created at repository root with every environment variable used in the codebase
- [ ] Each variable has an inline comment explaining its purpose, whether it is required, and the default/example value
- [ ] Variables are grouped by concern: Auth, AI Providers, Database, Stripe, Feature Flags, Rate Limiting, Pricing
- [ ] Startup validation: a `validateEnv()` function in `/lib/config/env.ts` checks required variables on boot; throws a descriptive error if any are missing in non-development environments
- [ ] `.env` and `.env.local` are in `.gitignore` (confirm — do not commit secrets)
- [ ] `README.md` updated with a "Getting started" section referencing `.env.example`

**UX Expectations:**
- Developer experience: running `cp .env.example .env.local` is the first setup step
- Startup validation error message: "Missing required environment variable: NEXTAUTH_SECRET. See .env.example for configuration guidance."

**Edge Cases:**
- Development environment: missing non-critical vars (e.g., Stripe keys) log a warning but do not crash the server
- Production environment: any missing required var causes an immediate startup failure with a clear error

**Dependencies:** None (foundational — should be done early)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: start server with a required var missing in production mode; confirm descriptive error
- Test: `.env.example` contains all vars referenced in the codebase (script to cross-check)
- Test: `.env` not tracked by git

---

### FF-029 · Structured Logging with Pino

**Epic:** EP-07 (Tech Debt)
**Title:** As a platform operator, I want structured JSON logging across all API routes so that I can query and alert on production errors, performance anomalies, and usage patterns.
**Priority:** High
**Story Points:** 3
**Sprint Allocation Category:** Tech Debt
**Labels:** `infra` `observability`

**Business Objective:**
The Engineering Constitution §7 mandates structured logging. Currently, all logging is bare `console.log()` calls with no consistent structure. In production, this makes it impossible to filter logs by userId, generation type, or error code — which means debugging production issues requires guesswork.

**Acceptance Criteria:**
- [ ] `pino` and `pino-pretty` installed
- [ ] A logger singleton at `/lib/logger.ts` is used across all API routes instead of `console.log`
- [ ] All existing `console.log` and `console.error` calls in API routes replaced with structured logger calls
- [ ] Log fields standardised: `{ level, timestamp, requestId, userId, route, durationMs, ...context }`
- [ ] Error logs include: `{ error: { message, stack, code } }` — never raw `Error` objects
- [ ] `requestId` generated per-request (UUID) and propagated through the call stack via a request context
- [ ] Log level configurable via `LOG_LEVEL` env var (default: `info`; development: `debug`)
- [ ] Sensitive fields are never logged: `idea` content, `output` content, API keys

**UX Expectations:**
- No user-visible change

**Edge Cases:**
- Logger initialisation fails: fall back to `console.error` with a startup warning — do not crash the server
- Very verbose debug logging in production: `LOG_LEVEL=info` default prevents this

**Dependencies:** FF-028 (env var governance for `LOG_LEVEL`)

**API Considerations:**
- No API response changes

**QA Notes:**
- Test: generation route logs structured output on success and failure
- Test: sensitive fields (idea, output, API keys) not present in any log output
- Test: `LOG_LEVEL=debug` in development shows verbose logs; `info` in production does not

---

### FF-030 · Automated Test Suite — Unit & Integration Tests

**Epic:** EP-07 (Tech Debt)
**Title:** As the engineering team, I want a test suite covering critical business logic so that we can ship changes confidently without manual regression testing.
**Priority:** High
**Story Points:** 8
**Sprint Allocation Category:** Tech Debt
**Labels:** `testing` `infra`

**Business Objective:**
The Engineering Constitution §6 mandates unit and integration tests. Currently there are zero automated tests. The credit system, generation routing, and authentication are all business-critical code paths with no test coverage. Every deploy is a manual regression risk.

**Acceptance Criteria:**
- [ ] `vitest` (or `jest`) installed and configured with TypeScript support
- [ ] `@testing-library/react` installed for component tests
- [ ] Unit tests for `/lib/credits/index.ts`: `getOrCreateBalance`, `deductCredits`, `addCredits`, `setPlan` — all edge cases covered
- [ ] Unit tests for `/lib/ai/index.ts`: provider routing, fallback logic (once FF-010 ships), model tier selection
- [ ] Unit tests for `/lib/prompts/index.ts`: `buildPrompt` returns non-empty string for all 7 generation types and all 3 providers
- [ ] Integration tests for `/api/generate` route: valid request succeeds, insufficient credits returns 402, invalid type returns 400, unauthenticated returns 401
- [ ] Integration tests for `/api/credits` route: GET returns correct balance
- [ ] Integration tests for `/api/billing/webhook` (once FF-005 ships): valid Stripe event updates plan, invalid signature returns 400
- [ ] Test coverage threshold: ≥ 70% line coverage on `/lib` and `/api` directories
- [ ] `npm test` runs all tests; `npm run test:watch` for development

**UX Expectations:**
- No user-visible change

**Edge Cases:**
- Tests must not make real AI API calls — mock all provider SDK calls
- Tests must not connect to a real database — use an in-memory SQLite database or mock the Prisma client
- Tests must not make real Stripe API calls — use Stripe's test mock or jest mocks

**Dependencies:** FF-028 (env var governance — test environment needs its own `.env.test`)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test suite itself is the QA artefact for this story
- Confirm `npm test` passes in CI before story is done
- Confirm coverage report generated and threshold enforced

---

### FF-031 · Error Boundary & Global Error Handling

**Epic:** EP-07 (Tech Debt)
**Title:** As a user, I want unhandled errors to show a clear, recoverable error page rather than a blank screen so that I am never left stranded.
**Priority:** Medium
**Story Points:** 3
**Sprint Allocation Category:** Tech Debt
**Labels:** `infra` `ui` `observability`

**Business Objective:**
The Engineering Constitution §7 mandates Error Boundaries. Currently, an unhandled React error in any component will crash the entire page. There is no global error boundary, no `error.tsx` in the App Router, and no structured error logging on the client side.

**Acceptance Criteria:**
- [ ] Next.js `error.tsx` created at `src/app/error.tsx` — renders a user-friendly error page with a "Try again" button and a "Go to dashboard" link
- [ ] Next.js `not-found.tsx` created at `src/app/not-found.tsx` — renders a "Page not found" state
- [ ] A React `ErrorBoundary` component in `src/components/errors/ErrorBoundary.tsx` wraps the main content area of `AppShell`
- [ ] Client-side errors caught by the ErrorBoundary are logged with structured context (userId, route, error message, stack) to a logging endpoint `POST /api/log/client-error`
- [ ] `POST /api/log/client-error` validates the payload and writes to the server logger — it does not return sensitive information
- [ ] Error page does not expose stack traces to the user in production

**UX Expectations:**
- Error page: branded, calm design; "Something went wrong" heading; "Try again" and "Go to dashboard" buttons
- Not-found page: "This page doesn't exist" with a "Go to dashboard" link
- ErrorBoundary recovery: "Try again" button calls `reset()` to attempt remount

**Edge Cases:**
- Error occurs during streaming output (FF-009): ErrorBoundary should not trigger for API errors — those are handled inline. Only catch synchronous React render errors.
- Client error logger endpoint itself fails: log to `console.error` as fallback — do not create an infinite error loop

**Dependencies:** FF-029 (structured logging must be set up before client error endpoint can write structured logs)

**API Considerations:**
- `POST /api/log/client-error` — body: `{ message, stack, route, userId }` — rate limited (max 10/min per user) to prevent abuse

**QA Notes:**
- Test: throw an error in a child component; confirm ErrorBoundary renders error UI
- Test: `error.tsx` renders correctly for unhandled route errors
- Test: `not-found.tsx` renders for 404 routes
- Test: client error is sent to `/api/log/client-error` and logged server-side
- Test: stack trace not exposed in production error page

---

### FF-032 · CI/CD Pipeline — GitHub Actions

**Epic:** EP-07 (Tech Debt)
**Title:** As the engineering team, I want an automated CI/CD pipeline so that every pull request is validated and deployments to staging and production are reliable and repeatable.
**Priority:** High
**Story Points:** 5
**Sprint Allocation Category:** Tech Debt
**Labels:** `infra` `cicd`

**Business Objective:**
The Architecture Blueprint §11 and Engineering Constitution §8 mandate a CI pipeline. Currently, all deployments are manual. There is no type-checking, linting, or test execution in CI. A single typo or missing environment variable can silently break production — and there is no automated rollback trigger.

**Acceptance Criteria:**
- [ ] GitHub Actions workflow at `.github/workflows/ci.yml` runs on every PR and push to `main`
- [ ] CI steps: `npm ci` → `npx tsc --noEmit` (type check) → `npm run lint` → `npm test` → build
- [ ] Deployment workflow at `.github/workflows/deploy.yml` runs on merge to `main` (staging) and on release tag (production)
- [ ] Deployment to Vercel via `vercel` CLI or Vercel GitHub integration with environment-specific env vars
- [ ] Database migration (`prisma migrate deploy`) runs automatically before deployment in staging and production
- [ ] CI fails fast: if type check fails, lint and tests are skipped
- [ ] Branch protection rule on `main`: requires CI to pass before merge (documented in `REPOSITORY_GOVERNANCE.md`)
- [ ] Secrets (`ANTHROPIC_API_KEY`, `STRIPE_SECRET_KEY`, etc.) stored in GitHub repository secrets — never in the workflow YAML

**UX Expectations:**
- Developer experience: PR shows green/red CI status checks within 3 minutes
- Failed CI shows clear error output in the GitHub Actions log

**Edge Cases:**
- First deployment to a new environment with no database: migration must create tables cleanly
- Migration fails: deployment is aborted; previous version remains active

**Dependencies:** FF-028 (env var governance), FF-030 (test suite must exist for CI to run)

**API Considerations:**
- No API changes required

**QA Notes:**
- Test: open a PR with a TypeScript error; confirm CI fails at type-check step
- Test: open a PR with a failing test; confirm CI fails at test step
- Test: successful CI on a PR shows all green checks
- Test: merge to main triggers staging deployment

---

### FF-033 · Prisma Schema — Full Data Model & Migrations

**Epic:** EP-07 (Tech Debt)
**Title:** As the engineering team, I want a complete, production-ready Prisma schema covering all data models so that the database is structured correctly from the start and does not require breaking migrations post-launch.
**Priority:** Critical
**Story Points:** 5
**Sprint Allocation Category:** Tech Debt
**Labels:** `database` `backend` `infra`

**Business Objective:**
FF-004 establishes the credit model. But the full data model (Users, GenerationRecords, Prompts, Subscriptions) needs to be designed coherently upfront to avoid costly breaking migrations after paying customers are using the product. This story defines and seeds the complete schema.

**Acceptance Criteria:**
- [ ] Prisma schema at `prisma/schema.prisma` with models: `User`, `CreditBalance`, `GenerationRecord`, `Prompt`, `Subscription`, `AuditLog`
- [ ] `User` model: `id` (cuid), `email` (unique), `name`, `image`, `createdAt`, `updatedAt`
- [ ] `CreditBalance` model: linked to `User` 1:1; fields per FF-004
- [ ] `GenerationRecord` model: linked to `User` 1:N; fields per FF-017 and FF-020
- [ ] `Prompt` model: `id`, `type`, `version`, `body`, `isActive`, `createdAt` (for FF-012)
- [ ] `Subscription` model: `id`, `userId`, `stripeCustomerId`, `stripeSubscriptionId`, `plan`, `status`, `currentPeriodStart`, `currentPeriodEnd`
- [ ] `AuditLog` model: `id`, `userId`, `action`, `metadata` (JSON), `createdAt` — for security-sensitive events
- [ ] All models have correct indexes for common query patterns (userId, createdAt, email)
- [ ] Seed script (`prisma/seed.ts`) creates the default prompt set for all 7 generation types
- [ ] Initial migration is clean and idempotent

**UX Expectations:**
- No user-visible change

**Edge Cases:**
- Schema change after initial migration: use Prisma's migration system — never modify existing migrations
- `Subscription` model must handle users with no subscription (nullable foreign key)

**Dependencies:** FF-004 (Prisma setup), FF-005 (Stripe — `stripeCustomerId` in Subscription model)

**API Considerations:**
- No public API changes
- Internal: all existing DB access must use the centralised Prisma client at `/lib/db.ts`

**QA Notes:**
- Test: seed script runs without error on a fresh database
- Test: all models created correctly by the migration
- Test: unique constraint on `User.email` enforced
- Test: `GenerationRecord` query by userId with date range returns correct results

---

### FF-034 · Security Hardening — HTTP Headers, CSRF, and Secret Rotation

**Epic:** EP-07 (Tech Debt)
**Title:** As a platform operator, I want production security headers, CSRF protection, and a secrets rotation procedure so that the product meets baseline security requirements before accepting payment data.
**Priority:** Critical
**Story Points:** 3
**Sprint Allocation Category:** Tech Debt
**Labels:** `security` `infra`

**Business Objective:**
The Security Baseline document governs this story. Before accepting real payment credentials and user data, the application must have: correct HTTP security headers, CSRF protection on state-changing endpoints, and a documented procedure for rotating secrets. This is a pre-launch gate.

**Acceptance Criteria:**
- [ ] `next.config.mjs` configured with `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`
- [ ] CSP allows: self, `accounts.google.com` (for OAuth), Stripe domains (for checkout redirect), and the configured AI provider domains — blocks all others
- [ ] CSRF protection: NextAuth's built-in CSRF token is enabled and verified on all POST requests via the session
- [ ] `NEXTAUTH_SECRET` is a 32-byte random string; startup validation confirms it does not match the dev default in non-development environments (see FF-028)
- [ ] Stripe webhook signature verification is already required by FF-005 — confirm it is correctly implemented
- [ ] A `SECRETS_ROTATION.md` document describes how to rotate each secret and the impact of each rotation
- [ ] Dependency audit: `npm audit` runs in CI (FF-032); any `high` or `critical` vulnerabilities block deployment

**UX Expectations:**
- No user-visible change

**Edge Cases:**
- CSP violation: configure `report-uri` to capture violations in logs (not a hard block initially — use `Content-Security-Policy-Report-Only` in staging)
- Secret rotation mid-session: JWT sessions signed with the old secret will be invalid after rotation — document that all sessions are invalidated on `NEXTAUTH_SECRET` rotation

**Dependencies:** FF-028 (env var governance), FF-032 (CI must run `npm audit`)

**API Considerations:**
- No API response changes

**QA Notes:**
- Test: HTTP response headers include all required security headers
- Test: CSP blocks requests to unlisted domains (unit test with mocked fetch)
- Test: `npm audit` returns zero high/critical vulnerabilities
- Test: startup with dev-default `NEXTAUTH_SECRET` in production throws a clear error

---

## Story Summary Table

| Story ID | Epic | Title (abbreviated) | Priority | Points | Category |
|---|---|---|---|---|---|
| FF-001 | EP-01 | Demo Mode Isolation | Critical | 3 | Feature |
| FF-002 | EP-01 | Google OAuth Session Persistence | High | 3 | Feature |
| FF-003 | EP-01 | Role-Based Access Guard | Medium | 2 | Feature |
| FF-004 | EP-02 | Migrate Credits to Database | Critical | 8 | Tech Debt |
| FF-005 | EP-02 | Stripe Checkout — Plan Upgrade | Critical | 8 | Feature |
| FF-006 | EP-02 | Credit Balance UI & Low-Credit Warnings | High | 3 | Feature |
| FF-007 | EP-02 | Monthly Credit Reset & Billing Cycle | High | 5 | Feature |
| FF-008 | EP-02 | Billing Portal — Subscription Management | Medium | 3 | Feature |
| FF-009 | EP-03 | Streaming Generation Output | High | 8 | Feature |
| FF-010 | EP-03 | Provider Fallback & Retry Logic | High | 5 | Feature |
| FF-011 | EP-03 | Input Validation & Prompt Safety Layer | High | 3 | Feature |
| FF-012 | EP-03 | Prompt Versioning & A/B Testing | Medium | 5 | Feature |
| FF-013 | EP-04 | Markdown Rendering in OutputViewer | High | 3 | Feature |
| FF-014 | EP-04 | Export to PDF and Markdown File | High | 5 | Feature |
| FF-015 | EP-04 | Copy-to-Clipboard with Format Options | Medium | 2 | Feature |
| FF-016 | EP-04 | Regenerate with Modified Input | Medium | 3 | Feature |
| FF-017 | EP-05 | Generation History Persistence | Critical | 5 | Feature |
| FF-018 | EP-05 | History Search & Filter | Medium | 3 | Feature |
| FF-019 | EP-05 | History Record Deletion | Low | 2 | Feature |
| FF-020 | EP-06 | Per-Generation Token & Cost Tracking | High | 3 | Feature |
| FF-021 | EP-06 | User-Facing Usage Dashboard | Medium | 3 | Feature |
| FF-022 | EP-06 | Rate Limiting Per User | High | 3 | Feature |
| FF-023 | EP-07 | Landing Page Redesign | High | 5 | Design Debt |
| FF-024 | EP-07 | Dark Mode Polish & Token Audit | Low | 3 | Design Debt |
| FF-025 | EP-07 | Accessibility Audit & WCAG AA | High | 5 | Design Debt |
| FF-026 | EP-07 | Bug: Demo Credits Reset on Restart | High | 1 | Bug |
| FF-027 | EP-07 | Bug: Stale Credits on Generate Page | Medium | 1 | Bug |
| FF-028 | EP-07 | Env Var Governance & .env.example | High | 2 | Tech Debt |
| FF-029 | EP-07 | Structured Logging with Pino | High | 3 | Tech Debt |
| FF-030 | EP-07 | Automated Test Suite | High | 8 | Tech Debt |
| FF-031 | EP-07 | Error Boundaries & Global Error Handling | Medium | 3 | Tech Debt |
| FF-032 | EP-07 | CI/CD Pipeline — GitHub Actions | High | 5 | Tech Debt |
| FF-033 | EP-07 | Prisma Schema — Full Data Model | Critical | 5 | Tech Debt |
| FF-034 | EP-07 | Security Hardening | Critical | 3 | Tech Debt |

**Total Stories:** 34
**Total Story Points:** 133

---

## Recommended Sprint Sequencing

### Sprint 1 — Foundation (must ship before Stripe)
FF-028 → FF-033 → FF-004 → FF-026 → FF-001 → FF-034

*Rationale: You cannot safely charge money without a database, correct env var hygiene, and baseline security. These are hard blockers.*

### Sprint 2 — Revenue Enablement
FF-005 → FF-007 → FF-006 → FF-008 → FF-002

*Rationale: Stripe checkout, billing cycle, and credit UI are the direct revenue path. Session hardening prevents churned sessions from blocking payments.*

### Sprint 3 — Core Product Quality
FF-013 → FF-009 → FF-010 → FF-011 → FF-017 → FF-027

*Rationale: Streaming, markdown rendering, and history persistence are the "wow" moments that convert trial users to paid subscribers. Provider reliability reduces churn.*

### Sprint 4 — Output & Observability
FF-014 → FF-015 → FF-016 → FF-020 → FF-022 → FF-029

*Rationale: Export and copy options expand shareability (organic growth). Token tracking and rate limiting protect the economics.*

### Sprint 5 — Growth & Polish
FF-023 → FF-025 → FF-018 → FF-019 → FF-021 → FF-003 → FF-012

*Rationale: Landing page drives top-of-funnel conversion. Accessibility removes procurement blockers. History search, usage dashboard, and RBAC round out the product.*

### Sprint 6 — Infrastructure Hardening
FF-030 → FF-032 → FF-031 → FF-024

*Rationale: Test suite and CI/CD should be built iteratively alongside features, but a dedicated sprint ensures full coverage before the product scales.*

---

## Definition of Ready Checklist

Before moving any story to "Ready for Development," confirm:
- [ ] Business objective is clear and linked to a measurable outcome
- [ ] Acceptance criteria are specific and testable
- [ ] UX expectations are documented (wireframe or written spec)
- [ ] Edge cases are identified
- [ ] Dependencies are listed and either resolved or tracked
- [ ] API considerations documented (new endpoints, changes to existing endpoints)
- [ ] QA notes written
- [ ] Priority assigned by PM
- [ ] Architecture awareness confirmed (no structural surprises)

## Definition of Done Checklist

A story is not complete until:
- [ ] All acceptance criteria validated
- [ ] Unit tests written and passing
- [ ] QA verified (happy path + all edge cases in QA notes)
- [ ] Accessibility reviewed (no new critical violations)
- [ ] Regression impact reviewed
- [ ] Structured logging added for any new server-side code paths
- [ ] `.env.example` updated if new env vars introduced
- [ ] Product Memory updated if a significant architectural decision was made
- [ ] Release notes entry prepared
