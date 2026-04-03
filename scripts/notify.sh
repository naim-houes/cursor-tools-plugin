#!/bin/bash
# cursor-tools notification — plays a chime + speaks the task status
#
# Usage:
#   ./notify.sh "task name" [status]
#
# Examples:
#   ./notify.sh "validator module"                    # → chime + "Complete. Validator module."
#   ./notify.sh "FastAPI endpoints" "done"            # → chime + "Done. FastAPI endpoints."
#   ./notify.sh "spec review" "issues found"          # → chime + "Issues found. Spec review."
#   ./notify.sh "auth middleware" "failed"             # → error chime + "Failed. Auth middleware."
#
# Environment:
#   CURSOR_NOTIFY_VOICE    - macOS voice (default: Samantha)
#   CURSOR_NOTIFY_SOUND    - chime sound (default: Hero for success, Basso for failure)
#   CURSOR_NOTIFY_WEBHOOK  - webhook URL for headless servers (POST JSON)
#   CURSOR_NOTIFY_OFF      - set to 1 to disable all notifications
#
# Works on:
#   - macOS: say + afplay (chime + voice)
#   - Linux desktop: notify-send + espeak/spd-say
#   - Linux headless/EC2: webhook or terminal bell
#   - Any: terminal bell fallback

set -euo pipefail

[ "${CURSOR_NOTIFY_OFF:-}" = "1" ] && exit 0

TASK="${1:-task}"
STATUS="${2:-complete}"
VOICE="${CURSOR_NOTIFY_VOICE:-Samantha}"
MESSAGE="[cursor-tools] ${STATUS}: ${TASK}"

# Pick sound based on status
IS_ERROR=false
case "$STATUS" in
  fail*|error*|block*)
    SOUND="${CURSOR_NOTIFY_SOUND:-/System/Library/Sounds/Basso.aiff}"
    IS_ERROR=true
    ;;
  *)
    SOUND="${CURSOR_NOTIFY_SOUND:-/System/Library/Sounds/Hero.aiff}"
    ;;
esac

notified=false

# ── macOS: chime + voice ──────────────────────────────
if command -v afplay &>/dev/null && command -v say &>/dev/null; then
  afplay "$SOUND" &
  say -v "$VOICE" "${STATUS}. ${TASK}."
  notified=true
fi

# ── Linux desktop: notify-send ────────────────────────
if [ "$notified" = false ] && command -v notify-send &>/dev/null; then
  if [ "$IS_ERROR" = true ]; then
    notify-send --urgency=critical "cursor-tools" "$MESSAGE"
  else
    notify-send "cursor-tools" "$MESSAGE"
  fi
  notified=true
fi

# ── Linux voice: espeak or spd-say ────────────────────
if [ "$notified" = false ]; then
  if command -v espeak &>/dev/null; then
    if command -v paplay &>/dev/null; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    fi
    espeak "${STATUS}. ${TASK}." 2>/dev/null
    notified=true
  elif command -v spd-say &>/dev/null; then
    spd-say "${STATUS}. ${TASK}." 2>/dev/null
    notified=true
  fi
fi

# ── Webhook (headless/EC2) ────────────────────────────
if [ -n "${CURSOR_NOTIFY_WEBHOOK:-}" ]; then
  curl -s -X POST "$CURSOR_NOTIFY_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"${MESSAGE}\",\"task\":\"${TASK}\",\"status\":\"${STATUS}\"}" \
    >/dev/null 2>&1 &
  notified=true
fi

# ── macOS notification center (always, if available) ──
if command -v osascript &>/dev/null; then
  osascript -e "display notification \"${STATUS}: ${TASK}\" with title \"cursor-tools\"" 2>/dev/null &
fi

# ── Fallback: terminal bell + print ───────────────────
if [ "$notified" = false ]; then
  printf '\a'
fi

echo "$MESSAGE"
