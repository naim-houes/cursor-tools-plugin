---
name: cursor-review
description: >
  Use when reviewing code changes, pull requests, or recent work for bugs,
  quality issues, and CLAUDE.md compliance. Runs via Cursor agent CLI with
  GPT-5.4 by default for deep code review. Triggers: user asks to review code,
  review a PR, check recent changes, or says "cursor review".
---

# Cursor Review

## Overview

Run comprehensive code reviews via Cursor's `agent` CLI using GPT-5.4 (1M context). Claude orchestrates: gathers the diff, spawns Cursor for multi-angle review, collects findings, filters false positives, and presents results.

**Why GPT-5.4:** Large context window (1M), strong reasoning for code analysis, available on Cursor Ultra credits.

## Two Modes

| Mode | Model | Speed | Use when |
|------|-------|-------|----------|
| **high** | `gpt-5.4-high` | ~2-3 min | Default. Quick PR reviews, routine changes, large diffs |
| **deep** | `gpt-5.4-xhigh` | ~8-10 min | Security-critical, complex architecture, pre-release audits |

**Always ask the user which mode before starting the review.** Use AskUserQuestion tool:

> "Which review mode?"
> - **High** (~3 min) — routine changes, quick feedback
> - **Deep** (~10 min) — thorough audit, security-critical code

If the user already specified (e.g. "deep review", "quick review"), skip the question and use the matching mode.

## Quick Reference

```bash
# High mode (default)
agent -p --force --trust --model gpt-5.4-high --output-format json \
  --mode ask "REVIEW PROMPT"

# Deep mode
agent -p --force --trust --model gpt-5.4-xhigh --output-format json \
  --mode ask "REVIEW PROMPT"
```

**`--mode ask`** — read-only mode, no file edits. Perfect for reviews.

## Workflow

### 1. Gather the Diff

Claude collects what needs reviewing:

```bash
# For unstaged work
git diff

# For staged changes
git diff --cached

# For a PR
gh pr diff <number>

# For recent commits
git diff HEAD~3..HEAD
```

Also read any relevant CLAUDE.md files from affected directories.

### 2. Spawn Review Agents

Run **3 parallel** Cursor agents, each reviewing from a different angle:

```bash
# Agent 1: Bug scan
agent -p --force --trust --model gpt-5.4-high --output-format json --mode ask \
  "Review this diff for bugs, logic errors, and security vulnerabilities.
Focus on issues that would break in production. Ignore style nitpicks.
Rate each finding 0-100 confidence (100 = certain bug, 0 = false positive).

CLAUDE.md rules:
[PASTE RELEVANT CLAUDE.md CONTENT]

Diff:
[PASTE DIFF]"

# Agent 2: CLAUDE.md compliance
agent -p --force --trust --model gpt-5.4-high --output-format json --mode ask \
  "Check if this diff complies with the project's CLAUDE.md rules.
Only flag violations that are EXPLICITLY mentioned in CLAUDE.md.
Rate each finding 0-100 confidence.

CLAUDE.md:
[PASTE FULL CLAUDE.md]

Diff:
[PASTE DIFF]"

# Agent 3: Architecture and patterns
agent -p --force --trust --model gpt-5.4-high --output-format json --mode ask \
  "Review this diff for architectural issues: wrong abstractions, missing error handling
at system boundaries, broken patterns, coupling issues.
Rate each finding 0-100 confidence.

Project context:
[BRIEF ARCHITECTURE DESCRIPTION]

Diff:
[PASTE DIFF]"
```

Run all 3 via parallel Bash tool calls.

### 3. Collect and Filter

Parse each agent's JSON response. Filter findings:

- **Keep**: confidence >= 80
- **Discard**: confidence < 80 (likely false positives)
- **Discard**: pre-existing issues not introduced by this diff
- **Discard**: issues a linter/typechecker would catch
- **Discard**: style nitpicks unless CLAUDE.md explicitly requires them

### 4. Present Results

Format the filtered findings for the user:

```markdown
### Code Review (via GPT-5.4)

Found N issues:

1. **[BUG]** Brief description (confidence: 92)
   File: path/to/file.ts:42-48
   Suggestion: ...

2. **[CLAUDE.md]** Brief description (confidence: 85)
   Rule: "CLAUDE.md says: ..."
   File: path/to/file.ts:15

No issues found in: architecture, error handling
```

### 5. Fix (Optional)

If the user wants fixes applied, delegate to `cursor-delegate` skill:

```bash
agent -p --force --trust --model composer-2-fast --output-format json \
  "Fix these code review findings: [LIST OF ISSUES WITH FILE PATHS]"
```

Use `composer-2-fast` for fixes (not GPT-5.4 — implementation is cheap work).

## PR Review Mode

For pull request reviews, also post the comment via `gh`:

```bash
# After collecting findings, post to PR
gh pr comment <number> --body "$(cat <<'EOF'
### Code Review (via GPT-5.4)

Found N issues:
...

Generated with cursor-tools plugin
EOF
)"
```

## False Positive Examples

Train the review agents to ignore these:

- Pre-existing issues (not introduced by the diff)
- Things a linter/typechecker catches (imports, types, formatting)
- General code quality issues unless CLAUDE.md requires them
- Intentional functionality changes related to the PR's purpose
- Issues on lines the author did not modify
- Lint-ignored code (`// eslint-disable`, `# noqa`, etc.)

## When NOT to Use

- Reviewing your own just-written code (just read it yourself)
- Trivial 1-file changes (overkill)
- User doesn't have `agent` CLI installed or authenticated
- No Cursor Ultra subscription

## Tips

- For large diffs (>2000 lines), split into chunks per file/module
- Always include CLAUDE.md content in the prompt — don't assume the agent knows your rules
- The `--mode ask` flag is essential — prevents the reviewer from modifying files
