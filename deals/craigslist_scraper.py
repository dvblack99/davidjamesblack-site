#!/usr/bin/env python3
"""
BlackStarr Craigslist Deals Scraper
Finds top 10 free items on North Shore that fit in SUV + have resale value
"""

import requests
import json
import os
from datetime import datetime
from bs4 import BeautifulSoup
import re

# Configuration
CRAIGSLIST_BASE = "https://vancouver.craigslist.org/search/sss"
OUTPUT_DIR = "/workspace/mysite/deals"
ARCHIVE_DIR = os.path.join(OUTPUT_DIR, "archive")

# Categories & resale value multipliers
CATEGORIES = {
    "furniture": 0.45,      # 45% of retail
    "electronics": 0.50,    # 50% of retail
    "tools": 0.40,          # 40% of retail
    "appliances": 0.35,     # 35% of retail
    "bikes": 0.55,          # 55% of retail
    "books": 0.15,          # 15% of retail
    "collectibles": 0.60,   # 60% of retail
}

# Size keywords (fits SUV)
SIZE_KEYWORDS = ["small", "medium", "chair", "desk", "table", "shelf", "lamp", "toolbox", "bike", "guitar", "monitor"]
EXCLUDE_KEYWORDS = ["car", "truck", "full room", "sofa set", "sectional", "full bed"]

class Deal:
    def __init__(self, title, url, price_estimate, category):
        self.title = title
        self.url = url
        self.price_estimate = price_estimate
        self.category = category
        self.posted_date = datetime.now().strftime("%Y-%m-%d")
    
    def __lt__(self, other):
        return self.price_estimate > other.price_estimate  # Sort by value (descending)

def estimate_value(title, category="general"):
    """Estimate resale value based on item type and keywords"""
    multiplier = CATEGORIES.get(category.lower(), 0.40)
    
    # Price estimation based on keywords
    price_map = {
        "laptop": 600, "computer": 700, "monitor": 300, "phone": 400,
        "couch": 1200, "sofa": 1200, "bed": 800, "desk": 500, "chair": 300,
        "tv": 400, "camera": 500, "drone": 600, "guitar": 400, "piano": 2000,
        "bike": 300, "bicycle": 300, "motorcycle": 5000, "truck": 15000,
        "tools": 200, "toolbox": 150, "drill": 200,
        "furniture": 400, "table": 400, "cabinet": 300,
    }
    
    base_value = 0
    for keyword, value in price_map.items():
        if keyword in title.lower():
            base_value = max(base_value, value)
    
    if base_value == 0:
        base_value = 200  # Default estimate
    
    return int(base_value * multiplier)

