---
name: cursor-brainstorm
description: >
  Use before any creative work — creating features, building components, adding
  functionality, or modifying behavior. Explores intent, requirements, and design
  through dialogue, then transitions to cursor-execute for implementation.
---

# Cursor Brainstorm

## Overview

Collaborative design dialogue leading to a spec, then Cursor-powered implementation. Claude handles the entire brainstorming process natively. Only implementation is delegated.

<HARD-GATE>
Do NOT write any code, spawn any Cursor agent, or take any implementation action until you have presented a design and the user has approved it.
</HARD-GATE>

## Checklist

Complete in order:

1. **Explore project context** — read files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to complexity, get user approval after each
5. **Write spec** — save to `docs/specs/YYYY-MM-DD-<topic>-design.md`, commit
6. **Spec self-review** — check for placeholders, contradictions, ambiguity, scope
7. **User reviews spec** — ask user to review before proceeding
8. **Write implementation plan** — break into independent tasks with file paths
9. **Transition to cursor-execute** — invoke `cursor-tools:cursor-execute` skill

## The Process

### Understanding the Idea

- Check project state first (files, docs, commits)
- If request describes multiple subsystems, decompose before detailing
- Ask questions one at a time, prefer multiple choice
- Focus on: purpose, constraints, success criteria

### Exploring Approaches

- Propose 2-3 approaches with trade-offs
- Lead with your recommendation and why
- Keep it conversational

### Presenting the Design

- Scale each section to its complexity
- Ask after each section if it looks right
- Cover: architecture, components, data flow, error handling, testing
- Design for isolation: clear purpose, well-defined interfaces, testable independently

### Writing the Plan

After spec approval, break the design into implementation tasks:

```markdown
## Implementation Plan

### Task 1: [Name]
- Files: src/foo.ts, src/bar.ts
- What: [specific description]
- Tests: [what to test]
- Complexity: simple | standard | complex

### Task 2: [Name]
...
```

**Mark each task's complexity:**
- **simple/standard** → Cursor (`composer-2-fast`)
- **complex** → Claude handles directly

### Transition to Execution

<HARD-GATE>
After the plan is written and approved, you MUST switch to `cursor-tools:cursor-execute`. Do NOT implement tasks yourself. Do NOT start coding inline. Invoke the skill.
</HARD-GATE>

When transitioning, say:

> "Design and plan approved. Switching to **cursor-execute** mode — simple tasks go to Cursor (`composer-2-fast`), complex ones I handle directly, reviews via GPT-5.4."

Then immediately invoke `cursor-tools:cursor-execute` via the Skill tool.

**Do NOT:**
- Start implementing tasks without invoking cursor-execute
- "Just do a quick one" before switching
- Skip the transition because "it's simple enough"

The entire point of this workflow is that brainstorming and execution are separate modes with different engines. Brainstorming = Claude native. Execution = Cursor hybrid.

## Key Principles

- **One question at a time**
- **YAGNI ruthlessly** — remove unnecessary features
- **Explore alternatives** — always 2-3 approaches
- **No code before approval** — design first, always
- **Complexity routing** — simple to Cursor, complex stays with Claude
- **Always switch to cursor-execute** — never implement inline after brainstorming
