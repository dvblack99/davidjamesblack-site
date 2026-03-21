#!/bin/bash
# BlackStarr Efficient Update Script
# Replaces 8-10 read/edit calls with 1 script execution
# Usage: ./update-blackstarr.sh --add-todo "Task" "Category" "Priority"

set -e

APP_DIR="/workspace/mysite/BlackStarr"
HTML_FILE="$APP_DIR/index.html"
STATE_FILE="/workspace/mysite/data/state.json"
BACKUP_SCRIPT="/workspace/mysite/backup-and-sync.sh"

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%SZ')
USER="${UPDATE_USER:-David}"

# Helper: Get next ID from HTML
get_next_id() {
    grep -o 'id:[0-9]*' "$HTML_FILE" | grep -o '[0-9]*' | sort -n | tail -1 | awk '{print $1+1}'
}

# Helper: Update activity log in state.json
log_activity() {
    local action="$1"
    local section="$2"
    
    jq ".activityLog |= [{timestamp:\"$TIMESTAMP\", user:\"$USER\", action:\"$action\", section:\"$section\"}, .[]] | .lastSync=\"$TIMESTAMP\"" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Process commands
case $1 in
    --add-todo)
        TEXT="$2"
        CATEGORY="${3:-Personal}"
        PRIORITY="${4:-Medium}"
        
        NEXT_ID=$(get_next_id)
        
        # Use sed to insert new todo (add before closing todos array bracket)
        sed -i "/todos: \[/,/\],/ {
            /\],$/i\
            { id:$NEXT_ID, text:'$TEXT', category:'$CATEGORY', priority:'$PRIORITY', status:'pending' },
        }" "$HTML_FILE"
        
        log_activity "Added to-do: $TEXT" "To-Do's"
        echo "✓ To-do added: $TEXT"
        ;;
        
    --add-grocery)
        ITEM="$2"
        CATEGORY="${3:-Pantry}"
        
        # Insert into grocery list
        sed -i "/category: '$CATEGORY/s/']/'\$ITEM', ]/" "$HTML_FILE"
        
        log_activity "Added grocery: $ITEM" "Food"
        echo "✓ Grocery added: $ITEM"
        ;;
        
    --add-event)
        DAY="$2"
        EVENT="$3"
        TIME="${4:-All Day}"
        
        # Insert into calendar
        sed -i "/$DAY: \[/a\\                { name:'$EVENT', time:'$TIME', description:'' }," "$HTML_FILE"
        
        log_activity "Added event: $EVENT" "Calendar"
        echo "✓ Event added: $EVENT ($DAY)"
        ;;
        
    *)
        echo "Usage: $0 --add-todo \"Text\" \"Category\" \"Priority\""
        echo "       $0 --add-grocery \"Item\" \"Category\""
        echo "       $0 --add-event \"Day\" \"Event\" \"Time\""
        exit 1
        ;;
esac

# Single backup/sync call
$BACKUP_SCRIPT > /dev/null 2>&1
echo "✅ Synced & backed up"
