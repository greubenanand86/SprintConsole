# Adding a New Product

All agents are shared. Products differ only by their config file and workspace.

## Steps

### 1. Register the product

Add an entry to `products/registry.json`:

```json
{
  "id": "my-product",
  "name": "My Product",
  "jira_project": "MP",
  "config": "products/my-product/config.env",
  "status": "active"
}
```

`jira_project` must match the Jira project key prefix exactly (e.g. `"MP"` for tickets like `MP-123`).

### 2. Create the product config

Copy and edit `products/sprintconsole/config.env`:

```bash
cp -r products/sprintconsole products/my-product
# then edit products/my-product/config.env
```

Set at minimum:
| Variable | Required | Example |
|---|---|---|
| `PRODUCT_ID` | ✅ | `my-product` |
| `PRODUCT_NAME` | ✅ | `My Product` |
| `JIRA_PROJECT` | ✅ | `MP` |
| `PRODUCT_STACK` | ✅ | `React 18, TypeScript` |
| `PRODUCT_CORE_FILES` | ✅ | `src/App.tsx, src/components/...` |
| `PRODUCT_WIP_LIMIT` | optional | `8` |
| `PRODUCT_TEAM_EMAIL` | optional | `team@example.com` |

### 3. Initialize the product memory file

```bash
cp products/sprintconsole/PRODUCT_MEMORY.md products/my-product/PRODUCT_MEMORY.md
# Clear the archive section — start fresh for the new product
```

### 4. Run agents against the new product

**Explicit product selection:**
```bash
PRODUCT=my-product .claude/hooks/pm-agent.sh
PRODUCT=my-product .claude/hooks/architect-agent.sh MP-42
```

**Auto-detect from Jira key:**
```bash
.claude/hooks/architect-agent.sh MP-42   # detects "MP" → my-product automatically
```

**All products (auto-scan hooks):**
Hooks in `.claude/settings.json` run with no `PRODUCT` env var, so they will
resolve via registry default unless you set the env var in your shell or CI.

To run all products in a sweep:
```bash
bash -c 'source .claude/hooks/jira.sh && for_each_product some_function'
```

## How context loading works

When any agent script does `source "$SCRIPT_DIR/jira.sh"`, the following happens
automatically at source time:

```
1. jira.sh defines all helper functions
2. jira.sh defines _GOVERNANCE_CONTEXT (shared governance docs — identical for all products)
3. load_product_context is called:
   a. Reads PRODUCT env var (if set)
   b. Or auto-detects from Jira key prefix via products/registry.json
   c. Or uses registry "default"
   d. Sources products/<id>/config.env
   e. Rebuilds AGENT_CONTEXT = product header + shared governance
   f. Exports JIRA_PROJECT, PRODUCT_MEMORY_FILE, PRODUCT_WIP_LIMIT
4. All subsequent Jira API calls use the loaded JIRA_PROJECT
5. All agent prompts include the product-specific context header
```

## What is shared (never duplicated)

- All 18 agent scripts in `.claude/hooks/`
- All governance docs (`ARCHITECTURE.md`, `AGENT_ROLE_SPECIFICATIONS.md`, etc.)
- `jira.sh` helper library
- `.claude/settings.json` hooks configuration
- Shared governance context in `_GOVERNANCE_CONTEXT`

## What is per-product

- `products/<id>/config.env` — name, Jira project, stack description, thresholds
- `products/<id>/PRODUCT_MEMORY.md` — isolated organizational memory
- Jira project (separate tickets, sprints, stories)
