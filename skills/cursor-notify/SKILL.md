---
name: cursor-notify
description: >
  Use after any long-running operation completes — Cursor agent tasks,
  reviews, builds, tests, deployments. Plays a chime and speaks the task
  name on Mac. On EC2, sends via SSH reverse tunnel to Mac.
  Triggers: task complete, review done, build finished, or any wait > 10s.
---

# Cursor Notify

## Overview

Notify the user when a long-running step finishes so they can multitask. Plays a chime + speaks the task name on Mac. On EC2/Linux, sends via SSH reverse tunnel (port 9876) to the Mac listener.

**Always notify after:** Cursor agent tasks, reviews (high/deep), test runs, builds, deployments, or any operation that took > 10 seconds.

## Usage

After any long-running Bash command completes, run:

```bash
NOTIFY=$(find ~/.claude/plugins -path "*/cursor-tools/*/scripts/notify.sh" 2>/dev/null | head -1)
[ -n "$NOTIFY" ] && bash "$NOTIFY" "task description" "status"
```

## Status Values

| Status | Sound | When |
|--------|-------|------|
| `complete` | Hero chime | Task finished successfully |
| `implemented` | Hero chime | Cursor agent wrote code |
| `spec reviewed` | Hero chime | Spec review passed |
| `review complete` | Hero chime | Code quality review passed |
| `plan complete` | Hero chime | All tasks in plan done |
| `tests passed` | Hero chime | Test suite green |
| `failed` | Basso chime | Something broke |
| `blocked` | Basso chime | Task stuck, needs input |
| `issues found` | Basso chime | Review found problems |

## Examples

```bash
# After Cursor agent finishes implementation
bash "$NOTIFY" "UserProfile component" "implemented"

# After GPT-5.4 review
bash "$NOTIFY" "auth middleware" "review complete"

# After test run
bash "$NOTIFY" "pytest suite" "tests passed"

# After failure
bash "$NOTIFY" "API endpoints" "failed"

# After entire plan
bash "$NOTIFY" "eval page redesign" "plan complete"
```

## Setup

### Mac (local development)

Works automatically — no setup needed. Uses `afplay` (chime) + `say` (voice) + notification center.

### EC2 → Mac (remote development)

**One-time setup:**

1. Mac — start listener (keep a terminal tab open):
```bash
~/cursor-notify-listen
```

2. SSH config already has `RemoteForward 9876 localhost:9876` on all EC2 hosts. Just SSH as usual:
```bash
ssh dev    # or ec2-dev, ec2-ml
```

3. On EC2, `notify.sh` sends via `nc localhost 9876` → tunnels to Mac → chime + voice.

### Customization

```bash
export CURSOR_NOTIFY_VOICE=Daniel     # change macOS voice
export CURSOR_NOTIFY_PORT=9876        # change tunnel port
export CURSOR_NOTIFY_OFF=1            # disable notifications
```
