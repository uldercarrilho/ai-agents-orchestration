# AI Agents Orchestration — Agent Instructions

## Workflow overview

This repo uses GitHub Projects for backlog/status and git for specs/plans.

### Feature lifecycle (parent issue)

1. **Backlog** — idea stub (title + problem/outcome bullets)
2. **Planning** — manual Cursor session: `/brainstorming` → spec → Gate 1 → `writing-plans`
3. **Ready** — you move here after spec approved and plan written; triggers execution automation (Phase 2)
4. **In progress** — automation executing child tasks
5. **In review** — PR ready for human review (Gate 2)
6. **Done** — human moves parent to Done after merge

### Planning session rules

- Spec path: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Plan path: `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`
- After spec approval, update parent issue **Links** section with spec and plan paths
- Do not move parent to **Ready** until plan file exists and Gate 1 is approved

### Plan task format (Superpowers native)

Each task block:

```markdown
### Task N: [Title]

**Depends on:** Task 1, Task 3   # omit line if no dependencies

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts`

**Interfaces:**
- Consumes: ...
- Produces: ...
```

- One GitHub sub-issue per `### Task N:` block (not per checkbox step)
- Include `**Depends on:**` whenever a task waits on another task's output

### Child task issues

- Label: `type:task`
- Status: **Ready** on creation
- Set GitHub **blocked by** links for dependencies (automation does this in Phase 2)
- All child issues must be added to the GitHub Project (Board visibility)

### Human-only gates

- Gate 1: spec approval before parent → Ready
- Gate 2: PR review before parent → Done
- Never move a parent issue to **Done** automatically
