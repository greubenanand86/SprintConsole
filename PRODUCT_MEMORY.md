# Product Memory
## SprintOps Console — Decisions, Learnings, and Governance Records

---

## Architecture Decision — 2026-05-25

### ADR-001: Architecture Blueprint v1.0 Adopted

**Decision:** Architecture Blueprint v1.0 is the governing technical standard for all SprintOps Console development, present and future. Full document in `ARCHITECTURE.md`.

**Rationale:** The product is evolving beyond a single no-build Babel prototype toward a multi-client (web + mobile), API-first system. The blueprint establishes consistent, boring-but-scalable defaults so the team doesn't relitigate stack choices story by story.

**Key mandates:**
- Web: React + TypeScript + Next.js (preferred) + React Query + Zustand/Redux Toolkit
- Mobile: React Native + Expo + TypeScript + shared design system
- Backend: API-first, version-aware, centralized auth, validation layer, structured logging
- All clients interact through consistent API contracts — no client-side business logic that leaks platform concerns
- TypeScript is mandatory everywhere (currently a known debt item on web — migration required)
- Feature-based folder organization across all clients

**Technical Decision Hierarchy (ARCHITECTURE.md §15):**
1. Security
2. Stability
3. Maintainability
4. Scalability
5. Developer productivity
6. Performance optimization
7. Architectural sophistication

**Current state vs target state:**
- Current: single-page Babel/JSX no-build prototype (`index.html` + `*.jsx` files)
- Target: `/web` (Next.js/TS), `/mobile` (Expo/TS), `/backend` (API-first), `/shared` (business logic + design system)

**Migration path:** No big-bang rewrite. Each new story should move toward the target structure. TypeScript migration is the highest-priority debt item per Engineering Constitution §2 + Architecture Blueprint §3.

**Constraints:**
- Babel in-browser transpilation is a temporary affordance — it must be replaced as part of the Next.js migration
- Native code in mobile requires Architecture review and Release Risk awareness
- Destructive DB migrations require Architecture review, rollback strategy, and human approval

**Known limitations of current architecture:**
- No TypeScript (debt — Engineering Constitution §2)
- No automated test suite (debt — Engineering Constitution §6)
- No CI pipeline (debt — Engineering Constitution §8)
- No structured logging (debt — Engineering Constitution §7)
- No bundler / build step (debt — Architecture Blueprint §3)

**Recorded by:** Architect Agent / Human  
**Governance refs:** Architecture Blueprint v1.0, Engineering Constitution v1.0, Product Constitution v1.0

---

## Architecture Decision — 2026-05-25

### ADR-002: API Contract Standards v1.0 Adopted

**Decision:** API Contract Standards v1.0 is the governing standard for all API design across web, mobile, and backend clients. Full document in `API_CONTRACT_STANDARDS.md`.

**Rationale:** As the product evolves toward an API-first architecture (Architecture Blueprint §5), consistent API contracts prevent frontend/backend/mobile drift and make integrations predictable across all clients.

**Key mandates:**
- All APIs must include: clear endpoint naming, consistent request/response format, validation rules, auth requirement, error format, pagination where needed, version awareness
- Standard error format: `{ "errorCode": "...", "message": "...", "details": {} }`
- Versioned routes: `/api/v1/...`
- Breaking changes require Architecture review, Release Risk review, and a migration plan
- API contracts are shared product infrastructure — not backend implementation details

**Impact on current state:** SprintOps Console prototype has no backend API yet. These standards apply from the first backend story onward and must be enforced by the Architect Agent during refinement.

**Governance refs:** API Contract Standards v1.0, Architecture Blueprint v1.0 §5

---

## Architecture Decision — 2026-05-25

### ADR-003: Shared Package Strategy v1.0 Adopted

**Decision:** Shared Package Strategy v1.0 governs how code is shared across web and mobile clients. Full document in `SHARED_PACKAGE_STRATEGY.md`.

**Rationale:** Without a shared package strategy, React web and React Native mobile will independently re-implement validation, API clients, analytics, and utility logic — creating drift that becomes expensive to fix.

**Package layout:**
- `/packages/ui` — reusable UI primitives (platform-aware)
- `/packages/api-client` — API clients (fetch wrappers, error handling, versioning)
- `/packages/validation` — shared validation schemas (used by both clients and backend)
- `/packages/utils` — common utilities
- `/packages/config` — shared configuration (no production secrets)
- `/packages/analytics` — analytics event helpers and consistent event naming

**Rules:**
- Shared packages must not contain platform-specific logic
- No business logic duplication across clients — extract to shared
- No direct production config in shared code
- Principle: reduce duplication without hiding platform-specific realities

**Impact on current state:** No `/packages` directory exists yet. These standards apply when the first shared package is introduced and must be enforced by the Architect Agent during refinement.

**Governance refs:** Shared Package Strategy v1.0, Architecture Blueprint v1.0 §3 §4

---
