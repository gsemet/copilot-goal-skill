# Goal Skill for GitHub Copilot

**Verified autonomous task completion** — an orchestrator that bounces
between a Builder (does the work) and an Inspector (judges the result)
until the goal is met.

> [!TIP]
> You need to enable [Copilot YOLO mode](vscode://settings/chat.tools.global.autoApprove)
> to use this skill efficiently.

![Goal Skill Workflow](images/goal-loop.svg)

## Important: Why Not Just Autopilot?

[Autopilot](https://code.visualstudio.com/updates/v1_124#_autopilot-preview) is a similar feature
directly provided by Copilot. It used to use hardcoded rules to find out if a task is done,
which was not reliable.

> [!IMPORTANT]
>
> Starting [VS Code 1.124](https://code.visualstudio.com/updates/v1_124#_autopilot-preview),
> **Autopilot CAN be configured to use an utility model to evaluate to completion of the task**,
> instead of relying on custom rules.
>
> For that you need to set [chat.autopilot.advanced.enabled](vscode://settings/chat.autopilot.advanced.enabled)
> to `true` in your VS Code settings.
>
> However, **this skill is not deprecated** by Autopilot if you care about the following:
>
> - the `goal.md` is clearly defined, written in your repository
> - Use a smarter model for inspector (Autopilot uses a small utility model)
> - Git audit trail (you can see in the history the different review, retry, ...)

## How It Works

1. **Relentless interview** — asks clarifying questions until it can
   write a clear goal with measurable acceptance criteria
2. **Project discovery** — explores your repo for conventions, quality
   gates, commit rules
3. **Writes a goal file** — immutable `goal.md` with acceptance criteria
   that becomes the single source of truth
4. **Builder → Inspector loop** — the Builder implements and commits;
   a separate Inspector (different model, fresh context) independently
   verifies against the goal; if FAIL, the Builder gets feedback and
   tries again
5. **Git commit trail** — each iteration is committed,
   so you can review the history of coder and inspector decisions
6. **Summary and squash** — when the Inspector says PASS, you get a
   summary and a ready-to-use squash command

## Architecture

| Agent | Model | Role |
|-------|-------|------|
| **Builder** | GPT-5.6 Luna | Implements the goal |
| **Inspector** | GPT 5.6 Sol | Verifies independently |

The Inspector runs on a separate model with fresh context by design —
it forces clear, verifiable acceptance criteria. If the Inspector
can't tell whether the goal is met, the goal was poorly defined.

## Installation

### Marketplace

Install this project as Marketplace in [VS code settings](vscode://settings/chat.plugins.marketplaces):

```raw
https://github.com/gsemet/copilot-goal-skill.git
```

### Manual

Clone this repo and point VS Code at it as a Copilot plugin:

```jsonc
// .vscode/settings.json
{
  "github.copilot.chat.agent-plugins": [
    "/path/to/copilot-goal-skill/plugins/copilot-goal-skill"
  ]
}
```

Or install from the marketplace if your setup supports
`marketplace.json`-based plugins.

## Usage

Invoke the skill through Copilot chat:

```raw
/copilot-goal-skill:goal Add retry logic to the API client
```

The skill will:

1. Ask you clarifying questions until the goal is clear
2. Write `.goals/<id>/goal.md`
3. Start the Builder → Inspector loop
4. Show a summary and squash command when done

## File Structure

When the skill runs, it creates in your project:

```raw
.goals/<id>/
├── goal.md                     # What must be achieved (immutable)
├── status.json                 # Iteration tracking + resumability
├── inspector-feedback-01.md    # First iteration feedback
├── inspector-feedback-02.md    # Second iteration (if needed)
└── summary.md                  # Final report (after PASS)
```

## Plugin Structure

```raw
copilot-goal-skill/
├── .github/plugin/marketplace.json
├── images
│   └── goal-loop.svg             # Animated workflow diagram
├── README.md
├── LICENSE
└── plugins/copilot-goal-skill/
    ├── .github/plugin/plugin.json
    ├── skills/goal/
    │   ├── SKILL.md              # Orchestrator instructions
    │   └── assets/
    │       └── goal-template.md  # Template for goal files
    └── agents/
        ├── goal-builder.agent.md
        └── goal-inspector.agent.md
```

## Configuration

| Setting | Default | Notes |
|---------|---------|-------|
| Builder model | GPT-5.6 Luna | In `goal-builder.agent.md` |
| Inspector model | GPT 5.6 Sol | Independent verification model |
| Iteration limit | None | Soft warning at 5 |
| Commit convention | Conventional commits | Overridden by project's own |

## License

MIT
