# Products

> Open this vault in Obsidian. Install community plugins when prompted.

## Products

| Product | Kanban | Tasks | Memory |
|---|---|---|---|
| SprintConsole | [[products/sprintconsole/kanban\|Board]] | [[products/sprintconsole/tasks/README\|Tasks]] | [[products/sprintconsole/PRODUCT_MEMORY\|Memory]] |
| PTS | [[products/pts/kanban\|Board]] | [[products/pts/tasks/README\|Tasks]] | [[products/pts/PRODUCT_MEMORY\|Memory]] |

## Shared governance

- [[governance/shared/shared-vs-product-specific-rules|Shared vs product-specific rules]]
- [[governance/shared/product-routing-rules|Product routing rules]]
- [[governance/shared/agent-advisory-mode|Agent advisory mode]]

## Quick actions

- New task → use template `obsidian-templates/task`
- New decision → use template `obsidian-templates/decision`
- New incident → use template `obsidian-templates/incident`

## All open tasks

```dataview
TABLE status, type, priority, product
FROM "products"
WHERE file.name != "README" AND contains(file.path, "/tasks/") AND status != "Done"
SORT priority ASC
```

## In Progress — all products

```dataview
LIST
FROM "products"
WHERE contains(file.path, "/tasks/") AND status = "In Progress"
```
