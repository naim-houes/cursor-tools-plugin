# cursor-tools

Claude Code plugin that delegates implementation tasks to Cursor's `agent` CLI. Claude handles planning and review, Cursor handles cheap/fast implementation via `composer-2-fast`.

## Skills

| Skill | Model | Purpose |
|-------|-------|---------|
| **cursor-delegate** | `composer-2-fast` | Delegate implementation tasks to Cursor |
| **cursor-superpowers** | `composer-2-fast` | Integration with superpowers plan execution |
| **cursor-review** | `gpt-5.4-medium` | Multi-angle code review via GPT-5.4 |

### cursor-delegate

Core delegation mechanism. Claude gathers context, crafts a prompt, spawns Cursor's `agent` CLI, waits, reviews the output, and fixes if needed.

### cursor-superpowers

Integration with `superpowers:subagent-driven-development`. Replaces native implementer subagent dispatch with Cursor agent CLI calls.

### cursor-review

Comprehensive code review using GPT-5.4 (1M context). Spawns 3 parallel review agents (bug scan, CLAUDE.md compliance, architecture), filters false positives (confidence < 80), and presents findings. Uses `--mode ask` (read-only).

## Prerequisites

- [Cursor agent CLI](https://cursor.com/install): `curl https://cursor.com/install -fsSL | bash`
- Cursor account authenticated: `agent login`
- Cursor Ultra subscription (for fast credits)

## Install

```bash
claude plugin marketplace add naim-houes/cursor-tools-plugin
claude plugin install cursor-tools
```

## Key Rules

- **Implementation:** Always `composer-2-fast`. Too complex? Claude handles it directly.
- **Review:** Default `gpt-5.4-medium`. User can override to any model.
