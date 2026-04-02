# cursor-tools

Claude Code plugin that delegates implementation tasks to Cursor's `agent` CLI. Claude handles planning and review, Cursor handles cheap/fast implementation via `composer-2-fast`.

## Skills

### cursor-delegate

Core delegation mechanism. Claude:
1. Gathers context (reads relevant files)
2. Crafts a specific prompt (file paths, patterns, constraints)
3. Runs `agent -p --force --trust --model composer-2-fast --output-format json "..."`
4. Waits for completion (JSON result with duration, tokens, session ID)
5. Reviews changed files
6. Fixes if needed (`--continue`, direct Edit, or fresh run)

### cursor-superpowers

Integration with `superpowers:subagent-driven-development`. Replaces the native implementer subagent dispatch with Cursor agent CLI calls while keeping native reviewer subagents.

## Prerequisites

- [Cursor agent CLI](https://cursor.com/install): `curl https://cursor.com/install -fsSL | bash`
- Cursor account authenticated: `agent login`
- Cursor Ultra subscription (for fast credits)

## Install

```bash
/plugin install cursor-tools@github:naim-houes/cursor-tools-plugin
```

## Key Rule

Always use `composer-2-fast`. If a task is too complex for it, Claude handles it directly instead of upgrading the Cursor model.
