# GitHub Workflow Bootstrap — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap the approved GitHub Projects workflow so a solo developer can capture ideas, plan features manually in Cursor, and (in Phase 1) execute tasks by hand — with repo artifacts ready for Conductor automation in Phase 2.

**Architecture:** Phase 1 delivers repo-local workflow contracts (`AGENTS.md`, issue templates, setup guides) plus GitHub Project configuration (manual UI steps documented and executed once). Phase 2 adds a thin Conductor CLI and READY GitHub Action. Git remains source of truth for specs/plans; GitHub Project tracks status for all issues on the Board.

**Tech Stack:** GitHub Projects v2, GitHub Issues/sub-issues, `gh` CLI, Markdown, TypeScript (Phase 2 only — Conductor CLI)

## Global Constraints

- Solo developer, cost-conscious — no Linear or paid tooling for v1
- Specs in `docs/superpowers/specs/`; plans in `docs/superpowers/plans/`
- Parent issues: human owns Backlog → Planning → Ready and In review → Done
- Child sub-issues: all appear on Board; created Ready with `blocked by` for dependencies
- Plan format: Superpowers native (`### Task N:` blocks); optional `**Depends on:** Task N` per task
- Status field values: Backlog, Planning, Ready, In progress, In review, Done
- Labels: `type:feature`, `type:task`, `needs:triage`, `risk:high`
- Board shows all issues; Roadmap shows parent issues only grouped by milestone
- Conductor must add sub-issues to GitHub Project when created (Phase 2)

---

## File Structure (Phase 1 deliverables)

```
ai-agents-orchestration/
├── AGENTS.md                              # workflow rules for agents
├── .github/
│   └── ISSUE_TEMPLATE/
│       ├── feature.yml                    # parent issue form
│       └── task.yml                       # child issue form (manual + reference for automation)
└── docs/
    └── setup/
        ├── github-project-setup.md        # one-time GitHub UI + gh CLI steps
        ├── workflow-dry-run.md            # end-to-end manual validation playbook
        └── create-labels.sh               # idempotent label bootstrap script
```

Phase 2 adds `orchestration/conductor/` and `.github/workflows/ready-trigger.yml` (separate tasks at end).

---

### Task 1: AGENTS.md workflow rules

**Files:**
- Create: `AGENTS.md`

**Interfaces:**
- Produces: `AGENTS.md` — referenced by all Cursor/Superpowers sessions and future Conductor roles

- [ ] **Step 1: Create AGENTS.md**

```markdown
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
```

- [ ] **Step 2: Verify file exists**

Run: `cat AGENTS.md | head -20`
Expected: shows workflow overview heading

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add AGENTS.md workflow rules for GitHub backlog"
```

---

### Task 2: GitHub issue templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/feature.yml`
- Create: `.github/ISSUE_TEMPLATE/task.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`

**Interfaces:**
- Consumes: label names from spec (`type:feature`, `type:task`, `needs:triage`)
- Produces: issue templates used when creating parent/child issues on GitHub

- [ ] **Step 1: Create feature template**

Create `.github/ISSUE_TEMPLATE/feature.yml`:

```yaml
name: Feature
description: New feature idea stub for the backlog
title: "[Feature] "
labels:
  - type:feature
  - needs:triage
body:
  - type: markdown
    attributes:
      value: |
        ## Problem
        <!-- 1-2 sentences: what problem does this solve? -->
  - type: textarea
    id: problem
    attributes:
      label: Problem
      description: What problem does this solve?
    validations:
      required: true
  - type: textarea
    id: outcome
    attributes:
      label: Desired outcome
      description: What does "done" look like, roughly?
    validations:
      required: true
  - type: textarea
    id: constraints
    attributes:
      label: Constraints
      description: Optional — cost, stack, deadline
    validations:
      required: false
  - type: markdown
    attributes:
      value: |
        ## Links
        - Spec: _(added during Planning)_
        - Plan: _(added during Planning)_
        - PR: _(added when opened)_
```

