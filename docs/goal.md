# Goal Skill: Verified Autonomous Task Completion

The `goal` skill helps GitHub Copilot carry a development task from an initially
rough request to a verified result. It turns the request into a written goal,
then coordinates an implementation agent and an independent inspection agent
until the acceptance criteria are satisfied.

## What it provides

The skill provides a **goal-driven orchestration loop** rather than another
implementation framework. It is responsible for:

- clarifying the request and defining measurable acceptance criteria;
- discovering the repository's conventions, quality gates, and commit rules;
- recording the agreed scope in an immutable `.goals/<id>/goal.md` file;
- dispatching a Builder to implement the work;
- dispatching a separate Inspector with fresh context to verify the result; and
- repeating implementation and verification when the Inspector finds a gap.

The Builder does the coding. The Inspector does not trust the Builder's claims and
checks the repository and its quality gates independently. The orchestrator
coordinates them and decides whether to continue, conclude, or report a blocker.

## When to use it

Use the skill when the desired outcome matters more than a single suggested patch,
for example:

- “Achieve this goal in the repository.”
- “Make this work and keep fixing it until it passes.”
- “Implement the feature and verify that it is complete.”
- “Have another agent independently review the result before declaring success.”

It is especially useful for changes with several acceptance criteria, tests or
quality gates, multiple files, or a user-visible behavior that needs independent
verification.

## How it works

### 1. Interview the user

Before any implementation starts, the skill asks focused questions, up to five
per round, until it knows:

1. what should be achieved;
2. how completion will be measured; and
3. what is explicitly out of scope.

Questions that can be answered by inspecting the repository are delegated to an
exploration step instead of being unnecessarily asked of the user.

### 2. Discover the project rules

The skill inspects the target repository for `AGENTS.md`, `CONSTITUTION.md`,
scoped guidelines, task-runner commands, quality gates, and commit conventions.
Those findings become part of the written goal so that the implementation loop
uses the project's own rules.

### 3. Write the source of truth

The skill creates a short-lived goal identifier and writes:

```text
.goals/<id>/
├── goal.md                     # User goal, criteria, scope, and project rules
└── status.json                 # Iteration state and history
```

`goal.md` is immutable after creation. It contains the refined goal, acceptance
criteria, scope boundaries, quality-gate command, commit convention, and relevant
guidelines. This gives both agents the same target and prevents the definition of
done from drifting during implementation.

### 4. Run the Builder → Inspector loop

For each iteration:

1. **Builder** reads `goal.md`, implements the complete iteration, runs the
   project's quality gate, and creates one Builder commit.
2. **Inspector** reads `goal.md` with fresh context, examines the Builder's diff,
   runs the relevant checks, and optionally opens a browser for UI verification.
3. The Inspector writes a detailed PASS or FAIL report and creates one Inspector
   commit containing the report and updated status.
4. A PASS moves the workflow to conclusion. A FAIL records the issue and sends the
   next Builder back with the Inspector's feedback. A BLOCKED result stops the
   loop and surfaces the blocker to the user.

The loop has no fixed iteration cap. It displays a warning after five iterations
so the user can reconsider an unclear or stalled goal, but it can continue.

### 5. Conclude with an auditable summary

After a PASS, the skill marks the goal complete and writes:

```text
.goals/<id>/
├── goal.md
├── status.json
├── inspector-feedback-01.md   # One report per inspection iteration
├── ...
└── summary.md                 # Criteria mapping and iteration summary
```

It also provides a ready-to-use `git reset --soft` and commit command for
squashing the iteration commits if the user wants one final product commit. The
process artifacts remain available in the history unless the user chooses to
remove or reorganize them.

## The two agents

Run the Goal skill with **GPT-6 Luna (copilot)**. The default subagent models are:

| Role | Model | Responsibility |
| --- | --- | --- |
| Builder | GPT-5.6 Luna (copilot) | Implements the goal, runs quality gates, and commits one iteration. |
| Inspector | GPT-6.1 Sol (copilot) | Independently verifies the goal, records evidence, and returns PASS or FAIL. |

The agents share no conversational state. Files and Git history are the hand-off
boundary. This separation makes the acceptance criteria observable and reduces
the chance that the same assumptions survive from implementation into review.

## What it brings to the user

- **A clearer definition of done:** the interview turns an ambiguous request into
  criteria that another agent can verify.
- **Independent quality control:** the Inspector is deliberately given fresh
  context and is instructed to distrust unverified claims.
- **Self-correction:** failures become concrete feedback for the next Builder
  iteration instead of being silently ignored.
- **A visible audit trail:** each implementation and inspection iteration is
  represented in Git commits and `.goals/<id>/` artifacts.
- **Project-native execution:** the loop discovers and uses the repository's own
  tests, lint commands, conventions, and guidance.
- **Resumability:** an existing `status.json` lets a later invocation determine
  whether a prior run was interrupted and offer to continue it.

## Invocation

Invoke it from Copilot Chat with a goal-oriented request, for example:

```text
/copilot-goal-skill:goal Add retry logic to the API client and verify it with tests
```

The exact request should describe the desired outcome. The interview supplies the
missing detail before any Builder work begins.

## Boundaries and prerequisites

- The orchestrator does not implement code or make the quality judgment itself;
  those responsibilities belong to the Builder and Inspector agents.
- A failed inspection does not automatically mean the goal is wrong. It means the
  next iteration must address the evidence in the Inspector report.
- A blocked iteration is surfaced to the user rather than hidden behind repeated
  retries.
- Efficient autonomous operation benefits from Copilot YOLO mode because the loop
  needs to run repository tools and subagents repeatedly.
- The skill complements, rather than replaces, a project's tests, linters, and
  other deterministic quality gates.

## In short

The `goal` skill is a structured, evidence-backed way to delegate a complete
repository change: define the outcome, implement it, inspect it independently,
retry when necessary, and finish with a traceable record of why the work is
considered complete.
