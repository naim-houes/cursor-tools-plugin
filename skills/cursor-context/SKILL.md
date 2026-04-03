---
name: cursor-context
description: >
  Use when you need to gather deep codebase context before planning or implementation.
  Delegates exploration to Cursor agent CLI (composer-2-fast, --mode ask) to save Claude
  tokens. Triggers: before brainstorming, before planning, when user says "gather context",
  "explore the codebase", "understand the code", or when starting work on an unfamiliar area.
---

# Cursor Context Gathering

Delegate codebase exploration to Cursor's `agent` CLI in read-only mode (`--mode ask`) to build deep understanding of a codebase area before Claude does planning, design, or implementation. Saves Claude tokens by offloading file reading and pattern discovery to Cursor.

## When to Use

- Before brainstorming or planning work in an unfamiliar area
- When you need to understand architecture, patterns, or conventions
- When the user asks to explore or understand a part of the codebase
- Before writing a spec or design document
- When onboarding to a new project or module

## Workflow

```
1. Understand the focus  — what area/topic needs context?
2. Craft exploration prompts — targeted queries for Cursor
3. Dispatch Cursor agents — parallel when independent
4. Synthesize findings — combine results into actionable context
5. Present summary — concise report to user or feed into next phase
```

## Exploration Strategies

Choose the right strategy based on what you need to understand:

### Strategy 1: Broad Project Survey

For understanding overall project structure and conventions:

```bash
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Explore this project thoroughly. Read README, CLAUDE.md, docs/, recent git log (last 10 commits), package.json/pyproject.toml, and key source files. Report:
  1. Tech stack and dependencies
  2. Architecture and file structure (top-level organization)
  3. Existing patterns and conventions (naming, imports, error handling)
  4. Entry points and main flows
  5. Test setup and conventions"
```

### Strategy 2: Focused Module Deep-Dive

For understanding a specific module, feature, or subsystem:

```bash
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Deep-dive into [MODULE/FEATURE]. Read all files in [DIRECTORY] and related imports. Report:
  1. Purpose and responsibilities of this module
  2. Key classes/functions and their roles
  3. Data flow — how data enters, transforms, and exits
  4. Dependencies — what it imports and what imports it
  5. Patterns — how similar features are implemented here
  6. Edge cases and error handling approach
  7. Test coverage — what's tested and how"
```

### Strategy 3: Pattern Discovery

For understanding how something is done across the codebase:

```bash
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Find all examples of [PATTERN] in this codebase. Look for:
  1. Every file that implements [PATTERN]
  2. The common structure they follow
  3. Variations and why they differ
  4. Which implementation is the most complete/canonical
  5. Related utilities, helpers, or base classes used"
```

### Strategy 4: Change Impact Analysis

For understanding what a proposed change would affect:

```bash
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Analyze the impact of changing [COMPONENT/FUNCTION/FILE]. Trace:
  1. All direct callers/importers of this code
  2. Indirect dependents (transitive)
  3. Tests that exercise this code path
  4. Config or environment dependencies
  5. Related documentation
  6. Risk areas — what could break?"
```

### Strategy 5: Git History Context

For understanding recent changes, decisions, and trajectory:

```bash
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "Analyze recent git history related to [TOPIC]. Run git log, git diff, and read relevant commits. Report:
  1. Recent changes in this area (last 20 commits touching [FILES/DIRS])
  2. Who changed what and apparent intent
  3. Patterns in how changes are made (small PRs? big refactors?)
  4. Any work-in-progress or partial implementations
  5. Breaking changes or migrations in progress"
```

## Parallel Dispatch

When you need multiple types of context, dispatch them in parallel:

```bash
# Run these as parallel Bash tool calls:

# Agent 1: Project overview
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "PROJECT SURVEY PROMPT"

# Agent 2: Module deep-dive
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "MODULE DEEP-DIVE PROMPT"

# Agent 3: Pattern discovery
cd PROJECT_DIR && agent -p --force --trust \
  --model composer-2-fast --output-format json --mode ask \
  "PATTERN DISCOVERY PROMPT"
```

Use parallel Bash calls or `run_in_background` for independent queries. Combine results after all complete.

## Synthesizing Results

After Cursor returns, Claude synthesizes the findings:

1. **Extract key facts** — architecture decisions, patterns, constraints
2. **Identify gaps** — what Cursor missed or was ambiguous about
3. **Fill gaps** — use Read/Grep/Glob for quick targeted lookups
4. **Build mental model** — how the pieces fit together
5. **Present concisely** — structured summary for the user

### Output Format

Present the synthesized context as:

```markdown
## Context: [Topic]

**Architecture:** [how it's structured]
**Key files:** [most important files with brief purpose]
**Patterns:** [conventions to follow]
**Dependencies:** [what this area depends on / what depends on it]
**Relevant history:** [recent changes, WIP, migrations]
**Risks:** [things to watch out for]
```

## Integration with Other Skills

This skill feeds context into other workflows:

| Next Step | How Context Is Used |
|-----------|-------------------|
| `cursor-brainstorm` | Informs questions and design decisions |
| `cursor-execute` | Provides patterns for implementation prompts |
| `cursor-review` | Gives reviewer baseline understanding |
| Planning (native) | Grounds the plan in actual codebase state |

## Required Flags

| Flag | Why |
|------|-----|
| `-p` | Non-interactive headless mode |
| `--force` | Allow shell commands (for git log, etc.) |
| `--trust` | Skip trust prompts |
| `--output-format json` | Structured result parsing |
| `--mode ask` | **Read-only** — prevents any file modifications |
| `--model composer-2-fast` | Cheap, fast, sufficient for exploration |

## Tips

- **Be specific in prompts** — "explore the auth module" is better than "explore the project"
- **Name files and directories** when you know them — helps Cursor focus
- **Ask for examples** — "show me an example of how routes are defined" gets concrete answers
- **Request file paths** — always ask Cursor to include file paths so you can verify later
- **Verify key claims** — if Cursor says a pattern exists, spot-check with Read/Grep before relying on it
- **Don't over-explore** — gather what you need for the current task, not everything

## Notify on Completion

After context gathering completes:

```bash
NOTIFY=$(find ~/.claude/plugins -path "*/cursor-tools/*/scripts/notify.sh" 2>/dev/null | head -1)
[ -n "$NOTIFY" ] && bash "$NOTIFY" "context gathered" "complete"
```
