#!/bin/bash
# cursor-tools benchmark: compare token usage Pure Claude vs Claude + Cursor
#
# Usage:
#   ./benchmark.sh "task description" [workspace_path]
#
# Example:
#   ./benchmark.sh "Create a Python calculator class with add/subtract/multiply/divide and tests"
#   ./benchmark.sh "Create src/utils/validator.ts with email and URL validators and tests" /path/to/project

set -euo pipefail

TASK="${1:?Usage: ./benchmark.sh \"task description\" [workspace_path]}"
WORKSPACE="${2:-$(mktemp -d)}"
RESULTS_DIR="/tmp/cursor-tools-benchmark-$(date +%s)"
mkdir -p "$RESULTS_DIR"

echo "================================================"
echo "  cursor-tools benchmark"
echo "================================================"
echo ""
echo "Task: $TASK"
echo "Workspace: $WORKSPACE"
echo "Results: $RESULTS_DIR"
echo ""

# ──────────────────────────────────────────────────
# Run 1: Pure Claude (no Cursor)
# ──────────────────────────────────────────────────
echo "▸ Running Pure Claude..."
START_CLAUDE=$(date +%s)

unset CLAUDECODE 2>/dev/null || true
claude --print --output-format json \
  --dangerously-skip-permissions \
  --no-session-persistence \
  --model opus \
  -p "$TASK" \
  2>/dev/null > "$RESULTS_DIR/pure-claude.json" || true

END_CLAUDE=$(date +%s)
CLAUDE_WALL=$((END_CLAUDE - START_CLAUDE))
echo "  Done (${CLAUDE_WALL}s wall time)"

# ──────────────────────────────────────────────────
# Run 2: Cursor delegate (composer-2-fast)
# ──────────────────────────────────────────────────
echo "▸ Running Cursor delegate (composer-2-fast)..."
START_CURSOR=$(date +%s)

cd "$WORKSPACE"
agent -p --force --trust \
  --model composer-2-fast --output-format json \
  "$TASK" \
  2>/dev/null > "$RESULTS_DIR/cursor-delegate.json" || true

END_CURSOR=$(date +%s)
CURSOR_WALL=$((END_CURSOR - START_CURSOR))
echo "  Done (${CURSOR_WALL}s wall time)"

# ──────────────────────────────────────────────────
# Parse results
# ──────────────────────────────────────────────────
echo ""
echo "▸ Parsing results..."

# Pure Claude
CLAUDE_INPUT=$(cat "$RESULTS_DIR/pure-claude.json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
u = d.get('usage', {})
mu = d.get('modelUsage', {})
total_in = 0
total_out = 0
total_cache_read = 0
total_cache_write = 0
for model, stats in mu.items():
    total_in += stats.get('inputTokens', 0)
    total_out += stats.get('outputTokens', 0)
    total_cache_read += stats.get('cacheReadInputTokens', 0)
    total_cache_write += stats.get('cacheCreationInputTokens', 0)
cost = d.get('total_cost_usd', 0)
duration = d.get('duration_ms', 0) / 1000
print(json.dumps({
    'input_tokens': total_in,
    'output_tokens': total_out,
    'cache_read': total_cache_read,
    'cache_write': total_cache_write,
    'total_tokens': total_in + total_out + total_cache_read + total_cache_write,
    'cost_usd': round(cost, 4),
    'duration_s': round(duration, 1)
}))
" 2>/dev/null)

# Cursor delegate
CURSOR_OUTPUT=$(cat "$RESULTS_DIR/cursor-delegate.json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
u = d.get('usage', {})
duration = d.get('duration_ms', 0) / 1000
print(json.dumps({
    'input_tokens': u.get('inputTokens', 0),
    'output_tokens': u.get('outputTokens', 0),
    'cache_read': u.get('cacheReadTokens', 0),
    'cache_write': u.get('cacheWriteTokens', 0),
    'total_tokens': u.get('inputTokens', 0) + u.get('outputTokens', 0) + u.get('cacheReadTokens', 0) + u.get('cacheWriteTokens', 0),
    'cost_usd': 0,
    'duration_s': round(duration, 1),
    'is_error': d.get('is_error', False)
}))
" 2>/dev/null)

# ──────────────────────────────────────────────────
# Display results
# ──────────────────────────────────────────────────
python3 -c "
import json, sys

claude = json.loads('$CLAUDE_INPUT')
cursor = json.loads('$CURSOR_OUTPUT')

# For the hybrid path, Claude only orchestrates (~2-3k tokens estimate)
# In real usage, Claude crafts the prompt and reviews the output
ORCHESTRATION_ESTIMATE_IN = 3500
ORCHESTRATION_ESTIMATE_OUT = 500
ORCHESTRATION_COST = 0.03  # rough estimate for orchestration

hybrid_claude_cost = ORCHESTRATION_COST
pure_cost = claude['cost_usd']
savings_pct = ((pure_cost - hybrid_claude_cost) / pure_cost * 100) if pure_cost > 0 else 0

print()
print('=' * 64)
print('  BENCHMARK RESULTS')
print('=' * 64)
print()
print(f'Task: {sys.argv[1][:70]}')
print()

# Table header
print(f'{\"Metric\":<28} {\"Pure Claude\":>14} {\"Cursor-tools\":>14} {\"Savings\":>10}')
print('-' * 68)

# Input tokens
ci = claude['input_tokens'] + claude['cache_write'] + claude['cache_read']
print(f'{\"Claude input tokens\":<28} {ci:>14,} {ORCHESTRATION_ESTIMATE_IN:>14,} {\"~\" + str(round((1 - ORCHESTRATION_ESTIMATE_IN/ci)*100)) + \"%\":>10}' if ci > 0 else f'{\"Claude input tokens\":<28} {ci:>14,} {ORCHESTRATION_ESTIMATE_IN:>14,} {\"N/A\":>10}')

# Output tokens
co = claude['output_tokens']
print(f'{\"Claude output tokens\":<28} {co:>14,} {ORCHESTRATION_ESTIMATE_OUT:>14,} {\"~\" + str(round((1 - ORCHESTRATION_ESTIMATE_OUT/co)*100)) + \"%\":>10}' if co > 0 else f'{\"Claude output tokens\":<28} {co:>14,} {ORCHESTRATION_ESTIMATE_OUT:>14,} {\"N/A\":>10}')

# Cursor tokens
ct = cursor['total_tokens']
print(f'{\"Cursor tokens (free*)\":<28} {0:>14,} {ct:>14,} {\"free\":>10}')

# Cost
print(f'{\"Claude API cost\":<28} {\"$\" + str(pure_cost):>14} {\"~$\" + str(round(hybrid_claude_cost, 2)):>14} {\"~\" + str(round(savings_pct)) + \"%\":>10}')

# Duration
print(f'{\"Duration\":<28} {str(claude[\"duration_s\"]) + \"s\":>14} {str(cursor[\"duration_s\"]) + \"s\":>14} {\"\":>10}')

print()
print('* Cursor tokens use Cursor Ultra credits (composer-2-fast), not Claude API billing.')
print(f'  In hybrid mode, Claude only pays for orchestration (~{ORCHESTRATION_ESTIMATE_IN + ORCHESTRATION_ESTIMATE_OUT:,} tokens).')
print(f'  Implementation tokens ({ct:,}) shift entirely to Cursor.')
print()
print('Raw results saved to:')
print(f'  {sys.argv[2]}/pure-claude.json')
print(f'  {sys.argv[2]}/cursor-delegate.json')
" "$TASK" "$RESULTS_DIR"
