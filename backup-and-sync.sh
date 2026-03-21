#!/bin/bash
# BlackStarr Backup & Sync Script
# Backs up data/state.json and commits to git
# Run manually or via cron

set -e

REPO_DIR="/workspace/mysite"
DATA_FILE="$REPO_DIR/data/state.json"
BACKUPS_DIR="$REPO_DIR/data/backups"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

echo "🔄 BlackStarr Backup & Sync"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if data file exists
if [ ! -f "$DATA_FILE" ]; then
    echo "❌ Error: $DATA_FILE not found"
    exit 1
fi

# Create timestamped backup
BACKUP_FILE="$BACKUPS_DIR/state.${TIMESTAMP}.json"
mkdir -p "$BACKUPS_DIR"
cp "$DATA_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Git commit
cd "$REPO_DIR"
git add data/state.json data/backups/*.json 2>/dev/null || true
git add . 2>/dev/null || true

if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit"
else
    git commit -m "Backup: $TIMESTAMP" --author="BlackStarr <blackstarr@davidjamesblack.com>"
    echo "✅ Git commit created"
fi

# Show backup count
BACKUP_COUNT=$(ls -1 "$BACKUPS_DIR"/state.*.json 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

# Cleanup old backups (keep last 30)
CLEANUP_COUNT=$((BACKUP_COUNT - 30))
if [ $CLEANUP_COUNT -gt 0 ]; then
    ls -t1 "$BACKUPS_DIR"/state.*.json | tail -n $CLEANUP_COUNT | xargs rm -f
    echo "🗑️  Removed $CLEANUP_COUNT old backups"
fi

echo "✅ Backup & sync complete"
