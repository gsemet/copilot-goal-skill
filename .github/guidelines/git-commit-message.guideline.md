---
name: Git Commit Message Guideline 2.0
description: Guidelines for writing conventional commits that communicate intent and user impact
metadata:
  owner: Gaetan Semet <gaetan.semet@ampere.cars>
  keywords: [git, commit, conventional, message, changelog]
  guideline-id: 45c42e46-0781-4954-a410-1f380f5553f3
---

# Git Commit Message Guideline

Write clear, user-impact focused commit messages following Conventional Commits format.
Commit messages communicate *why* changes were made, enabling automated changelog generation,
bug investigation, and decision-making during upgrades.

**Important**: Focus on user impact, not implementation details.

## Core Rules

### Rule 1: Use Conventional Commit Format

**Apply:** Format every title as `type(scope): description`

Note: scope is optional.

**Why:** Enables automated changelog generation and consistent pattern parsing.

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `chore`, `build`, `revert`

**Examples:**

```text
feat(auth): add two-factor authentication support
fix(api): resolve request timeout in user endpoint
docs(readme): update installation instructions
perf(cache): optimize query performance by 40%
test(validators): add email format validation tests
```

---

### Rule 2: Keep Title Under 50 Characters, Body Under 72 Characters per Line

**Apply:** Enforce character limits for scannability and terminal compatibility.

**Why:** Short titles force clarity; wrapped body text maintains readability in terminals and email clients.

**Exception**: URLs, hashes, or other unbreakable strings in body may exceed limits. Use discretion.

**Example:**

```text
feat(cache): implement LRU eviction policy

Reduces memory usage in long-running processes by
automatically removing least-recently-used items.

Changes:
- Cache drops oldest accessed items upon limit
- Configurable cache size (default 1000)
- < 2% performance overhead on reads

Users can set CACHE_SIZE environment variable.
```

---

### Rule 3: Focus Body on User Impact, Not Implementation Details

**Apply:** Describe what users gain and must know; exclude refactoring details, internal functions, and test additions.

**Why:** Users deciding whether to upgrade, developers integrating changes, and bug investigators need user-level context—not code structure details.

**Do Not** describe function-level changes, test modifications, or test counts.
CI provides the authoritative check statistics.

**Explicit check before committing**: Ask yourself — "Does the commit body
read like a diff summary?" If it lists files changed, methods added, or
test counts, rewrite it. The body must answer: "What can a user now do
differently, or what error/limitation is now resolved?"

**Example:**

```text
fix(api): allow null values in optional response fields

Optional fields now omitted from JSON when empty,
reducing response payload by ~15% for sparse data.

Migration:
- Check `field in response` instead of `field != null`
- Response schema updated in API reference
```

---

### Rule 4: Include Breaking Changes with Migration Guidance

**Apply:** When a breaking change is introduced, use `!` in title and `BREAKING CHANGE:` section.
Provide explicit migration steps.

**Why:** Breaking changes require user action; clear guidance reduces upgrade confusion.

**Example:**

```text
feat(api)!: change pagination to cursor-based tokens

Cursors improve performance with large datasets.

BREAKING CHANGE: Replaced `pagination_offset` and
`pagination_limit` with `pagination.cursor`.

Migration:
Old: GET /users?limit=10&offset=20
New: GET /users?limit=10&cursor=xyz123

Update code to use `response.pagination.cursor`
in next request instead of offset/limit.
```

### Rule 5: Keep ownership separate from AI assistance

**Apply:** Do not add a `Signed-off-by` line unless explicitly requested by a human.
The human may add it to indicate that they take ownership of the change. It is a
DCO attestation, not an AI attribution.

### Rule 6: Attribute the assisting model for AI-generated commits

**Apply:** When the content of a commit was generated mainly with AI assistance,
include exactly one `Assisted-by` trailer at the end of the message body:

```text
Assisted-by: PROVIDER:MODEL [FRAMEWORK]
```

- **PROVIDER** is the underlying model vendor, not the chat interface or IDE
  integration. For example, use `OpenAI`, not `GitHub Copilot`.
- **MODEL** is the exact display name reported by the active model selection or
  current session metadata, for example `GPT-5.6 Luna`.
- **FRAMEWORK** is optional and names the SDD orchestration framework that drove
  the implementation. Omit it when assistance was provided directly.

**Determine the value from the current session only:**

1. Use the provider and model identifier exposed by the active harness or session
  metadata.
2. For Craftsman sessions, use the current session's
  `Craftsman-Session-Model-Main` value or equivalent current usage record.
3. Never copy an `Assisted-by` value from a previous commit, recent `git log`,
  an example, or another session; those values describe historical assistance.
4. If the current model cannot be verified, stop and obtain that information
  before committing. Never guess a model or substitute the IDE/chat interface.

**Correct examples:**

```text
# Direct AI assistance (no agentic framework):
Assisted-by: Anthropic:Claude Sonnet 4.6

# AI assistance via Craftsman Ralph Loop:
Assisted-by: Anthropic:Claude Sonnet 4.6 Craftsman

# GPT via Cursor, no framework:
Assisted-by: OpenAI:GPT-4o
```

**Wrong (do not write these):**

```text
Assisted-by: GitHub Copilot        # ❌ interface name, not model
Assisted-by: Cursor                # ❌ IDE name, not model
Assisted-by: AI                    # ❌ too vague
```

A human may add a `Signed-off-by` line to indicate they take ownership of the change.
