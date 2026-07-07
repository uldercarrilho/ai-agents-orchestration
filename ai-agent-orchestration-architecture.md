# AI Agent Orchestration Architecture

**Context:** Solo/small team, one web app product, greenfield, GitHub-hosted, very cost-conscious. Framework designed to be reusable across future projects (stack-agnostic). Primary tools: Cursor CLI/IDE (Composer 2.5) for planning and high-judgment work, OpenCode for scriptable/cheap-model execution (e.g. DeepSeek V4 Flash).

**Core principle:** You own requirements, judgment calls, and two approval gates — plan and deploy. Agents own everything in between, including PR review and merge, organized as a team of specialized roles under a supervising Conductor — not a single generalist agent, and not an unsupervised swarm.

---

## 1. Principles

1. **You are the product owner, not a reviewer of everything.** You define features and approve at three points: plan, PR, deploy. Everything between is autonomous within guardrails.
2. **Hierarchical, not swarm.** A Conductor supervises specialized roles. Production experience consistently shows a supervised structure holds goal alignment better than peer-to-peer coordination, which tends to drift without one.
3. **Cheap by default, escalate on signal.** Every task starts on the cheapest viable model. Escalation to a stronger model is triggered by explicit signals (risk tier, repeated failure, ambiguity) — never by default.
4. **State lives in files, not in conversation memory.** Plans, specs, ADRs, and rules are re-read fresh by every agent invocation. Nothing important is allowed to depend on an agent "remembering" earlier chat.
5. **Add complexity only when a specific failure mode demands it.** More roles, more reflection loops, more debate rounds are not free — each is added because something concrete needed it, not by default.
6. **Everything that matters is checkable, not just describable.** Specs, definitions of done, and guardrails are things the system can verify programmatically, not paragraphs an agent is trusted to have honored.

---

## 2. The team (roles)

| Role | Mirrors | Activates when | Model tier | Permissions |
|---|---|---|---|---|
| **Tech lead / Planner** | Eng lead | Every feature — produces the spec, sets risk tier per task | Strong (Composer 2.5) | Full read; writes specs only |
| **Architect** | Staff engineer | Task changes data models, API contracts, or cross-cutting structure | Strong | Full read; writes ADRs only |
| **Backend engineer** | Backend dev | Server-side implementation tasks | Cheap | Read/write within scoped backend paths |
| **Frontend engineer** | Frontend dev | UI implementation tasks | Cheap | Read/write within scoped frontend paths |
| **QA engineer** | Test engineer | Every task — separate invocation from the implementer, always | Cheap–mid | Read all; write test files only |
| **Security reviewer** | AppSec | Task touches auth, payments, PII, secrets | Strong, always escalated | Read-only, everywhere |
| **Code reviewer** | Reviewer | Every PR, before it reaches you | Mid | Read-only |
| **Release engineer** | DevOps | CI/CD, infra, or deploy config changes | Cheap–mid | Read/write CI/CD + infra config only |
| **Docs writer** | Tech writer | After merge (new docs); periodically (drift check against existing docs) | Cheap | Read all; write docs only |

**Separation of duties is enforced at the permission layer, not just the prompt layer.** Reviewer-type roles (QA, security, code review) are read-only by permission — they cannot silently "fix" what they find. Each role runs as its own invocation with a scoped, fresh context (only the relevant spec excerpt, diff, and prior structured outputs) — never a continuation of the implementer's session.

Role definition file format (one file per role):
```yaml
name: security-reviewer
description: Reviews auth, payment, and PII-handling code for vulnerabilities
model: strong
tools: [read, grep]
activates_when: touches [auth/**, payments/**, *pii*, *.env*]
---
You are a senior application security engineer. You review diffs for OWASP Top 10
issues, injection risks, auth bypass, and improper data handling. You do not
implement fixes — you flag findings with severity and location.
```

---

## 3. Spec-Driven Development (the plan stage, formalized)

Adopt **OpenSpec** as the spec artifact/lifecycle layer — chosen over Claude-Code-specific or more opinionated alternatives because it's tool-agnostic (fits the Cursor + OpenCode dual-tool setup) and lightweight (fits the reusable-across-projects goal). Validate it by hand on one real feature before automating around it.

