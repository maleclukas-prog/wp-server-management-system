#!/bin/bash
# =================================================================
# 🔄 HYBRID CLOUD SYNC: SERVER TO SYNOLOGY NAS (SFTP)
# Description: Automated off-site backup synchronization. 
#              Features intelligent file-age detection and 
#              a "Minimum Copy" safety retention policy.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# --- CONFIGURATION ---
REMOTE_HOST="nas.your-domain.me"
REMOTE_PORT="58365"
REMOTE_USER="backup_operator"
REMOTE_BASE_DIR="/remote_backups/server_vault"
SSH_KEY="$HOME/.ssh/id_rsa_backup"

LOCAL_BASE_DIR="$HOME"
BACKUP_MODULES=("backups-full" "backups-lite" "backups-manual" "mysql-backups")

# Retention Policy
DAYS_TO_KEEP=120
MIN_KEEP_COPIES=2
LOG_FILE="$HOME/logs/nas_sync.log"

# UI Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# =================================================================
# Helper: Logging
log() { 
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 
}

# Helper: Extract age from filename (expects YYYYMMDD format)
get_file_age_days() {
    local filename="$1"
    if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        local file_date="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        local file_timestamp=$(date -d "$file_date" +%s 2> /dev/null)
        local current_timestamp=$(date +%s)
        echo $(((current_timestamp - file_timestamp) / 86400))
    else
        echo 0
    fi
}

# Core Module: Synchronization Engine
sync_directory() {
    local dir_name="$1"
    local local_path="$LOCAL_BASE_DIR/$dir_name"
    local remote_path="$REMOTE_BASE_DIR/$dir_name"

    echo -e "${CYAN}>>> SYNCING MODULE: $dir_name${NC}"
    [ ! -d "$local_path" ] && { log "⚠️  Skipping: $dir_name (Local directory missing)"; return 1; }

    # 1. Fetch Remote File Inventory
    local raw_remote_list=$(echo "ls -1 $remote_path" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_HOST" 2>/dev/null | tr -d '\r')
    
    # Ensure remote directory exists
    if [[ "$raw_remote_list" == *"not found"* || -z "$raw_remote_list" ]]; then
        log "📁 Creating remote directory: $remote_path"
        echo "mkdir $REMOTE_BASE_DIR
mkdir $remote_path" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_HOST" >/dev/null 2>&1
        raw_remote_list=""
    fi

    local remote_files=$(echo "$raw_remote_list" | grep -vE "(sftp>|Connected to|Fetching|^\.)" | sed "s|.*/||" | sort)

    # 2. Upload Phase (Differential Transfer)
    local copied=0; local skipped=0
    local local_files=$(ls -1 "$local_path")

    for file in $local_files; do
        if echo "$remote_files" | grep -q "^$file$"; then
            ((skipped++))
        else
            log "    📤 Uploading: $file"
            echo "put \"$local_path/$file\" \"$remote_path/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_HOST" >> "$LOG_FILE" 2>&1
            [ $? -eq 0 ] && ((copied++)) || log "    ${RED}❌ Error uploading: $file${NC}"
        fi
    done

    # 3. Retention Phase (NAS-side Cleanup)
    # Refresh remote list after upload
    raw_remote_list=$(echo "ls -1 $remote_path" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_HOST" 2>/dev/null | tr -d '\r')
    remote_files=$(echo "$raw_remote_list" | grep -vE "(sftp>|Connected to|Fetching|^\.)" | sed "s|.*/||" | sort -r)
    
    local keep_count=0; local deleted=0

    for file in $remote_files; do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        
        # Policy: Keep if it's within retention period OR it's one of the MIN_KEEP_COPIES
        if [ $keep_count -lt $MIN_KEEP_COPIES ]; then
            ((keep_count++))
        elif [ $age -gt $DAYS_TO_KEEP ]; then
            echo "rm \"$remote_path/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_HOST" >/dev/null 2>&1
            ((deleted++))
        else
            ((keep_count++))
        fi
    done

    # 4. Results Reporting
    echo -e "    📊 Results: Uploaded: ${GREEN}$copied${NC} | Skipped: $skipped | Removed: ${RED}$deleted${NC} | Total on NAS: ${CYAN}$keep_count${NC}"
    echo "----------------------------------------------------"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}   OFF-SITE NAS SYNCHRONIZATION START    ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    for module in "${BACKUP_MODULES[@]}"; do sync_directory "$module"; done
    log "🏁 Synchronization cycle completed."
}

main