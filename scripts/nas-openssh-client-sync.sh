#!/bin/bash
# =================================================================
# 🔄 NAS SFTP SYNC - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

LOG_FILE="$LOG_DIR/nas_sync.log"
BACKUP_MODULES=("backups-full" "backups-lite" "backups-manual" "mysql-backups")

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

get_file_age_days() {
    local filename="$1"
    if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        local file_date="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        local file_ts=$(date -d "$file_date" +%s 2>/dev/null)
        echo $((( $(date +%s) - file_ts ) / 86400))
    else
        echo 0
    fi
}

sync_module() {
    local module="$1"
    local local_path="$HOME/$module"
    local remote_path="$NAS_PATH/$module"
    
    [ ! -d "$local_path" ] && { log "⚠️  Skipping: $module (not found)"; return 1; }
    
    # Ensure remote dir exists
    echo "mkdir -p $remote_path" | openssh-client -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" >/dev/null 2>&1
    
    # Upload new files
    local copied=0
    for file in "$local_path"/*; do
        [ ! -f "$file" ] && continue
        local filename=$(basename "$file")
        
        if ! echo "ls $remote_path/$filename" | openssh-client -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" 2>/dev/null | grep -q "$filename"; then
            echo "put \"$file\" \"$remote_path/\"" | openssh-client -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" >/dev/null 2>&1
            ((copied++))
        fi
    done
    
    # Retention on NAS
    local remote_files=$(echo "ls -1 $remote_path" | openssh-client -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" 2>/dev/null | grep -v "openssh-client>" | tr -d '\r')
    local keep=0; local deleted=0
    
    for file in $remote_files; do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        
        if [ $keep -lt $NAS_MIN_KEEP_COPIES ]; then
            ((keep++))
        elif [ $age -gt $NAS_RETENTION_DAYS ]; then
            echo "rm \"$remote_path/$file\"" | openssh-client -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" >/dev/null 2>&1
            ((deleted++))
        else
            ((keep++))
        fi
    done
    
    log "   📊 $module: +$copied uploaded, -$deleted removed, $keep total on NAS"
}

mkdir -p "$LOG_DIR"
log "🚀 Starting NAS sync cycle"
for module in "${BACKUP_MODULES[@]}"; do sync_module "$module"; done
log "✅ NAS sync completed"