def scrape_craigslist():
    """Scrape Craigslist for free items"""
    deals = []
    
    try:
        # Search free items in Vancouver
        params = {
            "query": "free",
            "sort": "date",
            "max_price": 0,  # Free items only
        }
        
        response = requests.get(CRAIGSLIST_BASE, params=params, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Find listings
        listings = soup.find_all('div', class_='result-info')
        
        for listing in listings[:30]:  # Process first 30
            try:
                # Extract title and URL
                title_elem = listing.find('a', class_='result-title hdrlnk')
                if not title_elem:
                    continue
                
                title = title_elem.get_text(strip=True)
                url = title_elem.get('href', '')
                
                # Skip if doesn't fit SUV criteria
                skip = False
                for exclude in EXCLUDE_KEYWORDS:
                    if exclude.lower() in title.lower():
                        skip = True
                        break
                
                if skip:
                    continue
                
                # Check if size is appropriate
                fits_suv = any(keyword in title.lower() for keyword in SIZE_KEYWORDS)
                if not fits_suv and len(title) > 60:  # Likely large item if title is long
                    continue
                
                # Estimate category and value
                category = "general"
                for cat in CATEGORIES.keys():
                    if cat in title.lower():
                        category = cat
                        break
                
                value = estimate_value(title, category)
                
                # Create deal
                deal = Deal(title, url, value, category)
                deals.append(deal)
                
            except Exception as e:
                continue
        
        # Sort by value and get top 10
        deals.sort()
        return deals[:10]
        
    except Exception as e:
        print(f"Error scraping Craigslist: {e}")
        return []

def generate_html(deals):
    """Generate HTML report"""
    
    timestamp = datetime.now().strftime("%B %d, %Y at %H:%M %Z")
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>North Shore Free Deals - Top 10 Resale Value</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 1000px;
            margin: 0 auto;
        }}
        .header {{
            background: white;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }}
        .header h1 {{
            color: #333;
            margin-bottom: 10px;
        }}
        .header p {{
            color: #666;
            font-size: 0.95em;
        }}
        .deals-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }}
        .deal-card {{
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
            display: flex;
            flex-direction: column;
        }}
        .deal-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
        }}
        .deal-rank {{
            font-size: 0.85em;
            color: #999;
            margin-bottom: 8px;
        }}
        .deal-title {{
            font-size: 1.1em;
            font-weight: 600;
            color: #333;
            margin-bottom: 10px;
            line-height: 1.4;
        }}
        .deal-value {{
            font-size: 1.4em;
            color: #667eea;
            font-weight: bold;
            margin-bottom: 8px;
        }}
        .deal-category {{
            display: inline-block;
            background: #f0f0f0;
            color: #666;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.85em;
            margin-bottom: 15px;
        }}
        .deal-link {{
            background: #667eea;
            color: white;
            padding: 10px;
            border-radius: 6px;
            text-decoration: none;
            text-align: center;
            font-weight: 500;
            transition: background 0.2s;
            margin-top: auto;
        }}
        .deal-link:hover {{
            background: #764ba2;
        }}
        .footer {{
            text-align: center;
            color: white;
            margin-top: 30px;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎁 North Shore Free Deals</h1>
            <p>Top 10 Craigslist free items with highest resale value (fits in SUV)</p>
            <p style="margin-top: 10px; color: #999; font-size: 0.85em;">Updated: {timestamp}</p>
        </div>
        
        <div class="deals-grid">
"""
    
    if deals:
        for rank, deal in enumerate(deals, 1):
            html += f"""
            <div class="deal-card">
                <div class="deal-rank">#{rank}</div>
                <div class="deal-title">{deal.title}</div>
                <div class="deal-value">Est. ${deal.price_estimate}</div>
                <span class="deal-category">{deal.category.title()}</span>
                <a href="{deal.url}" target="_blank" class="deal-link">View on Craigslist →</a>
            </div>
"""
    else:
        html += """
            <div style="grid-column: 1/-1; background: white; padding: 40px; border-radius: 10px; text-align: center;">
                <p style="color: #999; font-size: 1.1em;">No deals found today. Check back later!</p>
            </div>
"""
    
    html += """
        </div>
        
        <div class="footer">
            <p>💡 Estimated resale values based on condition and market demand</p>
        </div>
    </div>
</body>
</html>
"""
    
    return html

def save_report(html):
    """Save HTML report and archive previous"""
    
    # Archive old report
    main_file = os.path.join(OUTPUT_DIR, "index.html")
    if os.path.exists(main_file):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        archive_file = os.path.join(ARCHIVE_DIR, f"deals_{timestamp}.html")
        os.rename(main_file, archive_file)
    
    # Write new report
    with open(main_file, 'w') as f:
        f.write(html)
    
    print(f"✅ Report saved to {main_file}")

def main():
    print("🔍 Scraping Craigslist for free items...")
    deals = scrape_craigslist()
    
    if deals:
        print(f"✅ Found {len(deals)} quality deals")
        html = generate_html(deals)
        save_report(html)
        print("✅ Report generated")
    else:
        print("⚠️  No deals found, generating empty report...")
        html = generate_html([])
        save_report(html)

if __name__ == "__main__":
    main()
