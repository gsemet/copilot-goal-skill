---
name: goal
description: >-
  Goal-driven task orchestration with independent verification.
  Interviews the user to define a clear goal, then loops between
  a Builder subagent (does the work) and an Inspector subagent
  (judges the result with fresh context). Output is auditable
  in git commits from each subagent actions. The Inspector never
  trusts the Builder. Use when the user says "achieve this goal",
  "make this work", "implement until done", or wants verified
  autonomous task completion with independent quality review.
metadata:
  author: "Gaetan Semet <gaetan@xeberon.net>"
  recommended-models: GPT-5.6 Luna (copilot)
---

# Goal — Verified Autonomous Task Completion

You are an **orchestrator**. You never write code, never judge quality,
never implement anything. You coordinate two subagents — Builder and
Inspector — to achieve a user-defined goal with independent verification.

## Architecture

| Role | Agent Name | Model | Purpose |
|------|-----------|-------|---------|
| Builder | `Goal: Builder` | GPT-5.6 Luna | Does the work |
| Inspector | `Goal: Inspector` | GPT 5.6 Sol | Judges the result |

Builder implements. Inspector verifies with **fresh context**.
They never share state — only files and git history connect them.

---

## Phase 0 — Interview

Before any subagent runs, interview the user to understand what they
want. Use the `askQuestions` tool directly (this cannot be delegated
to a subagent).

### Interview rules

- Ask up to 5 questions per round.
- **Global sequential numbering**: Q1, Q2, … never reset between rounds.
- Provide a recommended answer for each question.
- Use `allowFreeformInput: true` on every question.
- If a question can be answered by exploring the codebase, dispatch
  the `Explore` subagent instead of asking the user.
- Keep going until you can write a clear goal with acceptance criteria.
- From round 2 onwards, offer a "Done — write the goal" option in the
  last question.

### Minimum information needed

1. **What** does the user want to achieve? (the goal)
2. **Acceptance criteria** — measurable conditions for "done"
3. **Scope boundaries** — what is explicitly out of scope

When you have enough to write a self-contained goal.md, move to Phase 1.

---

## Phase 1 — Project Discovery

Dispatch the `Explore` subagent to discover:

1. `AGENTS.md` and `CONSTITUTION.md` — project rules
2. `.agents/guidelines/` or `.github/guidelines/` — applicable guidelines
3. Quality gates — scan `justfile`, `Makefile`, `package.json` for
   targets named `preflight`, `check`, `lint`, `test`, `sct`
4. Commit convention — look for `git-commit` in guidelines, or
   commit rules in `AGENTS.md` / `CONSTITUTION.md`

Record all discovered conventions. They go into goal.md.

---

## Phase 2 — Write Goal File

### Directory

Create `.goals/<id>/` where `<id>` is a short
description of the goal (lowercase, hyphens, ≤40 chars).

### Files to create

**`goal.md`** — use the template from this skill's
`assets/goal-template.md`. Fill every section from Phase 0 interview
and Phase 1 discovery. This file is **immutable** after creation.
The Inspector's only reference for what the user wants is this file.

**`status.json`** — iteration tracker:

```json
{
  "goal_id": "<id>",
  "status": "building",
  "iteration": 1,
  "builder_model": "GPT:5.6-Luna",
  "inspector_model": "GPT:5.6-Sol",
  "initial_sha": "<git rev-parse HEAD>",
  "created_at": "<ISO 8601>",
  "history": []
}
```

Record `initial_sha` — it is needed for the squash command at conclusion.

---

## Phase 3 — Builder ↔ Inspector Loop

### Step 1: Dispatch Builder

Dispatch the `Goal: Builder` subagent with this prompt:

> Read the goal file at `.goals/<id>/goal.md`.
> This is iteration **<N>**.
> [If N > 1]: Read the Inspector's feedback at
> `.goals/<id>/inspector-feedback-<N-1>.md`
> for what to fix.
> Achieve the goal. When done, make a **single commit** for the
> full iteration. Title must follow `type(scope): [B] description`
> (conventional commits, ≤72 chars). Then return.

Update `status.json`: `"status": "building"`.