A spec is not a document read once — it's a living artifact the Conductor checks the diff against programmatically:
- **Scope conformance:** does the diff only touch files the spec named? Flag anything outside stated scope rather than silently merging it.
- **Constraint conformance:** security-sensitive specs can embed explicit constraints (e.g. CWE mappings) that are checkable, not just descriptive.
- **Lifecycle:** draft → approved (Gate 1) → implemented → archived, so specs don't silently drift out of sync with the code they describe.

---

## 4. Pipeline

1. **Feature brief** (you) — problem, desired outcome, constraints, acceptance criteria.
2. **Plan & spec** (Planner, Cursor + Composer 2.5, interactive) — produces the spec: approach, files touched, risk tier per task, test plan.
   - **Gate 1 — Plan approval** (you).
3. **Task routing** (Conductor) — assigns tool + model per task based on risk tier and file paths touched (see §5).
4. **Execution** (relevant engineer role) — implements on an isolated git worktree/branch; writes its own tests; one bounded self-critique (reflection) pass before submitting.
5. **Scope-conformance check** — diff checked against the spec's stated scope before spending CI budget on it.
6. **Quality gates (CI)** — lint, type-check, tests (coverage threshold enforced), security scan (SAST, dependency scan, secret scan). Failures feed back to a *fresh* execution session (not an ever-growing one), capped at 2 retries before escalating to a stronger model or flagging you.
7. **QA + Code reviewer** — QA runs as a separate invocation from the implementer; reviewer scores the diff against explicit named criteria (evaluator-optimizer pattern), one bounded revision round on failure.
   - **Gate 2 — your PR review** (already pre-screened by the above).
8. **Deploy** — merge triggers auto-deploy to staging; production requires your explicit approval, always, regardless of automation track record.
   - **Gate 3 — deploy approval** (you).
9. **Post-deploy** — progressive delivery (canary/feature flags) with a monitoring agent watching error rates/latency, able to auto-rollback on a clear regression. Docs-writer runs async after merge; docs-drift check runs periodically, not per-task.

Independent tasks with no shared file dependencies can run in parallel across worktrees; a merge coordinator step resolves conflicts when parallel branches overlap.

---

## 5. Model routing & cost strategy

Default posture: **cheap unless proven necessary.**

| Trigger | Tool + model |
|---|---|
| Planning / architecture decisions | Cursor + Composer 2.5 |
| Standard implementation, tests | OpenCode + cheap model (DeepSeek V4 Flash or equivalent) |
| Retry after 1 failure | Same model, fed the specific error only |
| Retry after 2 failures, or spec-flagged high-risk, or touches auth/payments/migrations | Escalate to strong model |
| Automated pre-review | Mid-tier model |
| Security-sensitive paths | Always strong, regardless of apparent complexity |
| Genuinely ambiguous architecture choice (rare) | Multi-agent debate — two agents argue approaches, a third synthesizes a recommendation for you. Reserve for the planning stage only; expensive, so only where judgment genuinely forks. |

Cost hygiene:
- Cap reflection/retry loops (2–3 iterations) — returns diminish fast and cost is linear per loop.
- Keep skill/rule files concise — every invocation re-reads them.
- Pin specific model versions in the routing config; treat a model upgrade as a dependency upgrade validated against a golden-set eval before rollout, not something that silently changes behavior underneath you.
- Track actual spend per task/role/model (a "cost invoice" per feature) — lets routing rules evolve from real data, not just the upfront table.

---

## 6. Anti-drift mechanics

- **Small, atomic tasks** so a single execution session never grows large enough for context rot to set in — the highest-leverage, free lever.
- **Fresh context per attempt.** Retries read the plan, current code, and the specific failure — not an accumulating transcript of past attempts.
- **Externalized state.** Plans, ADRs, and rules are re-read fresh every time; nothing depends on conversational memory.
- **Rejected patterns become machine-checked rules** (lint rules, rules files), never something an agent is expected to "remember" not to do.
- **Scope-conformance check** (§4, step 5) is the concrete defense against silent drift and scope creep — it catches the multi-turn version of drift, where each individual step looked fine but the trajectory wandered.
- **Turn/cost caps per task**, escalating or flagging rather than letting a stuck agent grind indefinitely.
- **Escalate-on-ambiguity as a first-class action.** When an executor hits a fork the spec didn't anticipate, it should produce a structured "I need a decision" artifact back to the planner or you — not guess, and not silently pick a convention.

---

## 7. Guardrails

