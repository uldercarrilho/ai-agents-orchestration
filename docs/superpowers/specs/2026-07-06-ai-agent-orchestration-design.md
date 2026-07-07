# AI Agent Orchestration Framework — Design Spec

**Status:** Draft (brainstorming checkpoint — not yet approved for implementation)  
**Date:** 2026-07-06  
**Related:** [ai-agent-orchestration-architecture.md](../../ai-agent-orchestration-architecture.md) (north-star architecture)

---

## Summary

Design for a reusable, vendor-neutral AI agent orchestration framework. Primary goal is to **prove the framework itself**; a small full-stack test harness app exists only to exercise the pipeline end-to-end.

**Chosen approach:** Thin Conductor CLI + Superpowers workflow spine, growing toward the full architecture over time.

---

## Decisions Log

| Topic | Decision | Notes |
|---|---|---|
| Primary goal | **B — Framework first** | App is a test harness, not the product |
| v1 success bar | **C — Full pipeline** | Routing, escalation, security reviewer, observability trace, cost invoice |
| Spec / workflow layer | **Superpowers only** | Evolve to OpenSpec or Spec Kit when concrete pain appears |
| Task management | **Git source of truth + Linear mirror** | Specs/plans in repo; Linear for human visibility via optional adapter |
| Cursor Marketplace | **Optional plugin adapters** | Core framework runs without any marketplace plugins |
| Test harness stack | **A — TypeScript monorepo** | Next.js + Prisma + PostgreSQL |
| Self-improvement | **A — Human-in-the-loop only** | Agents propose changes; you approve all merges |
| Quality gates | **B — OSS + SonarCloud free tier** | ESLint, TypeScript, Vitest, Playwright, Gitleaks, Semgrep OSS + SonarCloud |

---

## Context & Constraints

- **Team:** Solo / small team, cost-conscious
- **Hosting:** GitHub
- **Primary tools:** Cursor (Composer 2.5) for planning and high-judgment work; OpenCode for scriptable cheap-model execution (e.g. DeepSeek)
- **Core principle:** You own requirements and three approval gates (plan, PR, deploy). Agents own everything in between under a supervising Conductor with specialized roles.
- **State:** Lives in files, not conversation memory
- **Vendor neutrality:** Avoid lock-in; marketplace plugins and external tools are swappable adapters

---

## Spec Framework Analysis

### Superpowers (chosen for v1)

