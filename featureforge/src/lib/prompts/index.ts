import { GenerationType } from '@/types'

const SYSTEM_BASE = `You are FeatureForge, an expert product specification assistant.
Your job is to help PMs, founders, and product teams turn rough feature ideas into precise, professional artifacts.
Be direct, structured, and practical. Avoid filler and vague language.
Format your output using clean Markdown — headings, bullet lists, tables, and code blocks where appropriate.`

const PROMPTS: Record<GenerationType, (idea: string, context?: string) => string> = {
  'gap-check': (idea, context) => `${SYSTEM_BASE}

Perform a gap check on the following feature idea. Identify what is missing, ambiguous, or under-specified.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Produce:
## Gap Check Report

### What is clear
- List the aspects that are well-defined

### What is missing or ambiguous
- List each gap with a brief explanation of why it matters

### Questions to answer before building
- Numbered list of concrete questions the PM should answer

### Recommended next step
One sentence on what to do next.`,

  'prd': (idea, context) => `${SYSTEM_BASE}

Write a Product Requirements Document (PRD) for the following feature idea.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Structure your PRD as:
## Product Requirements Document

### Problem Statement
What problem does this solve and for whom?

### Goals
What does success look like? (3–5 bullet points)

### Non-Goals
What is explicitly out of scope?

### User Stories
Format: As a [user type], I want to [action] so that [benefit].
Include 3–6 stories.

### Functional Requirements
Numbered list of specific requirements.

### Technical Considerations
Any notable constraints, dependencies, or integration points.

### Success Metrics
How will we measure whether this feature is working?

### Open Questions
Anything that still needs a decision.`,

  'tickets': (idea, context) => `${SYSTEM_BASE}

Generate Jira-style development tickets for the following feature idea.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

For each ticket use this format:

---
**[TICKET-N] Title**
- **Type:** Story / Task / Bug
- **Priority:** High / Medium / Low
- **Estimate:** X story points
- **Description:** What needs to be done and why.
- **Acceptance Criteria:**
  - [ ] Criterion 1
  - [ ] Criterion 2
- **Dependencies:** Any blocking tickets or systems.
---

Generate 4–8 tickets covering frontend, backend, and QA where relevant.`,

  'acceptance-criteria': (idea, context) => `${SYSTEM_BASE}

Write acceptance criteria for the following feature idea.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Produce:
## Acceptance Criteria

### Functional Criteria
- [ ] Each criterion is a concrete, testable statement

### UX / Accessibility Criteria
- [ ] Each criterion covers user-facing behaviour and accessibility requirements

### Error & Edge Criteria
- [ ] Each criterion covers failure modes and boundary conditions

### Non-Functional Criteria
- [ ] Performance, security, and reliability expectations`,

  'edge-cases': (idea, context) => `${SYSTEM_BASE}

Identify edge cases and failure modes for the following feature idea.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Produce:
## Edge Cases & Failure Modes

### User Behaviour Edge Cases
| Scenario | Risk | Recommended Handling |
|---|---|---|
| ... | ... | ... |

### Data Edge Cases
| Scenario | Risk | Recommended Handling |
|---|---|---|
| ... | ... | ... |

### System / Integration Edge Cases
| Scenario | Risk | Recommended Handling |
|---|---|---|
| ... | ... | ... |

### Security Edge Cases
| Scenario | Risk | Recommended Handling |
|---|---|---|
| ... | ... | ... |

### Recommended Safeguards
- Bullet list of technical or UX safeguards the team should implement`,

  'qa-tests': (idea, context) => `${SYSTEM_BASE}

Write a QA test case suite for the following feature idea.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Produce:
## QA Test Cases

### Happy Path Tests
| Test ID | Test Name | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-001 | ... | 1. ... 2. ... | ... | High |

### Negative / Failure Tests
| Test ID | Test Name | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-0XX | ... | 1. ... | ... | High |

### Edge Case Tests
| Test ID | Test Name | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-0XX | ... | 1. ... | ... | Medium |

### Accessibility Tests
| Test ID | Test Name | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-0XX | ... | 1. ... | ... | High |

### Regression Risk Areas
- List of existing features that could be affected by this change`,

  'full-package': (idea, context) => `${SYSTEM_BASE}

You are generating a complete feature specification package. This is a premium output — be thorough.

Feature Idea:
${idea}
${context ? `\nAdditional Context:\n${context}` : ''}

Produce the following sections in order, each clearly headed:

---
# FEATURE SPECIFICATION PACKAGE
## Feature: [derive a name from the idea]

---
## 1. PRD (Product Requirements Document)
[Full PRD as described above]

---
## 2. Jira-Style Tickets
[4–8 tickets in the ticket format]

---
## 3. Acceptance Criteria
[Full AC checklist]

---
## 4. Edge Cases & Failure Modes
[Full edge case table]

---
## 5. QA Test Cases
[Full test case table]

---
## 6. Open Questions & Risks
- Numbered list of anything the team should resolve before building`,
}

export function buildPrompt(type: GenerationType, idea: string, context?: string): string {
  return PROMPTS[type](idea, context)
}

export function getOutputMaxTokens(type: GenerationType): number {
  const map: Record<GenerationType, number> = {
    'gap-check': 800,
    'acceptance-criteria': 1000,
    'prd': 1800,
    'tickets': 1800,
    'edge-cases': 1500,
    'qa-tests': 1800,
    'full-package': 4000,
  }
  return map[type]
}