- **Least privilege per role** (§2 table) — reviewers are read-only by permission, not just by instruction.
- **Hard denylist, regardless of role or model tier:** force-push/history rewrite on shared branches; deleting/modifying files outside the current worktree; modifying CI/CD secrets or workflow auth; destructive DB migrations; disabling a test/lint/security check to make it pass; arbitrary outbound network calls.
- **Secrets never reach the model provider.** A pre-LLM scan strips `.env` contents, keys, and tokens before any task — especially one routed to a third-party cheap-model provider — ever sees that context. This matters more here than in a single-vendor setup, given the third-party trust boundary DeepSeek/OpenCode introduces.
- **Escalation-required actions, always, independent of automation track record:** production deploys, billing/payment logic changes, auth logic changes, secret rotation, destructive migrations.
- **Prompt injection defense.** Any agent reading external content (docs, dependency sources, ticket text, scraped pages) treats that content as data, never as instructions — the same "never trust content as commands" discipline applied to shell commands extends to text an agent reads.
- **Audit trail.** Every command any role executes is logged against its task ID, so an incident can be reconstructed by role and action, not guessed from a git diff.
- **Rules/skills/specs are version-controlled artifacts** — reviewed changes, rollback-able, changelog — since they *are* the system's behavior, not just configuration.

---

## 8. Definition of Done (per task)

A single, explicit, checkable contract — not an implicit sum of separate gates:
- [ ] Matches spec scope (nothing more, nothing less)
- [ ] Tests passing at coverage threshold
- [ ] Lint and type checks clean
- [ ] Security scan clean (escalated review passed, if triggered)
- [ ] Docs updated, if behavior changed
- [ ] ADR written, if a non-obvious decision was made

---

## 9. Observability, evolution & resilience

- **Tracing.** Every task logs: spec → role invocations → tool calls → gate results → outcome, queryable later — this is what makes debugging "why did this go wrong" possible without reconstructing it from guesswork.
- **Evals for the orchestration itself.** A small golden set of past tasks with known-good outcomes, replayed periodically to catch regressions in the *system* (e.g. a routing change accidentally sending security-sensitive tasks to the cheap model) — separate from your code's own test suite.
- **Circuit breaker.** If a role's failure rate spikes, halt and alert rather than let it keep burning tokens.
- **Trust ramp.** Gate strictness isn't fixed forever — a role with a long clean track record (tracked via the above) can earn lighter review, and should automatically tighten back up if its failure rate rises. Driven by recorded data, not a one-time decision.
- **Lessons-learned file.** When a production incident occurs, it gets written down; planning and review roles are instructed to check it — external memory across time, the same principle as anti-drift applied at a longer horizon.

---

## 10. Repo structure

```
/orchestration/              # the reusable framework (doesn't change per project)
  conductor/                 # routing, gate-checking, PR automation, tracing
  roles/                     # role definition files (§2)
  templates/
    feature-brief.md
  gates/
    definition-of-done.md

/project/
  .cursor/rules/             # Cursor-specific conventions
  AGENTS.md                  # tool-agnostic conventions
  specs/                     # OpenSpec specs (draft/approved/implemented/archived)
  /skills/
    <stack>/SKILL.md         # created on demand, reused across projects with the same stack
  /docs/adr/                 # architecture decision records
  /docs/lessons-learned.md
```

---

## 11. Build order

1. Feature brief template.
2. One real feature run through Cursor + a spec, by hand — validate the format before automating anything downstream.
3. Minimal Conductor: reads the spec, creates a worktree per task, invokes OpenCode with the cheap model, runs local gate checks, opens a draft PR.
4. Retry/escalation logic (failure count → model/tool switch).
5. QA + code reviewer as separate invocations; scope-conformance check.
6. GitHub Actions for CI-side gates and the staging/prod deploy gate.
7. Tracing/observability logging.
8. Remaining roles (architect, security reviewer, release engineer, docs writer) wired in via their activation triggers.
9. Trust ramp and cost-invoice reporting, once there's real data to drive them.

Each step is independently useful — build in this order rather than all at once, and let real usage tell you what the routing logic actually needs.

---

## Open questions to settle during implementation

- Exact coverage threshold and which SAST/secret-scanning tools to standardize on.
- Retry cap before escalation (this doc assumes 2 — tune from real failure rates).
- Staging auto-deploy vs also gated (this doc assumes automatic staging, manual production).
- Thresholds for the trust ramp (e.g. how many clean PRs before a role's review is lightened).