- Agent **methodology** via composable skills: brainstorm → writing-plans → subagent-driven-development → two-stage review
- Works across **Cursor and OpenCode**
- Specs: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Plans: `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`
- Hard gate: no production code until design approved
- [Superpowers on GitHub](https://github.com/obra/superpowers) · [Cursor Directory](https://cursor.directory/plugins/superpowers)

**v1 substitutes for OpenSpec:**

| Need | Superpowers-only approach |
|---|---|
| Spec artifact | Design docs in `docs/superpowers/specs/` |
| Task breakdown | Plans with checkbox tasks in `docs/superpowers/plans/` |
| Scope conformance | Conductor parses plan file paths + spec in/out-of-scope sections |
| Lifecycle | Folder naming + git tags (`spec-approved`, `implemented`) |
| Brownfield specs | `AGENTS.md` + per-feature design docs until capability library is warranted |

### OpenSpec (deferred)

- Machine-checkable deltas, `openspec validate`, brownfield capability library
- **Adopt when:** scope creep slips past plan-file checks, or brownfield spec drift becomes painful
- [OpenSpec](https://openspec.dev/) · [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)

### Spec Kit (deferred — template donor only)

- Constitution → Specify → Plan → Tasks → Implement; heavier ceremony
- **Adopt when:** planning feels thin; borrow constitution/checklist templates only, not full workflow
- [GitHub Spec Kit](https://github.github.com/spec-kit/)

### Evolution triggers

| Trigger | Action |
|---|---|
| Scope creep slips past plan-file checks | Add OpenSpec `validate` for delta specs |
| Brownfield capability library needed | Migrate specs → `openspec/specs/` |
| Planning feels thin | Borrow Spec Kit constitution template only |

---

## Task Management: Linear + Git Hybrid

**Problem:** Linear is excellent for following execution; git-backed specs are essential for version control, scope checks, and vendor neutrality.

**Pattern:**

| Layer | Role |
|---|---|
| **Git (Superpowers artifacts)** | Source of truth — specs, plans, scope, lifecycle |
| **Linear** | Human dashboard — mirrored status, optional issue links |

**Conductor behavior:**

- Tasks live in approved Superpowers plan files (checkbox syntax)
- On state transitions (`draft → in_progress → review → done`), Conductor syncs status to Linear via optional adapter
- Linear issues link back to spec folder + PR
- **Linear adapter is optional** — framework runs fully without it

**Cursor Marketplace:** [Linear plugin](https://cursor.com/marketplace) enables AI assistants to manage issues; use as adapter implementation, not core dependency.

---

## Cursor Marketplace Plugin Strategy

Treat the [Cursor Marketplace](https://cursor.com/marketplace) as an **adapter catalog**. Core Conductor never imports plugin-specific APIs directly.

```
orchestration/adapters/
  linear/           # optional — sync task status
  arize/            # optional — AI trace export
  observability/    # interface + noop fallback
  subtext/          # optional — verify against running app
```

| Concern | Marketplace plugin | Role |
|---|---|---|
| Task visibility | Linear | Mirror spec/plan status → issues |
| AI observability | Arize | Trace LLM calls, cost, eval workflows |
| Runtime observability | Datadog / Grafana Cloud | Post-deploy monitoring, rollback signals |
| Verify agent work | Subtext | Check work against running application |
| Security gates | "Find vulnerabilities" automation | PR-time security review complement |
| CI triage | "Triage failed GitHub Actions" | Feed failures to Conductor retry loop |
| Code context | Sourcegraph | Better navigation for reviewer roles |

**Non-negotiable for v1:** Superpowers (methodology). All others optional.

---

## Chosen Architecture: Approach 3

Three approaches were evaluated:

| Approach | Summary | Verdict |
|---|---|---|
| **1. Full Conductor CLI first** | Build complete orchestrator before proving pipeline | Too slow for v1; long-term target |
| **2. GitHub Actions as orchestrator** | CI owns execution; Cursor for planning only | Awkward for interactive Gate 1 and local OpenCode runs |
| **3. Thin Conductor + Superpowers spine** | Superpowers for workflow; thin CLI for routing, gates, tracing | **Chosen** — fastest path to full pipeline proof |

### Architecture diagram

```
┌─────────────────────────────────────────────────────────────┐
│  YOU (Product Owner)                                        │
│  Gate 1: approve spec │ Gate 2: PR review │ Gate 3: deploy  │
└────────────┬───────────────────────────────┬──────────────────┘
             │                               │
┌────────────▼────────────┐     ┌────────────▼────────────────┐
│  CURSOR + SUPERPOWERS   │     │  LINEAR (optional mirror)    │
│  brainstorm → spec      │     │  human visibility dashboard  │
│  writing-plans → plan   │     └─────────────────────────────┘
└────────────┬────────────┘
             │ approved spec + plan
┌────────────▼────────────────────────────────────────────────┐
│  CONDUCTOR (thin CLI, TypeScript)                           │
│  · parse plan tasks + file scopes                           │
│  · route: Cursor (strong) vs OpenCode (cheap)               │
│  · git worktree per parallel task                           │
│  · invoke roles (YAML definitions)                          │
│  · run gates locally before CI                              │
│  · write trace JSONL + cost invoice                         │
│  · sync status → Linear adapter                             │
└────────────┬────────────────────────────────────────────────┘
             │
┌────────────▼────────────┐  ┌──────────────┐  ┌─────────────┐
│  OPENCODE (cheap model) │  │  GITHUB CI   │  │  MARKETPLACE│
│  backend/frontend/QA    │  │  lint, test, │  │  plugins    │
│  implementation       │  │  SonarCloud  │  │  (Arize,    │
└─────────────────────────┘  │  deploy stg  │  │   Subtext…) │
                             └──────────────┘  └─────────────┘
```

### Repo layout

```
ai-agents-orchestration/
├── orchestration/              # reusable framework
│   ├── conductor/              # thin CLI (grows over time)
│   ├── roles/                  # YAML role definitions (see architecture doc §2)
│   ├── adapters/               # linear, arize, noop fallbacks
│   ├── gates/                  # gate runner config
│   └── templates/
│       └── feature-brief.md
├── project/                    # test harness app
│   ├── apps/web/               # Next.js App Router
│   ├── packages/db/            # Prisma schema + client
│   ├── skills/                 # stack-specific skills (dynamic discovery)
│   ├── docs/superpowers/
│   │   ├── specs/
│   │   └── plans/
│   ├── AGENTS.md
│   └── .github/workflows/
└── ai-agent-orchestration-architecture.md
```

---

## Pipeline (v1 target — full §4 from architecture doc)

1. **Feature brief** (you) — problem, outcome, constraints, acceptance criteria
2. **Plan & spec** (Superpowers: brainstorm → writing-plans in Cursor) — Gate 1 approval
3. **Task routing** (Conductor) — tool + model per task based on risk tier and file paths
4. **Execution** (engineer roles via OpenCode/Cursor) — isolated git worktree; bounded self-critique
5. **Scope-conformance check** — diff vs plan file paths before CI
6. **Quality gates (CI)** — lint, type-check, tests, SonarCloud, secret scan; retry cap 2 then escalate
7. **QA + Code reviewer** — separate invocations; one bounded revision round
8. **Gate 2 — PR review** (you)
9. **Deploy** — auto staging; manual production (Gate 3)
10. **Post-deploy** — monitoring; docs-writer async; lessons-learned proposals (human-approved)

### Model routing (from architecture doc)

| Trigger | Tool + model |
|---|---|
| Planning / architecture | Cursor + strong model |
| Standard implementation, tests | OpenCode + cheap model |
| Retry after 1 failure | Same model, error context only |
| Retry after 2 failures, high-risk, auth/payments/migrations | Escalate to strong model |
| Security-sensitive paths | Always strong model |
| Ambiguous architecture (planning only) | Multi-agent debate (rare, expensive) |

---

## Roles (from architecture doc — wire incrementally in v1)

| Role | Activates when | Model tier |
|---|---|---|
| Tech lead / Planner | Every feature | Strong |
| Architect | Data models, API contracts, cross-cutting | Strong |
| Backend engineer | Server-side tasks | Cheap |
| Frontend engineer | UI tasks | Cheap |
| QA engineer | Every task (separate from implementer) | Cheap–mid |
| Security reviewer | Auth, payments, PII, secrets | Strong, always |
| Code reviewer | Every PR | Mid |
| Release engineer | CI/CD, infra, deploy | Cheap–mid |
| Docs writer | After merge; periodic drift check | Cheap |

Separation of duties enforced at permission layer (reviewers read-only).

---

## Dynamic Skill Discovery

**Goal:** Conductor and agents find relevant skills (UI, UX, database, etc.) without hardcoding every stack.

**Proposed mechanism (v1):**

1. **Skill index** — `project/skills/index.yaml` lists available skills with tags (`nextjs`, `prisma`, `auth`, `ui`, `testing`)
2. **Task context matching** — Conductor matches plan task labels/file paths to skill tags
3. **Skill injection** — matched `SKILL.md` files attached to role invocation context
4. **On-demand creation** — if no skill matches, planner proposes new skill; human approves before use (aligns with self-improvement gate)
5. **Reuse** — `skills/<stack>/SKILL.md` portable across projects with same stack

**Future:** integrate [find-skills](https://skills.sh) or marketplace skill catalogs as optional adapter.

---

## Self-Improvement (human-in-the-loop)

Agents may **propose** but never auto-merge:

| Artifact | What agents can propose |
|---|---|
| `docs/lessons-learned.md` | Post-incident patterns |
| `.cursor/rules/`, `AGENTS.md` | Conventions from repeated failures |
| `project/skills/` | New or updated stack skills |
| `orchestration/roles/` | Role prompt refinements |
| ESLint / custom lint rules | Rejected patterns → machine-checked rules |
| Routing config | Model/tool routing adjustments |

**Trust ramp and auto-tuning deferred** until trace data exists and human-in-the-loop proves stable.

---

## Deterministic Quality Gates

### Local (Conductor pre-CI)

- ESLint
- TypeScript (`tsc --noEmit`)
- Vitest (unit)
- Scope check (diff vs plan paths)
- Gitleaks (secrets scan before LLM context)

### CI (GitHub Actions)

- All local gates
- Vitest with coverage threshold (TBD — tune from harness)
- Playwright (smoke / critical paths)
- Semgrep OSS (SAST)
- `npm audit` (dependency vulnerabilities)
- SonarCloud (code quality + security hotspots)
- Build verification

### Deferred to v1.1

- OWASP ZAP (DAST against staging)
- Snyk (if `npm audit` insufficient)

### Failure handling

- Failures feed back to a **fresh** execution session (not accumulating transcript)
- Cap: 2 retries on same model, then escalate to strong model or flag human
- Never allow disabling checks to pass

---

## Observability

### Trace format (JSONL per feature)

Each task logs:

```json
{
  "task_id": "feat-001-task-3",
  "spec_ref": "docs/superpowers/specs/2026-07-06-...",
  "plan_ref": "docs/superpowers/plans/2026-07-06-...",
  "role": "backend-engineer",
  "tool": "opencode",
  "model": "deepseek-v4-flash",
  "events": [
    {"ts": "...", "type": "invocation_start"},
    {"ts": "...", "type": "gate_result", "gate": "eslint", "passed": true},
    {"ts": "...", "type": "invocation_end", "tokens": 12400, "cost_usd": 0.02}
  ],
  "outcome": "pr_opened"
}
```

**Storage:** `orchestration/traces/<feature-id>/` (gitignored or committed — TBD)

### Cost invoice

Per-feature rollup: spend by role, model, tool — drives future routing rule tuning.

### Optional marketplace integrations

- **Arize** — LLM trace export, eval workflows
- **Datadog / Grafana** — post-deploy error rates for rollback agent

### Orchestration evals (from architecture doc)

Golden set of past tasks replayed periodically to catch routing regressions.

---

## Test Harness App

**Purpose:** Exercise full pipeline, not ship a product.

**Suggested app:** Simple habit tracker or task CRUD with auth — enough surface for:

- Frontend + backend engineer role split
- Auth path → security reviewer activation
- Prisma migrations → architect/escalation path
- UI + API + DB integration tests
- Staging deploy + post-deploy monitoring hook

**Stack:**

| Layer | Choice |
|---|---|
| Framework | Next.js (App Router) |
| Database | PostgreSQL |
| ORM | Prisma |
| Auth | NextAuth or similar (TBD at implementation) |
| Unit tests | Vitest |
| E2E | Playwright |
| CI | GitHub Actions |
| Staging deploy | Vercel or Railway (TBD) |

**Harness features (minimal set to prove pipeline):**

1. User registration / login (auth — triggers security reviewer)
2. CRUD for habits or tasks (backend + frontend split)
3. Basic dashboard UI
4. API route + Prisma model
5. Test coverage above threshold
6. One deliberate high-risk task in spec to test escalation

---

## Guardrails (inherited from architecture doc)

- Least privilege per role; reviewers read-only by permission
- Hard denylist: force-push, out-of-worktree writes, CI secret modification, destructive migrations, disabling checks, arbitrary outbound network
- Secrets never reach cheap-model providers (pre-LLM scan)
- Escalation required: production deploy, auth/billing changes, secret rotation, destructive migrations
- Prompt injection defense on external content
- Audit trail: every command logged against task ID
- Rules/skills/specs are version-controlled artifacts

---

## Build Order (recommended)

1. Feature brief template + repo scaffold (orchestration + project monorepo)
2. One real feature through Superpowers by hand (validate spec/plan format)
3. Minimal Conductor: parse plan, worktree, OpenCode invoke, local gates, draft PR
4. Retry/escalation logic
5. QA + code reviewer separate invocations; scope-conformance check
6. GitHub Actions CI (SonarCloud, full gate stack)
7. Trace JSONL + cost invoice
8. Linear adapter (optional sync)
9. Remaining roles via activation triggers
10. Marketplace plugin adapters (Arize, Subtext) as needed
11. Self-improvement proposal workflow (lessons-learned PRs)

---

## Open Questions (for next session)

- [ ] Approve Approach 3 architecture diagram and repo layout
- [ ] Exact test coverage threshold for harness
- [ ] NextAuth vs alternative auth library
- [ ] Staging host: Vercel vs Railway
- [ ] Trace JSONL: commit to repo vs gitignored local only
- [ ] SonarCloud project setup and quality gate thresholds
- [ ] Retry cap tuning (architecture doc assumes 2)
- [ ] Which marketplace plugins to wire first (Linear vs Arize vs Subtext)
- [ ] Harness app choice: habit tracker vs alternative
- [ ] Dynamic skill index format (`index.yaml` schema)
- [ ] Section 2+ design detail: components, data flow, error handling (brainstorming was paused before completion)

---

## Brainstorming Progress

| Step | Status |
|---|---|
| Explore project context | Done |
| Clarifying questions | Done |
| Propose 2–3 approaches | Done — Approach 3 recommended |
| Present design sections | **Partial** — Section 1 (architecture) presented, awaiting approval |
| Write design doc | **This file** |
| Spec self-review | Pending |
| User review | Pending |
| Invoke writing-plans skill | Pending (after approval) |

**Next session:** Review this spec, approve or revise, then continue design sections (components, data flow, error handling, testing) and proceed to implementation plan.
