#!/bin/bash
# BlackStarr Evening Routine Reminder
# Sends nightly checklist at 9:30 PM EDT via Telegram
# Setup: crontab -e
# Add: 30 21 * * * TZ=America/New_York /workspace/mysite/evening-routine.sh

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Build the checklist message
MESSAGE="🌙 *Evening Routine — 9:30 PM*

Your nightly checklist:

☐ Charge Sean's iPad
☐ Take Josiane's phone away
☐ David make lunch for work
☐ Turn off lights and lock doors

---
*Set up reminders for a smooth morning tomorrow!*"

# Send to Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"$TELEGRAM_CHAT_ID\",
            \"text\": \"$MESSAGE\",
            \"parse_mode\": \"Markdown\"
        }" > /dev/null
    echo "✅ Evening routine reminder sent at $(date '+%Y-%m-%d %H:%M:%S %Z')"
else
    echo "⚠️  Telegram credentials not set"
    echo "Set: export TELEGRAM_BOT_TOKEN='...' && export TELEGRAM_CHAT_ID='...'"
fi
