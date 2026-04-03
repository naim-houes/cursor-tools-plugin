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
  +-- TDD: Write failing tests first (Cursor or Claude)
  +-- 🔔 Notify: "task name" "tests written"
  +-- Verify tests fail (expected — no implementation yet)
  +-- Implement (Cursor agent or Claude directly)
  +-- Run tests — verify they pass
  +-- 🔔 Notify: "task name" "implemented"
  +-- Spec review (Cursor GPT-5.4, --mode ask)
  +-- 🔔 Notify: "task name" "spec reviewed"
  +-- Code quality + test coverage review (Cursor GPT-5.4, --mode ask)
  +-- 🔔 Notify: "task name" "review complete"
  +-- Fix issues if any
  +-- Mark complete
  |
  After all tasks:
  +-- Run full test suite
  +-- Final review (includes test coverage check)
  +-- Present to user
```

## Step by Step

### 1. Load Plan and Create Tasks

Read the plan. Extract every task with its full text. Create TodoWrite with all tasks.

For each task, assess complexity:
- **Simple/Standard:** 1-3 files, clear spec, no deep reasoning → Cursor
- **Complex:** multi-file architecture, security, deep reasoning → Claude

### 2. TDD: Write Failing Tests First

Before implementation, check the task's `TDD:` field from the plan:
- **TDD: yes** — write failing tests first, then implement (full TDD cycle below)
- **TDD: no** — skip this step, go straight to implementation (task has no testable behavior)
- **TDD: n/a** — this task IS a test task (integration/E2E), just write and run the tests

For tasks with `TDD: yes`, write tests first. This applies to every task that produces testable code.

**Test types required (when applicable):**

| Type | Scope | When Required |
|------|-------|---------------|
| **Unit tests** | Single function/class in isolation | Always for new functions/classes |
| **Integration tests** | Multiple components working together | When task connects modules, APIs, or services |
| **End-to-end tests** | Full user flow through the system | When task adds/modifies a user-facing workflow |

**Unit test structure:** Follow the existing project test directory structure. Mirror the source tree — if implementing `src/services/auth.py`, tests go in `tests/services/test_auth.py` (or wherever the project convention places them). Discover the convention first:

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Find the test directory structure and conventions in this project. Report:
  1. Test framework (pytest, jest, vitest, etc.)
  2. Test directory layout (mirror src? flat? co-located?)
  3. Naming conventions (test_*.py? *.test.ts? *.spec.ts?)
  4. Test runner command
  5. Example of a well-written test in this project"
```

**Write tests via Cursor:**

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "TDD — write FAILING tests for this task. Do NOT implement the feature yet.

TASK SPEC:
[PASTE TASK SPEC FROM PLAN]

Write tests following the project's existing test structure and conventions.
Include:
- Unit tests for each new function/class
- Integration tests if this task connects components [SPECIFY WHICH]
- E2E tests if this task modifies a user-facing flow [SPECIFY WHICH]

Tests MUST fail right now (the implementation doesn't exist yet).
Run the tests to confirm they fail with the expected errors."
```

**Verify tests fail:**

Run the test command. Confirm failures are for the RIGHT reason (missing implementation, not syntax errors or broken imports).

### 3. Implement — Cursor Path

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "TASK PROMPT — include: what to build, file paths, patterns to follow,
  constraints, and 'run tests when done to verify they pass'"
```

Run via Bash tool. Timeout 120000-300000ms.

Parse JSON result: check `is_error`, read `result` summary.

**After implementation, run all tests for this task.** If tests fail, fix before proceeding.

### 3b. Implement — Claude Path

For complex tasks, implement directly using Read/Edit/Write tools. No delegation. Claude handles the full reasoning. Run tests after implementation to verify they pass.

### 4. Spec Review

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

### 5. Code Quality + Test Coverage Review

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
- Test coverage gaps:
  * Are there unit tests for every new function/class?
  * Are there integration tests for component interactions?
  * Are there E2E tests for user-facing flows (if applicable)?
  * Do tests follow the project's test directory structure?
  * Are tests meaningful (not just asserting true)?

Rate each finding 0-100 confidence. Only report findings >= 80.
Report: PASS or FAIL with specific issues."
```

### 6. Fix Issues

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

### 7. Mark Complete

Update TodoWrite. Move to next task.

### 8. Final Review (After All Tasks)

Run the full test suite first, then the final review:

```bash
# Run full test suite
cd /path/to/project && [TEST RUNNER COMMAND]
```

If tests fail, fix before proceeding to review.

```bash
cd /path/to/project && agent -p --force --trust \
  --model gpt-5.4-high --output-format json --mode ask \
  "Final review of the full implementation.

ALL FILES CHANGED:
[git diff --stat from start]

Check for:
- Cross-task integration issues
- Inconsistent patterns between tasks
- Test coverage completeness:
  * Unit tests for all new functions/classes
  * Integration tests for cross-module interactions
  * E2E tests for user-facing flows
  * Tests follow project directory structure
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
  Writing tests (unit/integration/E2E)?       → Cursor (composer-2-fast)
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

- **Never** skip TDD — write failing tests BEFORE implementation
- **Never** skip reviews (spec OR quality)
- **Never** proceed with unfixed review issues
- **Never** mark a task complete without passing tests
- **Never** send full plan to Cursor (scope to THIS task only)
- **Never** use anything other than `composer-2-fast` for implementation
- **Never** upgrade Cursor model for complex tasks — do it yourself as Claude
- **Always** read files after Cursor finishes — don't trust blindly
- **Always** re-review after fixes
- **Always** notify after long-running steps
