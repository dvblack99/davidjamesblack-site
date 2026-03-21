#!/bin/bash
# BlackStarr Deals Scraper - Daily Runner
# Called via cron at 8 AM EDT
# crontab: 0 8 * * * /workspace/mysite/deals/run-scraper.sh

cd /workspace/mysite/deals
python3 craigslist_scraper.py

# Backup the deals directory
sudo /workspace/backup-manager.sh backup > /dev/null 2>&1

echo "✅ Deals scraper completed at $(date '+%Y-%m-%d %H:%M:%S %Z')"
