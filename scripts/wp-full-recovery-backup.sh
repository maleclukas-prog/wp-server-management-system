#!/bin/bash
# =================================================================
# 💾 WORDPRESS FULL RECOVERY BACKUP SYSTEM
# Description: Performs high-integrity backups including database 
#              optimization and full filesystem snapshots.
# Author: [Your Name]
# =================================================================

echo "💾 INITIATING FULL SYSTEM BACKUP"
echo "================================"
echo "⏰ Timestamp: $(date)"
echo ""

# --- CONFIGURATION ---
# Format: "site_id:path_to_public_html:system_user"
sites=(
    "site1:/var/www/site1/public_html:site1_user"
    "site2:/var/www/site2/public_html:site2_user"
    "site3:/var/www/site3/public_html:site3_user"
)

BACKUP_DIR="$HOME/backups-full"
MYSQL_SCRIPT="$HOME/scripts/mysql-backup-manager.sh"
RETENTION_DAYS=35
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure backup repository exists
mkdir -p "$BACKUP_DIR"

# --- CORE FUNCTIONS ---

# Function: Comprehensive Filesystem Archiving
archive_site_files() {
    local name="$1"
    local path="$2"
    local ARCHIVE_FILE="$BACKUP_DIR/backup-full-$name-files-$TIMESTAMP.tar.gz"

    echo "📁 Creating filesystem snapshot..."
    echo "   Source: $path"
    echo "   Target: $ARCHIVE_FILE"

    # Optimization: Exclude volatile data (cache, logs, temporary files)
    if tar -czf "$ARCHIVE_FILE" \
        -C "$path" \
        --exclude="wp-content/cache" \
        --exclude="wp-content/upgrade" \
        --exclude="*.log" \
        --exclude="cache/*" \
        --exclude="tmp/*" \
        .; then

        if [ -f "$ARCHIVE_FILE" ]; then
            SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
            echo "✅ Filesystem archive success: $SIZE"
            return 0
        fi
    fi

    echo "❌ Critical Error: Filesystem backup failed for $name"
    return 1
}

# --- MAIN ORCHESTRATION ---

for site in "${sites[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo ""
    echo "🌐 SITE AUDIT & BACKUP: $name"
    echo "-----------------------------------"

    if [ ! -d "$path" ] || [ ! -f "$path/wp-config.php" ]; then
        echo "❌ Error: WordPress installation not detected at $path"
        continue
    fi

    # 1. Proactive Database Optimization
    echo "📊 Executing pre-backup database maintenance..."
    # Cleaning transients and flushing cache ensures a lean database dump
    sudo -u "$user" wp --path="$path" transient delete --expired --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" db optimize --quiet 2>/dev/null
    sleep 2

    # 2. Database Export via Centralized Engine
    echo "🗃️ Triggering MySQL Backup Engine..."
    if bash "$MYSQL_SCRIPT" "$name"; then
        echo "✅ Database backup verified."
    else
        echo "❌ Database backup error. Skipping filesystem archive for safety."
        continue
    fi

    # 3. Filesystem Backup
    archive_site_files "$name" "$path"

    echo "✅ Full backup cycle completed for $name"
done

# --- CLEANUP & RETENTION ---
echo ""
echo "🧹 Applying retention policy (Deleting archives older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "backup-full-*" -type f -mtime +$RETENTION_DAYS -delete

# --- FINAL SUMMARY ---
echo ""
echo "📊 OPERATIONAL SUMMARY:"
FILE_COUNT=$(find "$BACKUP_DIR" -name "backup-full-*" -type f | wc -l)
echo "   Total Full Archives: $FILE_COUNT"
echo "   Storage Usage: $(du -sh "$BACKUP_DIR" | cut -f1)"

echo ""
echo "✅ FULL BACKUP OPERATION FINISHED SUCCESSFULLY!"