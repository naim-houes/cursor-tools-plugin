---
name: cursor-narrate
description: >
  Use when the user wants to hear results read aloud — review findings,
  benchmark reports, test results, build output, or any summary. Speaks
  via macOS say or sends to Mac via SSH tunnel from EC2. Triggers: user
  says "read it", "narrate", "speak results", "tell me what happened".
---

# Cursor Narrate

## Overview

Read results aloud so the user can listen while multitasking. Speaks review findings, test results, build output, or any summary via macOS `say` or SSH tunnel.

## Usage

After generating a report or summary, speak it:

```bash
# Mac — speaks directly
say -v Samantha "SUMMARY TEXT"

# EC2 — sends to Mac listener via tunnel
echo "narrate|SUMMARY TEXT" | nc -w 1 localhost 9876
```

## When to Use

- After `cursor-review` — narrate the findings
- After `cursor-execute` — narrate task completion summary
- After test runs — narrate pass/fail counts
- After benchmarks — narrate the comparison
- Anytime user says "read it", "tell me", "narrate"

## How to Narrate

**Keep it short.** Summarize to 2-3 sentences max before speaking. Nobody wants to listen to a 5-minute monologue.

**Good narration:**
```bash
say -v Samantha "Review complete. Found 2 issues: missing null check in validator dot py line 42, and unused import in router dot py. Both high confidence."
```

**Bad narration:**
```bash
# Don't read raw JSON, diffs, or full file contents
say -v Samantha "$(cat review-output.json)"  # NO
```

## Template

After any result, build a spoken summary and deliver it:

```bash
VOICE="${CURSOR_NOTIFY_VOICE:-Samantha}"
SUMMARY="your 2-3 sentence summary here"

# Mac
if command -v say &>/dev/null; then
  say -v "$VOICE" "$SUMMARY"
# EC2 via tunnel
else
  echo "narrate|${SUMMARY}" | nc -w 1 localhost "${CURSOR_NOTIFY_PORT:-9876}"
fi
```

## Narration Patterns

### Review findings
```
"Review [mode]. Found [N] issues. [Top issue]. [Second issue]. Overall: [pass/fail]."
```

### Test results
```
"Tests finished. [N] passed, [N] failed. [First failure if any]."
```

### Benchmark
```
"Benchmark complete. Pure Claude: [X] tokens, [cost]. Cursor tools: [Y] tokens, [cost]. Savings: [Z] percent."
```

### Plan progress
```
"Task [N] of [total] complete. [task name]. [pass/fail]. Moving to [next task]."
```
