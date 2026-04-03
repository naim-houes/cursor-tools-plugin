---
name: cursor-execute
description: >
  Use when you have an implementation plan to execute. Routes each task to
  Cursor agent CLI (composer-2-fast) or Claude based on complexity. Includes
  two-stage review via GPT-5.4 or Claude after each task.
---

# Cursor Execute

## Overview

Execute an implementation plan by routing each task to the right engine:

| Role | Engine | Model |
|------|--------|-------|
| **Implementation** (simple/standard) | Cursor agent CLI | `composer-2-fast` |
| **Implementation** (complex) | Claude (native) | current model |
| **Spec review** | Cursor agent CLI | `gpt-5.4-high` (high) / `gpt-5.4-xhigh` (deep) |
| **Code quality review** | Cursor agent CLI | `gpt-5.4-high` (high) / `gpt-5.4-xhigh` (deep) |
| **Fix from review** | Cursor agent CLI | `composer-2-fast` |
| **Orchestration** | Claude (native) | current model |

**Announce:** "Executing plan with Cursor hybrid routing. Simple tasks go to Cursor, complex ones I handle directly. Reviews via GPT-5.4."

## The Loop

```
Read plan → Extract tasks → Create TodoWrite
  |
  For each task:
  +-- Assess complexity (simple/standard → Cursor, complex → Claude)
  +-- Implement (Cursor agent or Claude directly)
  +-- 🔔 Notify: "task name" "implemented"
  +-- Spec review (Cursor GPT-5.4, --mode ask)
  +-- 🔔 Notify: "task name" "spec reviewed"
  +-- Code quality review (Cursor GPT-5.4, --mode ask)
  +-- 🔔 Notify: "task name" "review complete"
  +-- Fix issues if any
  +-- Mark complete
  |
  After all tasks:
  +-- Final review
  +-- Present to user
```

## Step by Step

### 1. Load Plan and Create Tasks

Read the plan. Extract every task with its full text. Create TodoWrite with all tasks.

For each task, assess complexity:
- **Simple/Standard:** 1-3 files, clear spec, no deep reasoning → Cursor
- **Complex:** multi-file architecture, security, deep reasoning → Claude

### 2. Implement — Cursor Path

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "TASK PROMPT — include: what to build, file paths, patterns to follow,
  constraints, and 'run tests when done'"
```

Run via Bash tool. Timeout 120000-300000ms.

Parse JSON result: check `is_error`, read `result` summary.

### 2b. Implement — Claude Path

For complex tasks, implement directly using Read/Edit/Write tools. No delegation. Claude handles the full reasoning.

### 3. Spec Review

After implementation (either path), run spec review via Cursor GPT-5.4:

```bash
cd /path/to/project && agent -p --force --trust \
  --model gpt-5.4-high --output-format json --mode ask \
  "Review this implementation against the spec.

SPEC:
[PASTE TASK SPEC FROM PLAN]

FILES CHANGED:
[LIST FILES]

Check:
1. Does the implementation match EVERY requirement in the spec?
2. Is anything MISSING from the spec?
3. Is anything EXTRA that wasn't requested?

Report: PASS (all requirements met) or FAIL (list specific gaps)."
```

### 4. Code Quality Review

If spec review passes, run code quality review:

```bash
cd /path/to/project && agent -p --force --trust \
  --model gpt-5.4-high --output-format json --mode ask \
  "Review these files for code quality.

FILES:
[LIST FILES WITH PATHS]

CLAUDE.md RULES:
[PASTE RELEVANT RULES]

Check for:
- Bugs and logic errors
- Security issues
- CLAUDE.md compliance
- Missing error handling at system boundaries
- Wrong abstractions

Rate each finding 0-100 confidence. Only report findings >= 80.
Report: PASS or FAIL with specific issues."
```

### 5. Fix Issues

If either review fails:

**Small fixes (1-3 lines):** Edit tool directly.

**Larger fixes via Cursor:**
```bash
cd /path/to/project && agent -p --force --trust \
  --continue --output-format json \
  "Fix these review findings: [SPECIFIC ISSUES]"
```

**Re-review after fix.** Don't skip re-review.

**After 2 failed fix rounds:** handle it yourself as Claude.

### 6. Mark Complete

Update TodoWrite. Move to next task.

### 7. Final Review (After All Tasks)

Run one final review across the entire implementation:

```bash
cd /path/to/project && agent -p --force --trust \
  --model gpt-5.4-high --output-format json --mode ask \
  "Final review of the full implementation.

ALL FILES CHANGED:
[git diff --stat from start]

Check for:
- Cross-task integration issues
- Inconsistent patterns between tasks
- Missing tests
- Anything that would break in production

Report findings with confidence scores. Only report >= 80."
```

Present results to user.

## Parallel Tasks

When plan has independent tasks (different files):

```bash
# Parallel Cursor dispatch with worktree isolation
agent -p --force --trust -w task-1 --model composer-2-fast --output-format json "TASK 1"
agent -p --force --trust -w task-2 --model composer-2-fast --output-format json "TASK 2"
```

Run via parallel Bash tool calls. Review each independently.

**Never parallelize:** tasks touching same files, or tasks with dependencies.

## Complexity Routing Decision

```
Is the task...
  Touching 1-3 files with clear spec?        → Cursor (composer-2-fast)
  A rename, add attributes, CRUD?             → Cursor (composer-2-fast)
  Writing tests for existing code?            → Cursor (composer-2-fast)
  Multi-file architecture decision?           → Claude (native)
  Security-critical (auth, crypto, tokens)?   → Claude (native)
  Requires reading many files to understand?  → Claude (native)
  Debugging a complex issue?                  → Claude (native)
```

**When in doubt:** start with Cursor. If it fails or produces poor results, handle it yourself as Claude.

## Notifications

After every long-running step (implementation, review), notify the user so they can multitask:

```bash
NOTIFY=$(find ~/.claude/plugins -path "*/cursor-tools/*/scripts/notify.sh" 2>/dev/null | head -1)

# After implementation completes
[ -n "$NOTIFY" ] && bash "$NOTIFY" "Task 1: validators" "implemented"

# After spec review
[ -n "$NOTIFY" ] && bash "$NOTIFY" "Task 1: validators" "spec reviewed"

# After quality review
[ -n "$NOTIFY" ] && bash "$NOTIFY" "Task 1: validators" "review complete"

# On failure
[ -n "$NOTIFY" ] && bash "$NOTIFY" "Task 1: validators" "failed"

# On all tasks done
[ -n "$NOTIFY" ] && bash "$NOTIFY" "All tasks" "plan complete"
```

On macOS: plays a chime + speaks the task name. On Linux: desktop notification or terminal bell. Set `CURSOR_NOTIFY_WEBHOOK` for headless/EC2 servers.

## Red Flags

- **Never** skip reviews (spec OR quality)
- **Never** proceed with unfixed review issues
- **Never** send full plan to Cursor (scope to THIS task only)
- **Never** use anything other than `composer-2-fast` for implementation
- **Never** upgrade Cursor model for complex tasks — do it yourself as Claude
- **Always** read files after Cursor finishes — don't trust blindly
- **Always** re-review after fixes
- **Always** notify after long-running steps