- [ ] **Step 2: Create task template**

Create `.github/ISSUE_TEMPLATE/task.yml`:

```yaml
name: Task
description: Plan-derived task (normally created by automation)
title: "[Task] "
labels:
  - type:task
body:
  - type: input
    id: parent
    attributes:
      label: Parent issue
      description: "Parent feature issue number, e.g. #42"
    validations:
      required: true
  - type: input
    id: task_id
    attributes:
      label: Task ID
      description: "From plan heading, e.g. Task 2"
    validations:
      required: true
  - type: input
    id: plan_path
    attributes:
      label: Plan file path
      description: "e.g. docs/superpowers/plans/2026-07-06-feature.md"
    validations:
      required: true
  - type: textarea
    id: files
    attributes:
      label: Files
      description: Scoped files from plan **Files:** block
    validations:
      required: true
```

- [ ] **Step 3: Create template config**

Create `.github/ISSUE_TEMPLATE/config.yml`:

```yaml
blank_issues_enabled: false
contact_links:
  - name: Workflow spec
    url: https://github.com/YOUR_USER/ai-agents-orchestration/blob/master/docs/superpowers/specs/2026-07-06-github-workflow-backlog-design.md
    about: Read the GitHub workflow design spec before creating issues
```

Replace `YOUR_USER` with the actual GitHub username/org when pushing.

- [ ] **Step 4: Commit**

```bash
git add .github/ISSUE_TEMPLATE/
git commit -m "feat: add GitHub issue templates for feature and task issues"
```

---

### Task 3: Label bootstrap script

**Files:**
- Create: `docs/setup/create-labels.sh`

**Interfaces:**
- Produces: idempotent shell script; run once after repo is on GitHub

- [ ] **Step 1: Create script**

Create `docs/setup/create-labels.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Requires: gh CLI authenticated (gh auth login)

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  gh label create "$name" --color "$color" --description "$description" --force
}

create_label "type:feature" "0075ca" "Feature (parent) issue"
create_label "type:task" "7057ff" "Plan-derived task (child) issue"
create_label "needs:triage" "fbca04" "Stub needs refinement before Ready"
create_label "risk:high" "d93f0b" "Escalate model tier during execution"

echo "Labels created."
```

- [ ] **Step 2: Make executable and verify syntax**

Run (Git Bash or WSL on Windows):
```bash
chmod +x docs/setup/create-labels.sh
bash -n docs/setup/create-labels.sh
```
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```bash
git add docs/setup/create-labels.sh
git commit -m "chore: add gh CLI script to bootstrap GitHub labels"
```

---

### Task 4: GitHub Project setup guide

**Files:**
- Create: `docs/setup/github-project-setup.md`

**Interfaces:**
- Consumes: spec decisions (status values, views, milestones)
- Produces: step-by-step guide for one-time GitHub UI configuration

- [ ] **Step 1: Write setup guide**

Create `docs/setup/github-project-setup.md` with these exact sections:

1. **Prerequisites** — repo pushed to GitHub, `gh auth login`
2. **Create labels** — run `bash docs/setup/create-labels.sh`
3. **Create GitHub Project** — org/user project linked to repo
4. **Configure Status field** — add options in order: Backlog, Planning, Ready, In progress, In review, Done
5. **Board view** — group by Status; filter: none (show all issues)
6. **Optional Board filter** — save "Features only" view: label = `type:feature`
7. **Roadmap view** — layout = Roadmap; group by Milestone; filter: label = `type:feature`
8. **Create milestones:**
   - `v0.1 — Workflow bootstrap`
   - `v0.2 — Thin Conductor CLI`
   - `v0.3 — Test harness app`
9. **Enable sub-issues** — repo Settings → General → Features → Issues → Sub-issues (if not already on)
10. **Verify** — create a test Feature issue, add to project, confirm it appears on Board in Backlog

- [ ] **Step 2: Commit**

