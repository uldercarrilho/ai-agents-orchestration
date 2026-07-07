# GitHub Project — One-Time Setup Guide

One-time manual configuration for the solo-developer workflow described in [GitHub Workflow & Backlog design](../superpowers/specs/2026-07-06-github-workflow-backlog-design.md). After this setup, GitHub Projects v2 is the control plane for backlog and execution status; specs and plans stay in git.

**Time:** ~15–20 minutes  
**When:** Run once after the repo is pushed to GitHub and labels exist.

---

## 1. Prerequisites

Before starting, confirm:

1. **Repo on GitHub** — `ai-agents-orchestration` is pushed to your account (or org). From your local clone:
   ```bash
   gh repo view
   ```
   Expected: prints the remote repo URL without error.

2. **GitHub CLI authenticated** — labels and later automation use `gh`:
   ```bash
   gh auth login
   gh auth status
   ```
   Expected: `Logged in to github.com` with `repo` scope.

3. **Local clone** — run label commands from the repository root (where `docs/setup/create-labels.sh` lives).

---

## 2. Create labels

Labels are defined in the design spec and bootstrapped by the Task 3 script. Run once per repo:

```bash
bash docs/setup/create-labels.sh
```

Expected output:

```
Labels created.
```

This creates (idempotent — safe to re-run):

| Label | Purpose |
|-------|---------|
| `type:feature` | Parent feature issues |
| `type:task` | Plan-derived child task issues |
| `needs:triage` | Stub needs refinement before Ready |
| `risk:high` | Escalate model tier during execution (future Conductor use) |

Verify in the GitHub UI: **Issues** → **Labels** — all four labels should appear.

---

## 3. Create GitHub Project

Create a **user** (or org) project linked to this repository. A linked project auto-includes repo issues when you add them.

1. Open the repo on GitHub: `https://github.com/<your-user>/ai-agents-orchestration`
2. Click the **Projects** tab.
3. Click **Link a project** (if you already have projects) or **New project**.
4. Choose **Create new project**.
5. Select the **Board** template (you will customize fields and views below).
6. Name the project: **AI Agents Orchestration** (or your preference).
7. Under **Linked repositories**, add `ai-agents-orchestration`.
8. Click **Create project**.

You should land on a Board-style project view. The default **Status** field will have GitHub's stock options (e.g. Todo, In Progress, Done) — you replace those in the next section.

---

## 4. Configure Status field

The workflow uses a single **Status** project field with six values. Status is **not** encoded as labels.

1. In the project, open the **⋯** menu (top right) → **Settings** (or click the project title → **Settings**).
2. In the left sidebar, click **Fields**.
3. Click **Status** to edit the field.
4. Remove any default options you do not need (Todo, In Progress, Done, etc.).
5. Add options **in this exact order**:

   | Order | Option |
   |-------|--------|
   | 1 | Backlog |
   | 2 | Planning |
   | 3 | Ready |
   | 4 | In progress |
   | 5 | In review |
   | 6 | Done |

6. Save / close the field editor.

**Lifecycle reminder (parents):** Backlog → Planning → Ready → In progress → In review → Done. Moving a parent to **Ready** (after spec Gate 1 and plan exist) will eventually trigger execution automation. **Done** on a parent is human-only (Gate 2 after PR review).

---

## 5. Board view

Configure the primary Board view to show **all issues** (parents and child tasks) grouped by status.

1. In the project, select the default view (often named **View 1** or **Board**).
2. Click the view name → **Rename** → set to **Board**.
3. Set **Layout** to **Board** (table icon vs board icon in the view toolbar).
4. Click **Group by** → select **Status**. Columns should match the six statuses from §4.
5. **Filter:** leave empty — do **not** add label or type filters. Every issue added to the project should appear here, including future sub-issues created by Conductor.

This is your day-to-day execution view.

---

## 6. Optional Board filter

Save a secondary view when you want a less cluttered board during planning (features only, no task sub-issues).

