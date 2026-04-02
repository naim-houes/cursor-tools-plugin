---
name: cursor-superpowers
description: >
  Use when executing implementation plans with superpowers:subagent-driven-development
  or superpowers:executing-plans and Cursor agent CLI is available. Replaces native
  implementer subagent dispatch with Cursor's agent CLI for cheaper, faster implementation
  while keeping Claude for orchestration and review.
---

# Cursor Superpowers

## Overview

Drop-in replacement for the implementer dispatch step in `superpowers:subagent-driven-development`. Claude plans, reviews, and orchestrates. Cursor implements.

**REQUIRED:** `cursor-delegate` skill must be available — it defines the CLI interface and flags.

## What Changes

```
superpowers:subagent-driven-development flow:

  For each task in plan:
  +-- Build implementer prompt           (unchanged — Claude does this)
  +-- Dispatch implementer               ** CHANGED: agent CLI instead of Task() **
  +-- Wait for completion                ** CHANGED: Bash blocks, parse JSON **
  +-- Review result                      ** CHANGED: Claude reads files directly **
  +-- Dispatch spec reviewer             (unchanged — native subagent)
  +-- Dispatch code quality reviewer     (unchanged — native subagent)
  +-- Fix issues if any                  ** CHANGED: agent --continue or Edit **
  +-- Mark task complete                 (unchanged)
```

## The Loop

For each task from the plan:

### 1. Prepare

Read the task from the plan. Gather context:
- Read files the task will modify or that serve as patterns
- Identify the workspace path
- Assess complexity: if too complex for a fast model, handle it yourself as Claude instead of delegating

### 2. Dispatch to Cursor

```bash
cd /path/to/project && agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "TASK PROMPT — be specific, include file paths, patterns to follow, constraints"
```

Run via Bash tool with timeout 120000-300000ms.

### 3. Wait + Parse

The Bash call blocks until done. Parse the JSON:
- `is_error: true` → task failed, diagnose and retry or escalate
- `is_error: false` → proceed to review

### 4. Claude Reviews

**Do not skip this step.** Read every file the agent created or modified:

```
Read created/modified files
Check: does implementation match the plan's spec?
Check: code quality, edge cases, naming conventions
Check: tests written and passing (if applicable)
```

If issues found → go to step 5. If clean → go to step 6.

### 5. Fix

**Small fixes (1-3 lines):** Use Edit tool directly. Faster than another agent call.

**Larger fixes:** Use `--continue` to send targeted fix instructions:

```bash
cd /path/to/project && agent -p --force --trust \
  --continue --output-format json \
  "Fix: 1) [specific issue]. 2) [specific issue]."
```

**If 2 fix rounds fail:** Abandon agent session. Either fix directly with Edit or start a fresh agent call with a comprehensive prompt incorporating all lessons.

### 6. Native Reviewers (Optional)

If the superpowers workflow calls for spec/code quality reviewers, dispatch those as normal native subagents. They read files and report back — no change from standard workflow.

### 7. Mark Complete

Update TodoWrite, move to next task.

## Parallel Tasks

When the plan has independent tasks (different files, no dependencies):

```bash
# Run in parallel via multiple Bash calls
# Terminal 1 — worktree isolation
agent -p --force --trust -w task-a --model composer-2-fast --output-format json "TASK A"

# Terminal 2 — worktree isolation
agent -p --force --trust -w task-b --model composer-2-fast --output-format json "TASK B"
```

Review each result independently before marking complete.

## When to Fall Back to Native Subagents

- Task needs MCP tools or interactive capabilities
- Agent CLI is not installed or authenticated
- Task failed twice with Cursor — native subagent may have better context handling
- Task is purely research/analysis (use native subagent or do it yourself)

## Announcement

When starting, say:

> "Executing plan with Cursor delegation. I'll orchestrate and review — Cursor handles implementation via `agent` CLI."

## Key Rules

1. **Always `composer-2-fast`** — never upgrade the Cursor model. If a task is too complex, do it yourself as Claude.
2. **Always review** — never trust agent output blindly
3. **Scope prompts tight** — only this task's context, not the full plan
4. **Fix fast** — small fixes via Edit, larger via `--continue`, abandon after 2 failed rounds
5. **Reviewers stay native** — only implementation goes to Cursor
6. **Track progress** — update TodoWrite after each task completes