```bash
git add docs/setup/github-project-setup.md
git commit -m "docs: add GitHub Project one-time setup guide"
```

---

### Task 5: Push repo to GitHub and run setup

**Files:**
- Modify: `.github/ISSUE_TEMPLATE/config.yml` (replace YOUR_USER placeholder)

**Interfaces:**
- Consumes: Tasks 1–4 committed locally
- Produces: remote repo with labels and documented project setup

- [ ] **Step 1: Create GitHub remote**

Run (replace `YOUR_USER`):
```bash
gh repo create ai-agents-orchestration --public --source=. --remote=origin --push
```
Expected: repo created and master pushed

If repo already exists:
```bash
git remote add origin https://github.com/YOUR_USER/ai-agents-orchestration.git
git push -u origin master
```

- [ ] **Step 2: Fix template config URL**

Update `.github/ISSUE_TEMPLATE/config.yml` contact link with real GitHub URL.

- [ ] **Step 3: Create labels on remote**

Run:
```bash
bash docs/setup/create-labels.sh
```
Expected: `Labels created.`

- [ ] **Step 4: Follow github-project-setup.md**

Complete steps 3–10 in GitHub UI (Project, Status field, Board, Roadmap, milestones).

- [ ] **Step 5: Commit config fix and push**

```bash
git add .github/ISSUE_TEMPLATE/config.yml
git commit -m "chore: set issue template contact link to repo URL"
git push
```

---

### Task 6: Workflow dry-run playbook

**Files:**
- Create: `docs/setup/workflow-dry-run.md`

**Interfaces:**
- Consumes: live GitHub Project from Task 5
- Produces: validated manual workflow before Conductor automation

- [ ] **Step 1: Write dry-run playbook**

Create `docs/setup/workflow-dry-run.md` covering this first feature: **"Workflow bootstrap validation"**

Checklist:

1. Create Feature issue via template → confirm on Board in **Backlog** with `type:feature`, `needs:triage`
2. Move to **Planning**; run Cursor `/brainstorming` on the issue (this very workflow can be the subject, or a trivial "hello" feature)
3. Confirm spec + plan files committed; parent issue Links updated
4. Remove `needs:triage`; move parent to **Ready**
5. **Manually** create 2 sub-issues from plan tasks:
   - Both Status **Ready**
   - Task 2 has `blocked by` Task 1
   - Both added to GitHub Project (visible on Board)
6. Move Task 1 through In progress → In review → Done
7. Confirm Task 2 is still blocked until Task 1 Done, then pick up Task 2
8. Move parent to In review, then **Done** (human)
9. Record any friction in a comment on the parent issue

- [ ] **Step 2: Execute dry-run**

Follow the playbook yourself; check each box.

- [ ] **Step 3: Commit playbook**

```bash
git add docs/setup/workflow-dry-run.md
git commit -m "docs: add manual workflow dry-run playbook"
git push
```

---

## Phase 2 — Conductor automation (after Phase 1 dry-run passes)

These tasks implement spec items 9–10. Execute only after Task 6 dry-run succeeds.

### Task 7: Plan parser module

**Depends on:** Task 6

**Files:**
- Create: `orchestration/conductor/package.json`
- Create: `orchestration/conductor/tsconfig.json`
- Create: `orchestration/conductor/src/plan-parser.ts`
- Create: `orchestration/conductor/src/plan-parser.test.ts`
- Test: `orchestration/conductor/src/plan-parser.test.ts`

**Interfaces:**
- Produces: `parsePlan(markdown: string): ParsedPlan` where `ParsedPlan = { tasks: PlanTask[] }` and `PlanTask = { id: string; title: string; files: string[]; dependsOn: string[] }`

- [ ] **Step 1: Scaffold TypeScript package**

Minimal `package.json` with `vitest`, `typescript`; `"type": "module"`.

- [ ] **Step 2: Write failing tests**

```typescript
import { describe, it, expect } from 'vitest';
import { parsePlan } from './plan-parser.js';

const SAMPLE = `# Plan

