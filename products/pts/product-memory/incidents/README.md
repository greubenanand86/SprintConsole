# Incidents

Postmortems for production incidents. SEV-1 and SEV-2 entries are required. SEV-3 entries are optional but encouraged when a pattern is emerging.

## Entry template

```markdown
# Incident — {Short title}

**Date**: {YYYY-MM-DD}
**Severity**: SEV-1 / SEV-2 / SEV-3
**Duration**: {HH:MM} — {start time} to {resolution time}
**Jira**: {PREFIX}-{N}
**Status**: Resolved / Monitoring

## What happened

{Timeline of events. What broke, when it was detected, how it was resolved.}

## Root cause

{The specific technical or process failure that caused the incident.}

## Impact

{Who was affected and how. Quantify if possible — users impacted, data affected, downtime.}

## Remediation

**Immediate**: {What was done to stop the bleeding.}
**Short-term**: {Jira stories filed to prevent recurrence.}
**Long-term**: {Process or architecture changes needed.}

## What we learned

- {Learning}

## Contributing factors

- {Factor — not blame, just causes}
```
