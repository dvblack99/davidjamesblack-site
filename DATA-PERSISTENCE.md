# BlackStarr Data Persistence & Sync

This document explains how BlackStarr stores and backs up your household data.

## Architecture

```
/workspace/mysite/
├── index.html                 # Landing page
├── BlackStarr/
│   └── index.html            # Main app
├── data/
│   ├── state.json            # Master state file (server)
│   └── backups/
│       └── state.*.json      # Timestamped backups
├── sync-server.js            # Node.js sync endpoint
├── backup-and-sync.sh        # Backup & git commit script
└── .git/                      # Version control
```

## Data Flow

### Browser to Server (Auto-Sync)

1. **Browser (BlackStarr app)**
   - Saves to browser `localStorage`
   - Simultaneously POSTs to sync server
   - Background, non-blocking

2. **Sync Server** (sync-server.js)
   - Receives POST on `/api/sync`
   - Creates timestamped backup
   - Saves to `data/state.json`

3. **Server Storage**
   - `data/state.json` = current master copy
   - `data/backups/` = timestamped archives

### Server to Git (Manual or Scheduled)

1. **Run backup script**
   ```bash
   /workspace/mysite/backup-and-sync.sh
   ```

2. **Script**
   - Backs up `data/state.json` with timestamp
   - Git adds & commits changes
   - Cleans up old backups (keeps last 30)

3. **Result**
   - Git history in `/.git/`
   - Full version control & audit trail

## Quick Start

### 1. Start the Sync Server

```bash
node /workspace/mysite/sync-server.js &
```

Server listens on `http://127.0.0.1:3737`

**Endpoints:**
- `POST /api/sync` — Save state (called from browser)
- `GET /api/state` — Load state
- `GET /api/health` — Health check

### 2. Manual Backup

```bash
/workspace/mysite/backup-and-sync.sh
```

This:
- Backs up `data/state.json`
- Commits to git
- Keeps last 30 backups
- Cleans old ones

### 3. Scheduled Backup (Cron)

Add to crontab:

```bash
# Daily backup at 2 AM EDT
0 2 * * * /workspace/mysite/backup-and-sync.sh >> /var/log/blackstarr-backup.log 2>&1
```

Or:

```bash
crontab -e
# Add the line above
```

## What Data is Saved

The `state.json` file contains:

```json
{
  "currentUser": null,
  "isAdmin": false,
  "darkMode": false,
  "journal": [],
  "ideas": { "ideas": [], "exploring": [], "doing": [] },
  "goals": [],
  "giftIdeas": {},
  "actionItems": {},
  "sectionLocks": { "food": false, "projects": false, ... },
  "activityLog": [],
  "lastSync": "2026-03-21T16:18:00Z",
  "version": "1.0"
}
```

## Backup Strategy

### Auto-Sync (Browser → Server)
- **When:** Every change (food, todos, journal, etc.)
- **Trigger:** Browser app calls `fetch('/api/sync')`
- **Result:** Server `state.json` always current
- **Backup:** Timestamped copy on first sync each hour

### Manual Sync (Admin Dashboard)
- **Button:** "↻ Sync Now" in Admin tab
- **Result:** Immediate confirmation
- **Log:** Logged as activity
- **Fallback:** If sync fails, local copy persists

### File Backup (Server → Git)
- **Script:** `backup-and-sync.sh`
- **Frequency:** Manual or cron (recommended daily)
- **Result:** Git commit with timestamp
- **Cleanup:** Keeps last 30 backups

## Recovery

### From Browser localStorage
- App stores copy locally
- Survives page refresh
- Lost if browser cache cleared

### From Server state.json
- Access at `/workspace/mysite/data/state.json`
- Always up-to-date (auto-synced)
- Human-readable JSON

### From Git History
- View commits: `cd /workspace/mysite && git log`
- Restore old version: `git checkout <commit> -- data/state.json`
- Full version control & audit trail

## Admin Features

### In BlackStarr App

**Admin Dashboard → Data Backup & Sync:**

- **↻ Sync Now** — Force immediate server sync
- **⬇️ Download JSON** — Export backup file to computer
- Sync status updates shown

### Manual Download
1. Open BlackStarr as admin
2. Go to Admin → Data Backup & Sync
3. Click "⬇️ Download JSON"
4. File saved to Downloads: `blackstarr-backup-YYYY-MM-DD.json`

## Monitoring

### Check Sync Status

```bash
# Test sync server
curl http://127.0.0.1:3737/api/health

# View current state
curl http://127.0.0.1:3737/api/state | jq '.'
```

### Check Backups

```bash
# List all backups
ls -lh /workspace/mysite/data/backups/

# Count backups
ls -1 /workspace/mysite/data/backups/ | wc -l

# View git log
cd /workspace/mysite && git log --oneline -10
```

### Check Git Status

```bash
cd /workspace/mysite
git status
git log -5 --oneline
git show --stat HEAD
```

## Disaster Recovery

### If localhost data lost:

1. **From git:**
   ```bash
   cd /workspace/mysite
   git checkout HEAD -- data/state.json
   ```

2. **From backup folder:**
   ```bash
   cp /workspace/mysite/data/backups/state.2026-03-21_12-00-00.json \
      /workspace/mysite/data/state.json
   ```

3. **From GitHub (if pushed):**
   ```bash
   git pull origin main
   ```

## GitHub Integration (Optional)

To push to GitHub:

```bash
cd /workspace/mysite

# Add remote
git remote add origin https://github.com/YOUR_USER/blackstarr-data.git

# Push
git push -u origin main

# Future pushes
git push origin main
```

Then use GitHub as off-site backup:
- Full version history
- Can access from anywhere
- Automated deployments possible

## Troubleshooting

### Sync Server Not Running

```bash
# Check if running
lsof -i :3737

# Start it
node /workspace/mysite/sync-server.js

# Or daemonize with nohup
nohup node /workspace/mysite/sync-server.js > /tmp/sync-server.log 2>&1 &
```

### Git Permission Errors

```bash
# Fix safe directory
git config --global --add safe.directory /workspace/mysite
```

### Backup Script Fails

```bash
# Test it
bash -x /workspace/mysite/backup-and-sync.sh

# Check permissions
ls -l /workspace/mysite/backup-and-sync.sh
ls -l /workspace/mysite/data/

# Run with sudo if needed
sudo /workspace/mysite/backup-and-sync.sh
```

## Summary

| Layer | Storage | Frequency | Persistence |
|-------|---------|-----------|------------|
| Browser | localStorage | Real-time | Session |
| Server | state.json | Auto-sync | Long-term |
| Backups | backups/*.json | Manual/Cron | Archives |
| Git | .git/ | Manual | Version control |
| GitHub | Remote repo | Manual push | Redundant backup |

Your data is safe, versioned, and recoverable at every level. 🎩