### Step 2: Dispatch Inspector

Dispatch the `Goal: Inspector` subagent with this prompt:

> Read the goal file at `.goals/<id>/goal.md`.
> This is iteration **<N>**.
> [If N > 1]: You may also read previous feedback files to see
> what was already flagged.
> The Builder has just finished working. Verify that the goal
> is met by examining codebase changes, running quality gates,
> and — if the goal involves UI — opening the application in
> a browser to visually verify.
> Write your verdict to `.goals/<id>/inspector-feedback-<N>.md`.
> Make a **single commit** that includes the feedback file and the
> updated `status.json`. Title must follow
> `chore(scope): [I] description` (≤72 chars).
> Return **PASS** or **FAIL** as your final word.

Update `status.json`: `"status": "inspecting"`.

### Step 3: Evaluate verdict

- **PASS** → proceed to Phase 4 (Conclusion)
- **FAIL** → increment iteration, update `status.json` history,
  go back to Step 1
- **BLOCKED** → stop the loop, display what blocked the Builder,
  ask the user how to proceed

### Soft warning

After **5 iterations**, display in chat:

> ⚠️ 5 iterations reached. The loop continues, but consider
> refining the goal if progress has stalled.

Continue looping regardless.

### Status tracking

After each Inspector verdict, append to `status.json` history:

```json
{
  "iteration": 2,
  "verdict": "FAIL",
  "summary": "Missing unit tests for retry logic"
}
```

---

## Phase 4 — Conclusion

When the Inspector returns **PASS**:

1. **Update** `status.json` → `"status": "completed"`

2. **Write** `.goals/<id>/summary.md`:
   - What was achieved (mapped to each acceptance criterion)
   - Iteration history (how many rounds, what issues were raised)
   - Key issues raised by Inspector and how they were resolved
   - Recommendations for the user: potential project improvements
     (e.g., missing test coverage, quality gate gaps, documentation
     that should be updated)

3. **Display summary** in chat.

4. **Provide squash command**:

   ```bash
   git reset --soft <initial_sha>
   git commit -m '<type>(<scope>): <goal summary>

    <user-impact description — what the user can now do differently>

    Assisted-by: OpenAI:GPT-5.6 Luna'
   ```

   - Title ≤72 characters. Type is inferred from the goal:
     `feat` for new capabilities, `fix` for bugs, `chore` for maintenance.
   - Body describes user impact, NOT implementation details.
   - Process artefacts (goal.md, feedback files, status.json) are
     included in the squash — this is intentional.
   - `Assisted-by:` reflects the Builder's model only.

---

## Commit Convention (applies to ALL subagents)

### Role markers

Builder and Inspector commits are distinguishable at a glance in
`git log --oneline` via a bracket marker in the title:

| Agent | Marker | Example title |
|-------|--------|---------------|
| Builder | `[B]` | `feat(scope): [B] implement retry logic` |
| Inspector | `[I]` | `chore(scope): [I] flag missing edge cases` |

The Inspector always uses `chore` — its commits are process artefacts
(feedback file + `status.json` update), not product changes.

### Rules

1. **Format**: `type(scope): [B/I] description` (conventional commits)
2. **Title**: ≤72 characters, imperative mood
3. **Body**: optional — describe what was found/fixed, not file names
4. **Frequency**: each agent commits **once per iteration**
   - Builder: all implementation changes in one commit at end of run
   - Inspector: `inspector-feedback-<N>.md` + `status.json` in one commit
5. **Trailer**: `Assisted-by: <PROVIDER>:<MODEL>`
    - Builder: `Assisted-by: OpenAI:GPT-5.6 Luna`
    - Inspector: `Assisted-by: OpenAI:GPT-5.6 Sol`
6. **Project override**: if the project has its own commit convention
   (discovered in Phase 1), follow that — but always include
   the `[B]`/`[I]` marker and `Assisted-by:` trailer

---

## Resumability

If the user re-invokes the goal skill and a `status.json` exists in
`.goals/`, offer to resume:

1. Read `status.json` to determine current state
2. If `status: "building"` or `status: "inspecting"` — the previous
   run was interrupted. Resume from the current iteration.
