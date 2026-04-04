#!/bin/bash
# cursor-tools notification
#
# Usage:
#   ./notify.sh "task name" [status]
#
# On Mac:  plays chime + speaks task name
# On EC2:  sends to localhost:9876 via SSH reverse tunnel → Mac plays it
#
# Setup (one time):
#   Mac:  ./notify-listener.sh        # starts listener on port 9876
#   SSH:  ssh -R 9876:localhost:9876 ec2-user@host
#   EC2:  ./notify.sh "task name"     # sends to Mac via tunnel
#
# Environment:
#   CURSOR_NOTIFY_PORT   - tunnel port (default: 9876)
#   CURSOR_NOTIFY_VOICE  - macOS voice (default: Samantha)
#   CURSOR_NOTIFY_OFF    - set to 1 to disable

[ "${CURSOR_NOTIFY_OFF:-}" = "1" ] && exit 0

TASK="${1:-task}"
STATUS="${2:-complete}"
PORT="${CURSOR_NOTIFY_PORT:-9878}"
VOICE="${CURSOR_NOTIFY_VOICE:-Samantha}"

# ── Mac: local notification ───────────────────────────
if command -v afplay &>/dev/null && command -v say &>/dev/null; then
  case "$STATUS" in
    fail*|error*|block*)
      afplay /System/Library/Sounds/Basso.aiff & ;;
    *)
      afplay /System/Library/Sounds/Hero.aiff & ;;
  esac
  say -v "$VOICE" "${STATUS}. ${TASK}."
  osascript -e "display notification \"${STATUS}: ${TASK}\" with title \"cursor-tools\"" 2>/dev/null
  exit 0
fi

# ── EC2/Linux: send via tunnel to Mac ─────────────────
echo "${STATUS}|${TASK}" | nc -w 1 localhost "$PORT" 2>/dev/null && exit 0

# ── Fallback: terminal bell ───────────────────────────
printf '\a'
echo "[cursor-tools] ${STATUS}: ${TASK}"
