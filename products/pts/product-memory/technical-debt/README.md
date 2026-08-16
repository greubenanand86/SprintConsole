# Technical Debt

Logged debt items with enough context to act on them later. Each entry is a Jira story that has not been scheduled yet, or a known shortcut taken during delivery.

Write an entry when debt is introduced deliberately (time pressure, prototype phase) or discovered during work. Link to the Jira story if one exists.

## Entry template

```markdown
# {Debt title}

**Date logged**: {YYYY-MM-DD}
**Jira**: {PREFIX}-{N} / not yet filed
**Severity**: Low / Medium / High
**Status**: Open / In progress / Resolved in v{x.y.z}

## What the debt is

{Describe the shortcut, missing piece, or fragile assumption in plain language.}

## Why it was introduced

{Time pressure / prototype phase / blocked dependency / deliberate trade-off.}

## Impact if not addressed

{What breaks, degrades, or becomes impossible to change as the codebase grows?}

## Remediation plan

{What the fix looks like and roughly how large the effort is.}

## Trigger for prioritization

{What event should force this to the top of the backlog?}
```
