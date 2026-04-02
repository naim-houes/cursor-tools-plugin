# cursor-tools

Hybrid AI workflow plugin for Claude Code. Claude brainstorms and orchestrates, Cursor implements cheaply, GPT-5.4 reviews.

**Replaces:** `superpowers:brainstorming` + `superpowers:subagent-driven-development`

## Skills

| Skill | Engine | Model | Purpose |
|-------|--------|-------|---------|
| **cursor-brainstorm** | Claude (native) | current | Design dialogue → spec → plan |
| **cursor-execute** | Cursor + Claude | routing table | Execute plan: Cursor for simple, Claude for complex |
| **cursor-delegate** | Cursor agent CLI | `composer-2-fast` | Core delegation mechanism |
| **cursor-review** | Cursor agent CLI | `gpt-5.4-xhigh` | Multi-angle code review |

### Workflow

```
cursor-brainstorm                    cursor-execute
(Claude native)                      (hybrid routing)

1. Explore context                   For each task:
2. Ask questions (1 at a time)        ├─ Simple? → Cursor (composer-2-fast)
3. Propose 2-3 approaches            ├─ Complex? → Claude (native)
4. Present design                     ├─ Spec review → Cursor (gpt-5.4)
5. Write spec                         ├─ Quality review → Cursor (gpt-5.4)
6. Write plan                         ├─ Fix issues → Cursor or Edit
7. → cursor-execute                   └─ Mark complete
```

### Routing Table

| Role | Engine | Model |
|------|--------|-------|
| Brainstorming | Claude (native) | current |
| Planning | Claude (native) | current |
| Implementation (simple) | Cursor agent CLI | `composer-2-fast` |
| Implementation (complex) | Claude (native) | current |
| Spec review | Cursor agent CLI | `gpt-5.4-xhigh` |
| Code quality review | Cursor agent CLI | `gpt-5.4-xhigh` |
| Fix from review | Cursor agent CLI | `composer-2-fast` |
| Debugging | Claude (native) | current |

## Prerequisites

- [Cursor agent CLI](https://cursor.com/install): `curl https://cursor.com/install -fsSL | bash`
- Authenticated: `agent login`
- Cursor Ultra subscription

## Install

```bash
claude plugin marketplace add naim-houes/cursor-tools-plugin
claude plugin install cursor-tools
```

## Key Rules

- **Implementation:** Always `composer-2-fast`. Too complex? Claude handles it directly.
- **Review:** Default `gpt-5.4-xhigh` via `--mode ask` (read-only).
- **No code before design approval.** Brainstorm first, always.
- **Always review.** Never trust Cursor output blindly.
