# Workflow Dry-Run Playbook

Manual end-to-end validation of the solo-developer GitHub workflow before Conductor automation (Phase 2). Run this once after one-time project setup is complete.

**Feature under test:** **Workflow bootstrap validation** — you can use this very workflow as the subject, or a trivial "hello" feature.

**Time:** ~30–45 minutes  
**When:** After [GitHub Project setup](./github-project-setup.md) is complete.

---

## Prerequisites

Complete **[GitHub Project — One-Time Setup Guide](./github-project-setup.md) sections 3–10** before starting this dry-run:

| Section | Requirement |
|---------|-------------|
| 3 | Linked user project **AI Agents Orchestration** (Board template) |
| 4 | Status field: Backlog, Planning, Ready, In progress, In review, Done |
| 5 | **Board** view — group by Status, no filter |
| 6 | Optional **Features only** view — filter `type:feature` |
| 7 | **Roadmap** view — Roadmap layout, group Milestone, filter `type:feature` |
| 8 | Milestones: v0.1, v0.2, v0.3 |
| 9 | **Sub-issues** enabled (repo Settings → General → Features) |
| 10 | Verification smoke test passed |

Section 2 (labels) must also be satisfied — four workflow labels present on the remote.

See also [AGENTS.md](../../AGENTS.md) for lifecycle rules, spec/plan paths, and child-task conventions.

---

## Checklist

Work through each step in order. Check boxes as you complete them.

- [ ] **1. Create Feature issue**

  Create a Feature issue via the **Feature** template. Confirm on the project **Board** in **Backlog** with labels `type:feature` and `needs:triage`.

- [ ] **2. Move to Planning and brainstorm**

  Move the parent to **Planning**. Run Cursor `/brainstorming` on the issue (this workflow can be the subject, or a trivial "hello" feature).

- [ ] **3. Commit spec and plan; update Links**

  Confirm spec and plan files are committed to git:

  - Spec: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  - Plan: `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`

  Update the parent issue **Links** section with both file paths. Gate 1 (spec approval) must pass before proceeding.

- [ ] **4. Remove triage label; move to Ready**

  Remove `needs:triage`. Move the parent to **Ready** (plan file exists and Gate 1 approved).

- [ ] **5. Manually create two sub-issues from plan tasks**

  From the plan, create **two** child sub-issues (one per `### Task N:` block):

  - Both **Status: Ready**
  - Label: `type:task`
  - Task 2 has GitHub **blocked by** link to Task 1
  - Both added to the GitHub Project (visible on **Board**)

- [ ] **6. Execute Task 1**

  Move Task 1 through **In progress** → **In review** → **Done**.

- [ ] **7. Confirm blocking; execute Task 2**

  Confirm Task 2 remains blocked until Task 1 is **Done**, then pick up Task 2 and move it through the same status progression.

- [ ] **8. Close out the parent (human gates)**

  Move the parent to **In review**, then **Done** (human-only — Gate 2 after PR review).

- [ ] **9. Record friction**

  Record any friction, gaps, or surprises in a comment on the parent issue. Use this feedback to refine templates, labels, or automation before Phase 2.

---

## Expected outcomes

| Check | Pass criteria |
|-------|---------------|
| Parent lifecycle | Backlog → Planning → Ready → In progress → In review → Done |
| Labels | Parent: `type:feature`; children: `type:task` |
| Spec/plan in git | Paths linked on parent issue |
| Sub-issue dependency | Task 2 blocked until Task 1 Done |
| Board visibility | Parent and both tasks visible on **Board** |
| Human gates | Ready only after plan; Done only after review |

---

## After the dry-run

- If all checks pass, the workflow is validated for Conductor automation (Task 7+ in the bootstrap plan).
- If friction was recorded in step 9, address template, project, or doc gaps before enabling automation.

**Related:** [GitHub Workflow & Backlog design](../superpowers/specs/2026-07-06-github-workflow-backlog-design.md) · [Bootstrap plan](../superpowers/plans/2026-07-06-github-workflow-bootstrap.md)
