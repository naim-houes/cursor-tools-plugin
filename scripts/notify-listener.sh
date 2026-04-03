#!/bin/bash
# cursor-tools notify listener — runs on your Mac
#
# Listens on a port for notifications from EC2 via SSH reverse tunnel.
# Plays chime + speaks task name when a message arrives.
#
# Usage:
#   ./notify-listener.sh [port]     # default: 9876
#
# Then SSH into EC2 with reverse tunnel:
#   ssh -R 9876:localhost:9876 ec2-user@your-ec2-host
#
# Or add to ~/.ssh/config:
#   Host ec2
#     HostName your-ec2-host
#     User ec2-user
#     RemoteForward 9876 localhost:9876

PORT="${1:-9876}"
VOICE="${CURSOR_NOTIFY_VOICE:-Samantha}"

echo "cursor-tools notify listener on port $PORT"
echo "Waiting for notifications..."
echo ""
echo "Connect from EC2 with: ssh -R ${PORT}:localhost:${PORT} user@this-mac"
echo ""

while true; do
  # Listen for one connection, read the message
  MSG=$(nc -l "$PORT" 2>/dev/null)

  if [ -n "$MSG" ]; then
    # Parse: "status|task name"
    STATUS=$(echo "$MSG" | cut -d'|' -f1)
    TASK=$(echo "$MSG" | cut -d'|' -f2-)
    [ -z "$TASK" ] && TASK="$STATUS" && STATUS="complete"

    echo "[$(date +%H:%M:%S)] $STATUS: $TASK"

    # Chime
    case "$STATUS" in
      fail*|error*|block*)
        afplay /System/Library/Sounds/Basso.aiff &
        ;;
      *)
        afplay /System/Library/Sounds/Hero.aiff &
        ;;
    esac

    # Speak
    say -v "$VOICE" "${STATUS}. ${TASK}."

    # Notification center
    osascript -e "display notification \"${STATUS}: ${TASK}\" with title \"cursor-tools\"" 2>/dev/null
  fi
done
