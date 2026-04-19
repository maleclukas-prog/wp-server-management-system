#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - NAS SFTP SYNC
# =================================================================

source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_NAS_SYNC"
ERROR_LOG="$LOG_NAS_ERRORS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "☁️ NAS SYNC - $(date)"
echo "=========================================================="

# Check if SSH key exists
if [ ! -f "$NAS_SSH_KEY" ]; then
    echo "❌ ERROR: SSH key not found at $NAS_SSH_KEY"
    echo "$(date): SSH key missing" >> "$ERROR_LOG"
    exit 1
fi

# Check if NAS_HOST is configured
if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
    echo "⚠️ WARNING: NAS_HOST not configured - sync skipped"
    exit 0
fi

sync_success=0
sync_fail=0

for module in backups-lite backups-full mysql-backups; do
    echo -e "\n📤 Processing $module..."
    
    if [ ! -d "$HOME/$module" ] || [ -z "$(ls -A "$HOME/$module" 2>/dev/null)" ]; then
        echo "   ⚠️ No files in $module - skipping"
        continue
    fi
    
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
mkdir -p $NAS_PATH/$module
put $HOME/$module/* $NAS_PATH/$module/
bye
SFTP_EOF
    then
        echo "   ✅ $module synced successfully"
        ((sync_success++))
    else
        echo "   ❌ $module sync FAILED"
        echo "$(date): Failed to sync $module" >> "$ERROR_LOG"
        ((sync_fail++))
    fi
done

echo -e "\n📊 SYNC SUMMARY:"
echo "   ✅ Successful: $sync_success module(s)"
echo "   ❌ Failed: $sync_fail module(s)"

echo "=========================================================="
echo "--- NAS Sync Finished: $(date) ---"
echo "=========================================================="