### Task 1: Add model

**Files:**
- Create: \`packages/db/schema.prisma\`

### Task 2: API route

**Depends on:** Task 1

**Files:**
- Create: \`apps/web/app/api/route.ts\`
`;

describe('parsePlan', () => {
  it('extracts task id, title, files', () => {
    const result = parsePlan(SAMPLE);
    expect(result.tasks[0]).toEqual({
      id: 'Task 1',
      title: 'Add model',
      files: ['packages/db/schema.prisma'],
      dependsOn: [],
    });
  });

  it('extracts dependsOn', () => {
    const result = parsePlan(SAMPLE);
    expect(result.tasks[1].dependsOn).toEqual(['Task 1']);
  });
});
```

- [ ] **Step 3: Run tests — expect FAIL**

Run: `cd orchestration/conductor && npm test`
Expected: FAIL — module not found

- [ ] **Step 4: Implement parsePlan**

Implement regex/markdown parsing for `### Task N:`, `**Depends on:**`, and `**Files:**` bullet list.

- [ ] **Step 5: Run tests — expect PASS**

Run: `cd orchestration/conductor && npm test`
Expected: all tests PASS

- [ ] **Step 6: Commit**

```bash
git add orchestration/conductor/
git commit -m "feat(conductor): add Superpowers plan file parser"
```

---

### Task 8: Conductor bootstrap command + READY workflow

**Depends on:** Task 7

**Files:**
- Create: `orchestration/conductor/src/bootstrap.ts`
- Create: `orchestration/conductor/src/github-client.ts`
- Create: `orchestration/conductor/src/cli.ts`
- Create: `.github/workflows/ready-trigger.yml`

**Interfaces:**
- Consumes: `parsePlan()` from Task 7
- Produces: `conductor bootstrap --issue <n>` CLI; GitHub Action trigger on parent → Ready

- [ ] **Step 1: Implement github-client wrappers**

Functions: `createSubIssue`, `addIssueToProject`, `setBlockedBy`, `setProjectStatus`, `getIssueBody`

Uses `@octokit/rest` or `gh api` subprocess.

- [ ] **Step 2: Implement bootstrap command**

Flow:
1. Read parent issue; extract plan path from Links section
2. Parse plan with `parsePlan`
3. Idempotency: skip creation if sub-issues already exist
4. Create sub-issues (Ready, `type:task`, add to project, set blocked-by)
5. Set parent → In progress

- [ ] **Step 3: Add ready-trigger workflow**

```yaml
name: READY Trigger
on:
  projects_v2_item:
    types: [edited]

jobs:
  bootstrap:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci
        working-directory: orchestration/conductor
      - run: node dist/cli.js bootstrap --issue ${{ github.event.projects_v2_item.content_id }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 4: Integration test on a test feature issue**

Move a test parent to Ready; verify sub-issues appear on Board with correct blockers.

- [ ] **Step 5: Commit**

```bash
git add orchestration/conductor/ .github/workflows/ready-trigger.yml
git commit -m "feat(conductor): add bootstrap command and READY GitHub Action"
git push
```

---

## Spec Coverage Check

| Spec requirement | Task |
|------------------|------|
| AGENTS.md Depends on convention | Task 1 |
| Issue templates (parent/child) | Task 2 |
| Labels | Task 3, 5 |
| GitHub Project Status field (6 values) | Task 4, 5 |
| Board all issues / Roadmap parents only | Task 4 |
| Milestones | Task 4, 5 |
| Manual planning flow | Task 6 |
| Plan parser (Superpowers format) | Task 7 |
| READY trigger + sub-issue creation + project add | Task 8 |
| blocked by dependencies | Task 6 (manual), Task 8 (auto) |
| Idempotency on re-trigger | Task 8 |

## Out of scope for this plan

- Task picker / parallel execution loop (Conductor scheduler — next plan)
- OpenCode agent invocation
- Linear adapter
