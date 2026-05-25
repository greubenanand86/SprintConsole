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
