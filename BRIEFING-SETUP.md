# BlackStarr Daily Briefing Setup

**Send yourself a 6:30 AM EDT daily briefing with weather + to-do's + motivation.**

## What You'll Get

Every morning at 6:30 AM EDT:

```
📅 Saturday, March 21, 2026 — 6:30 AM EDT

⛅ Weather: North Vancouver
Partly cloudy, 8°C. High 12°C. Light winds.

✓ Today's Priorities
📋 To-Do list is in your BlackStarr app
[Full tasks appear here when synced]

💪 Your Outlook
You've got a solid weekend ahead. Focus on high-priority items, and you'll have a productive day. Remember: small wins compound. 🌟
```

Sent via **Telegram** directly to your phone.

## Setup (5 minutes)

### 1. Create a Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Send: `/start`
3. Send: `/newbot`
4. Answer:
   - Name: `BlackStarr Briefing`
   - Username: `blackstarr_briefing_bot` (or similar, must be unique)
5. BotFather replies with your **Bot Token** (looks like: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)
6. **Copy the token** and save it safely

### 2. Get Your Telegram Chat ID

1. Open Telegram and search for **@userinfobot**
2. Send: `/start`
3. It replies with your **User ID** (a number like `8622430482`)
4. **Copy your User ID**

Alternatively, send yourself a message and check:
```bash
curl https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
# Look for "chat": {"id": 8622430482}
```

### 3. Set Environment Variables

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export TELEGRAM_BOT_TOKEN='your_bot_token_here'
export TELEGRAM_CHAT_ID='your_chat_id_here'
```

Then reload:
```bash
source ~/.bashrc
# or
source ~/.zshrc
```

Verify:
```bash
echo $TELEGRAM_BOT_TOKEN
echo $TELEGRAM_CHAT_ID
```

### 4. Test the Script

```bash
/workspace/mysite/daily-briefing.sh
```

You should see:
- Weather fetched for North Vancouver
- Briefing formatted
- Message sent to Telegram

**Check your Telegram** — you should see the briefing message!

### 5. Add to Crontab

```bash
crontab -e
```

Add this line:

```bash
30 6 * * * /workspace/mysite/daily-briefing.sh
```

This runs at 6:30 AM EDT every day.

Verify:
```bash
crontab -l
```

You should see your entry.

## Troubleshooting

### Script runs but Telegram doesn't receive message

**Check credentials:**
```bash
echo $TELEGRAM_BOT_TOKEN
echo $TELEGRAM_CHAT_ID
```

Both should be non-empty.

**Test Telegram API directly:**
```bash
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": "'$TELEGRAM_CHAT_ID'", "text": "Test"}'
```

Should return `{"ok": true, ...}`. If `{"ok": false, ...}`, check:
- Bot token is correct (didn't get truncated)
- Chat ID is correct (should be a number)
- Bot was started in Telegram (send it any message)

### Cron job doesn't run

**Check cron is running:**
```bash
sudo systemctl status cron
```

**Check logs:**
```bash
grep CRON /var/log/syslog | tail -20
```

**Test manually at expected time:**
```bash
# Set system time to 6:30 AM (testing only)
# Or run the script directly
/workspace/mysite/daily-briefing.sh
```

### Weather doesn't show up

The script uses wttr.in (free, no API key needed). If it fails:
```bash
curl "https://wttr.in/North%20Vancouver?format=3"
```

Should return weather text. If not, wttr.in may be down. Check:
```bash
curl "https://wttr.in/?format=3"
```

### Todos always show "To-Do list is in your BlackStarr app"

This is expected initially. The briefing script will be enhanced to read todos from `/workspace/mysite/data/state.json` once the todo structure is finalized in the app.

For now, todos are shown in the app itself, and you get weather + motivation in the briefing.

## Customization

### Change the time

Edit the cron line:
```bash
# 30 6 = 6:30 AM
# Change to:
# 0 8  = 8:00 AM
# 30 12 = 12:30 PM
# etc.
```

### Change the location

Edit daily-briefing.sh:
```bash
WEATHER=$(curl -s "https://wttr.in/YOUR_LOCATION?format=3" 2>/dev/null ...)
```

### Disable/Enable

**Disable:**
```bash
crontab -e
# Comment out the line with #
# # 30 6 * * * /workspace/mysite/daily-briefing.sh
```

**Enable:**
```bash
crontab -e
# Uncomment the line
# 30 6 * * * /workspace/mysite/daily-briefing.sh
```

## Security Notes

- **Bot Token:** Keep this secret. Never commit to git or share publicly.
- **Chat ID:** This is your Telegram user ID. It's how the bot knows where to send messages.
- **Environment Variables:** Store in shell profile or `.env` file (not in git).

## File Locations

- Script: `/workspace/mysite/daily-briefing.sh`
- Data: `/workspace/mysite/data/state.json` (todos will come from here)
- Logs: Check cron logs with `grep CRON /var/log/syslog`

## Testing Commands

```bash
# Test script directly
/workspace/mysite/daily-briefing.sh

# Test weather
curl "https://wttr.in/North%20Vancouver?format=3"

# Check cron is installed
which cron

# List your cron jobs
crontab -l

# Edit cron jobs
crontab -e

# View cron logs (Linux)
grep CRON /var/log/syslog | tail -20

# View cron logs (macOS)
log stream --predicate 'process == "cron"' --level debug
```

## Next Steps

1. ✅ Create Telegram bot (get token)
2. ✅ Get your chat ID
3. ✅ Set environment variables
4. ✅ Test the script
5. ✅ Add to crontab
6. Enjoy your daily briefing! 🎩

---

**Questions?** Check the script or logs. Most issues are environment variable related.