1. In the project, click **+ New view** (or duplicate the Board view).
2. Rename the view to **Features only**.
3. Set **Layout** to **Board**.
4. Set **Group by** → **Status**.
5. Open **Filter** → **+ Filter** → **Label** → include **`type:feature`**.
6. Save the view.

Switch between **Board** (all issues) and **Features only** as needed. Automation still adds child tasks to the project; they appear on **Board** but not on **Features only**.

---

## 7. Roadmap view

Add a Roadmap view for release planning: parent features on a timeline, grouped by milestone.

1. Click **+ New view**.
2. Rename to **Roadmap**.
3. Set **Layout** to **Roadmap** (timeline layout in the view toolbar).
4. Set **Group by** → **Milestone**.
5. Open **Filter** → **+ Filter** → **Label** → include **`type:feature`**.
6. Save the view.

Child **task** sub-issues (`type:task`) are excluded by the label filter — only parent features appear on the roadmap. Assign milestones to parent issues when planning releases (§8).

---

## 8. Create milestones

Milestones are **repository-level** (not project-level). Create three release buckets:

1. In the repo, go to **Issues** → **Milestones** (right sidebar, or `https://github.com/<your-user>/ai-agents-orchestration/milestones`).
2. Click **New milestone** and create each of the following (description optional; due date optional for now):

   | Title | Suggested description |
   |-------|------------------------|
   | `v0.1 — Workflow bootstrap` | GitHub Project, templates, labels, dry-run workflow |
   | `v0.2 — Thin Conductor CLI` | READY trigger, sub-issue bootstrap, task picker |
   | `v0.3 — Test harness app` | End-to-end integration test application |

3. Leave milestones **open** until the corresponding work ships.

On the **Roadmap** view, parent issues with `type:feature` and a milestone assigned appear in the correct timeline group.

---

## 9. Enable sub-issues

Child tasks are GitHub **sub-issues** of parent features. Enable the feature on the repository if it is not already on.

1. In the repo, go to **Settings** → **General**.
2. Scroll to **Features**.
3. Under **Issues**, ensure **Sub-issues** is **enabled** (checked).
4. If you changed the setting, scroll down and click **Save** if prompted.

Without sub-issues, the plan-driven workflow (one sub-issue per `### Task N:` block) cannot be represented in GitHub.

---

## 10. Verify

Confirm the project, views, and templates work together.

1. **Create a test feature issue**
   - Repo **Issues** → **New issue** → choose the **Feature** template.
   - Fill in Problem and Desired outcome (any placeholder text).
   - Submit. Confirm labels **`type:feature`** and **`needs:triage`** were applied automatically.

2. **Add the issue to the project**
   - On the issue sidebar, under **Projects**, click **AI Agents Orchestration** (or your project name).
   - Or: open the project → **+ Add item** → search for the issue → add it.

3. **Confirm Board placement**
   - Open the project **Board** view.
   - The test issue should appear in the **Backlog** column (default Status for new items).
   - If Status is unset, set it to **Backlog** on the card.

4. **Confirm Features only view**
   - Switch to **Features only** — the test issue should appear.
   - (No task sub-issues exist yet; when they do, they should **not** appear here.)

5. **Confirm Roadmap (optional for this test)**
   - Assign milestone **`v0.1 — Workflow bootstrap`** to the test issue.
   - Open **Roadmap** — the issue should appear under that milestone.

6. **Clean up (optional)**
   - Close or delete the test issue when satisfied, or keep it as the first real backlog item.

---

## Quick reference

| Item | Value |
|------|--------|
| Status field | Backlog, Planning, Ready, In progress, In review, Done |
| Board view | Group by Status; no filter (all issues) |
| Features only | Group by Status; filter `type:feature` |
| Roadmap | Layout Roadmap; group Milestone; filter `type:feature` |
| Labels script | `bash docs/setup/create-labels.sh` |
| Milestones | v0.1 — Workflow bootstrap; v0.2 — Thin Conductor CLI; v0.3 — Test harness app |

**Next:** Follow the workflow dry-run in the bootstrap plan (Task 6) or proceed with pushing the repo and running full setup (Task 5 in `docs/superpowers/plans/2026-07-06-github-workflow-bootstrap.md`).
