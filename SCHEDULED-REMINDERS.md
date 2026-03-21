# BlackStarr Scheduled Reminders Setup

**Automated reminders at exact times via Telegram:**
- 6:30 AM EDT — Daily briefing (weather + to-do's + motivation)
- 9:30 PM EDT — Evening routine checklist

## How It Works

```
VPS Cron (exact time)
    ↓
Creates trigger file
    ↓
Gerard checks triggers during heartbeat
    ↓
Sends message to your Telegram
    ↓
Deletes trigger file
```

## Setup (2 steps)

### 1. Add to VPS Crontab

```bash
crontab -e
```

Add these two lines:

```bash
# 6:30 AM EDT - Daily briefing
30 6 * * * /workspace/mysite/schedule-reminders.sh briefing

# 9:30 PM EDT - Evening routine
30 21 * * * /workspace/mysite/schedule-reminders.sh routine
```

Verify:
```bash
crontab -l
```

### 2. Done!

That's it. Cron will create trigger files at exact times, and I'll send the messages during heartbeats.

## What You'll Receive

### 6:30 AM Briefing

```
📅 Saturday, March 21, 2026 — 6:30 AM EDT

⛅ Weather: North Vancouver
Partly cloudy, 8°C. High 12°C.

✓ Today's Priorities
- [ ] Organize kitchen pantry
- [ ] Get Sean a haircut
- [ ] Josiane practice bus

💪 Your Outlook
You've got a solid weekend ahead. Focus on high-priority items and you'll have a productive day. Remember: small wins compound. 🌟
```

### 9:30 PM Routine

```
🌙 Evening Routine — 9:30 PM

Your nightly checklist:

☐ Charge Sean's iPad
☐ Take Josiane's phone away
☐ David make lunch for work
☐ Turn off lights and lock doors

---
Set up reminders for a smooth morning tomorrow!
```

## Files

- **Trigger script:** `/workspace/mysite/schedule-reminders.sh`
- **Trigger directory:** `/workspace/mysite/triggers/`
- **Briefing trigger:** `triggers/briefing.trigger`
- **Routine trigger:** `triggers/routine.trigger`

## Testing

To test manually without waiting for cron:

```bash
# Test briefing
/workspace/mysite/schedule-reminders.sh briefing

# Check trigger was created
ls -l /workspace/mysite/triggers/

# I'll send the message during the next heartbeat
```

## Disable/Enable

**Disable:**
```bash
crontab -e
# Comment out the lines with #
```

**Enable:**
```bash
crontab -e
# Uncomment the lines
```

## How I Check

During heartbeats, I:
1. List `/workspace/mysite/triggers/`
2. If `briefing.trigger` exists → send briefing message + delete file
3. If `routine.trigger` exists → send routine message + delete file
4. Move on to other checks

Simple, reliable, no external dependencies.

---

**Questions?** Check the trigger directory or test manually.
