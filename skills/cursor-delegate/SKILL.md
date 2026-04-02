---
name: cursor-delegate
description: >
  Use when delegating implementation work to Cursor's agent CLI. Triggers:
  user mentions Cursor, cursor-agent, "delegate to cursor", wants to use their
  Cursor subscription for code generation, or you need a cheap fast implementer
  for file-editing tasks. Also use when dispatching implementation subagents
  and Cursor is available.
---

# Cursor Delegate

## Overview

Delegate implementation tasks to Cursor's `agent` CLI while you (Claude) handle planning, prompt crafting, and review. You run the command yourself via Bash — the user does not need to copy-paste anything.

**Why:** Cursor Ultra gives generous fast credits. Use `composer-2-fast` for implementation, save Claude tokens for orchestration and review.

## Workflow

```
1. Gather context  — read relevant files, understand the task
2. Craft prompt    — specific, scoped, with file paths and patterns
3. Run agent       — Bash: agent -p --force --trust ...
4. Wait            — command blocks until done, returns JSON
5. Review          — read changed/created files, verify correctness
6. Fix if needed   — either agent --continue or direct Edit
```

## Quick Reference

```bash
# Basic dispatch (run via Bash tool)
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "TASK PROMPT"

# Follow-up fix (same session)
cd /path/to/project && agent -p --force --trust \
  --continue --output-format json \
  "Fix: [SPECIFIC ISSUES]"

# Isolated worktree (parallel-safe)
agent -p --force --trust -w task-name \
  --model composer-2-fast --output-format json \
  "TASK PROMPT"
```

## Required Flags

| Flag | Why |
|------|-----|
| `-p` / `--print` | Non-interactive headless mode |
| `--force` | Allow file writes and shell commands |
| `--trust` | Trust workspace without prompting (essential for headless) |
| `--output-format json` | Structured result with `is_error`, `duration_ms`, `session_id`, `usage` |
| `--model composer-2-fast` | Always use this model. Complex tasks stay with Claude. |

Prompt is a **positional argument** — always last.

## Model Selection

**Always use `composer-2-fast`.** It is the default and handles all delegated tasks well.

If a task is too complex for `composer-2-fast` (multi-file architecture, security-critical, deep reasoning), **do NOT upgrade the Cursor model** — handle it yourself as Claude instead. Cursor is for fast, cheap implementation. Claude is for complex work.

## JSON Output Shape

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 19948,
  "result": "Summary of what was done...",
  "session_id": "efa982fa-...",
  "usage": {
    "inputTokens": 17743,
    "outputTokens": 2565,
    "cacheReadTokens": 32800
  }
}
```

## Step-by-Step

### 1. Gather Context

Before crafting the prompt, read the files that the agent will need to understand:
- The files to modify or create
- Pattern files to follow ("follow the pattern in X.tsx")
- Related types, interfaces, configs

You include this context IN the prompt — the agent starts fresh each call.

### 2. Craft the Prompt

Be specific. Include:
- Exactly what to create or modify
- File paths
- Patterns to follow (reference specific files)
- Constraints ("do NOT modify other files", "run tests when done")

```
# Good prompt
"Create src/components/UserProfile.tsx that displays name, email, avatar.
Follow the pattern in src/components/Dashboard.tsx for styling and exports.
Add unit tests in src/components/__tests__/UserProfile.test.tsx.
Run the tests and make sure they pass."

# Bad prompt
"Make a user profile component"
```

### 3. Run the Agent

Use the Bash tool with a reasonable timeout:

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "YOUR PROMPT HERE"
```

Set Bash timeout to 120000-300000ms depending on task complexity.

### 4. Parse Result

From the JSON output, check:
- `is_error` — did it fail?
- `result` — summary of what was done
- `duration_ms` — how long it took
- `session_id` — needed if you want to `--continue`

### 5. Review

After the agent finishes, YOU review:
- Read the created/modified files with the Read tool
- Verify the implementation matches the spec
- Check for quality issues, missing edge cases
- Run tests if the agent didn't

### 6. Fix if Needed

**Option A — Follow-up via agent** (preferred for multi-file fixes):
```bash
cd /path/to/project && agent -p --force --trust \
  --continue --output-format json \
  "Fix these issues: 1) Missing null check in line 42. 2) Wrong CSS class name."
```

**Option B — Direct Edit** (preferred for small, precise fixes):
Use the Edit tool directly. Faster for single-line fixes.

**Option C — Fresh agent run** (if `--continue` produces bad results after 2 tries):
Abandon the session. Start fresh with a comprehensive prompt that includes all lessons learned.

## Parallel Dispatch

For independent tasks touching different files:

```bash
# Use worktrees for isolation
agent -p --force --trust -w task-1 --model composer-2-fast --output-format json "TASK 1"
agent -p --force --trust -w task-2 --model composer-2-fast --output-format json "TASK 2"
```

Run these via parallel Bash tool calls.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `cursor-agent` as binary | Binary is `agent` |
| Forgetting `--trust` | Headless mode hangs waiting for trust prompt |
| Forgetting `--force` | Agent can't write files or run commands |
| Using `--prompt` or `--message` flags | Prompt is positional, always last |
| Full Anthropic model IDs | Use short names: `composer-2-fast`, `claude-4.6-sonnet-medium` |
| Sending full plan as context | Scope to THIS task only |
| Not reviewing after completion | Always read the output files yourself |

## When NOT to Use

- Task needs MCP tools or capabilities Cursor doesn't have
- User doesn't have `agent` CLI installed (`curl https://cursor.com/install -fsSL | bash`)
- User isn't authenticated (`agent login`)
- Task is a 1-line edit (just use Edit tool directly)
- For review work — you review natively, only delegate implementation

## Known Issues

- `agent -p` may hang after completion (beta bug) — if Bash times out, the work is usually done; check the files
- Each `-p` call starts fresh unless `--continue` is used
- `--yolo` is an alias for `--force` (both work)
