# North Shore Free Deals Scraper

**Location:** `/deals/` 
**URL:** `https://davidjamesblack.com/deals/`

## What It Does

- 🔍 Scrapes Craigslist daily for free items in North Shore Vancouver
- 🚗 Filters for items that fit in an SUV  
- 💰 Estimates resale value for each item
- 📊 Generates HTML report with top 10 highest-value deals
- 🔗 Links directly to Craigslist postings

## Files

- `craigslist_scraper.py` — Main scraper script
- `run-scraper.sh` — Cron wrapper
- `index.html` — Live report (auto-generated daily)
- `archive/` — Historical reports (one per day)

## Setup Cron Job

```bash
crontab -e
```

Add:
```bash
0 8 * * * /workspace/mysite/deals/run-scraper.sh
```

This runs the scraper every day at 8 AM EDT.

## Manual Run

```bash
cd /workspace/mysite/deals
python3 craigslist_scraper.py
```

## How It Works

1. **Search:** Craigslist free items (North Shore)
2. **Filter:** Size (fits SUV), exclude large furniture
3. **Estimate:** Resale value based on category & keywords
   - Electronics: 50% retail
   - Tools: 40% retail
   - Furniture: 45% retail
   - Collectibles: 60% retail
   - etc.
4. **Rank:** Top 10 by estimated value
5. **Generate:** HTML with clickable links
6. **Archive:** Previous reports saved daily

## Customization

Edit `craigslist_scraper.py`:

**Change categories/multipliers:**
```python
CATEGORIES = {
    "furniture": 0.45,      # Adjust percentage
    "electronics": 0.50,
    ...
}
```

**Add/remove keywords:**
```python
SIZE_KEYWORDS = ["small", "medium", "chair", ...]
EXCLUDE_KEYWORDS = ["car", "truck", "full room", ...]
```

**Adjust base prices:**
```python
price_map = {
    "laptop": 600,
    "desk": 500,
    ...
}
```

## Dependencies

- Python 3
- `requests` — HTTP library
- `beautifulsoup4` — HTML parsing

Installed via: `pip3 install requests beautifulsoup4`

## Troubleshooting

**No deals found:**
- Craigslist structure may have changed
- No matching items on the day
- Check Craigslist directly: https://vancouver.craigslist.org/search/sss

**Script fails:**
- Check Python packages: `python3 -c "import requests; import bs4"`
- Run manually: `cd /deals && python3 craigslist_scraper.py`
- Check cron logs: `grep CRON /var/log/system.log | tail -20`

**Old reports in archive:**
- View: `ls -la /workspace/mysite/deals/archive/`
- Old files automatically created daily
- Manual cleanup: `rm /workspace/mysite/deals/archive/deals_*.html`

## Notes

- First run may take 10-20 seconds
- Subsequent runs are faster
- Report updates at 8 AM daily
- Previous report moved to archive
- All links are live Craigslist listings

---

**Live report:** https://davidjamesblack.com/deals/
