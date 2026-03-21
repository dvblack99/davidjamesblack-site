#!/bin/bash
# BlackStarr Scheduled Reminders Trigger
# VPS cron calls this at exact times
# Crontab entries:
#   30 6 * * * /workspace/mysite/schedule-reminders.sh briefing
#   30 21 * * * /workspace/mysite/schedule-reminders.sh routine

TRIGGER_DIR="/workspace/mysite/triggers"
mkdir -p "$TRIGGER_DIR"

REMINDER_TYPE="$1"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

if [ "$REMINDER_TYPE" = "briefing" ]; then
    echo "$TIMESTAMP" > "$TRIGGER_DIR/briefing.trigger"
    echo "✅ Briefing trigger created at $(date '+%H:%M %Z')"
elif [ "$REMINDER_TYPE" = "routine" ]; then
    echo "$TIMESTAMP" > "$TRIGGER_DIR/routine.trigger"
    echo "✅ Evening routine trigger created at $(date '+%H:%M %Z')"
else
    echo "Usage: $0 [briefing|routine]"
    exit 1
fi
