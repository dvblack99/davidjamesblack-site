#!/bin/bash
# BlackStarr Daily Briefing
# Sends weather + todos + motivation at 6:30 AM EDT via Telegram
# Setup: crontab -e
# Add: 30 6 * * * TZ=America/New_York /workspace/mysite/daily-briefing.sh

set -e

DATA_FILE="/workspace/mysite/data/state.json"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Colors/emojis
EMOJI_DATE="📅"
EMOJI_WEATHER="⛅"
EMOJI_TODO="✓"
EMOJI_GOALS="💪"

# Timestamp
TIMESTAMP=$(date '+%A, %B %d, %Y — %I:%M %p %Z')

# Fetch weather for North Vancouver
echo "🌤️  Fetching weather..."
WEATHER=$(curl -s "https://wttr.in/North%20Vancouver?format=3" 2>/dev/null || echo "Unable to fetch weather")

# Extract todos from state.json
echo "📝 Reading todos..."
TODOS=""
if [ -f "$DATA_FILE" ]; then
    # This is a simplified read - in production you'd use jq
    # For now, show a placeholder
    TODOS="📋 To-Do list is in your BlackStarr app"
fi

# Motivational messages (rotate daily)
MOTIVATION_ARRAY=(
    "You've got a solid weekend ahead. Focus on the high-priority items, and you'll have a productive day. Remember: small wins compound. 🌟"
    "Great weekend ahead! Your household organization is looking fantastic — keep the momentum going. You've got this! 🚀"
    "The weather's cooperating for your plans. This is a great day to tackle those projects you've been planning. You're doing great! 💪"
    "You're building something meaningful for your family. Keep up the good work — progress over perfection! 🎯"
    "Today's a fresh start. Make it count, take it one task at a time, and celebrate the wins. You've got this! ✨"
)

# Get motivation based on day of year (same motivation for same day each year)
DAY_OF_YEAR=$(date +%j | sed 's/^0*//')  # Remove leading zeros
MOTIVATION_INDEX=$((DAY_OF_YEAR % ${#MOTIVATION_ARRAY[@]}))
MOTIVATION="${MOTIVATION_ARRAY[$MOTIVATION_INDEX]}"

# Build briefing message
MESSAGE="$EMOJI_DATE *$TIMESTAMP*

$EMOJI_WEATHER *Weather: North Vancouver*
$WEATHER

$EMOJI_TODO *Today's Priorities*
$TODOS

Check your BlackStarr app for full task list and details.

$EMOJI_GOALS *Your Outlook*
$MOTIVATION

---
*Sent from BlackStarr Daily Briefing*"

# Send to Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "📤 Sending briefing to Telegram..."
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"$TELEGRAM_CHAT_ID\",
            \"text\": \"$MESSAGE\",
            \"parse_mode\": \"Markdown\"
        }" > /dev/null
    echo "✅ Briefing sent at $(date '+%Y-%m-%d %H:%M:%S %Z')"
else
    echo "⚠️  Telegram credentials not set"
    echo "Set environment variables:"
    echo "  export TELEGRAM_BOT_TOKEN='...'"
    echo "  export TELEGRAM_CHAT_ID='...'"
    echo ""
    echo "Message that would be sent:"
    echo "---"
    echo -e "$MESSAGE"
    echo "---"
fi
