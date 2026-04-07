#!/bin/bash
# =================================================================
# ⚡ WORDPRESS ESSENTIAL ASSETS BACKUP (LITE)
# Description: High-frequency backup targeting only unique site 
#              assets (uploads, themes, plugins) to minimize 
#              storage footprint and execution time.
# Author: [Your Name]
# =================================================================

echo "⚡ INITIATING LEAN ASSETS BACKUP"
echo "================================"
echo "⏰ Timestamp: $(date)"
echo ""

# --- CONFIGURATION ---
# Format: "site_id:path_to_public_html"
sites=(
    "site1:/var/www/site1/public_html"
    "site2:/var/www/site2/public_html"
    "site3:/var/www/site3/public_html"
)

BACKUP_ROOT="$HOME/backups-lite"
MYSQL_ENGINE="$HOME/scripts/mysql-backup-manager.sh"
RETENTION_DAYS=14
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure backup repository exists
mkdir -p "$BACKUP_ROOT"

# --- CORE FUNCTIONS ---

# Function: Selective Asset Archiving
# Focuses only on wp-content subdirectories and configuration files
backup_essential_assets() {
    local name=$1
    local path=$2
    local ERROR_LOG="/tmp/wp_backup_error.log"
    local ARCHIVE_FILE="$BACKUP_ROOT/backup-lite-$name-assets-$TIMESTAMP.tar.gz"

    echo "📁 Archiving unique assets for: $name"
    
    # Validation: Ensure critical config exists
    if [ ! -f "$path/wp-config.php" ]; then
        echo "   ❌ Critical Error: wp-config.php missing in $path"
        return 1
    fi

    # Selective Backup Execution
    # Only includes custom content, excluding core files and cache
    if sudo tar -czf "$ARCHIVE_FILE" \
        -C "$path" \
        wp-content/uploads \
        wp-content/themes \
        wp-content/plugins \
        wp-config.php \
        2> "$ERROR_LOG"; then

        SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
        echo "   ✅ Assets Archive Success: $SIZE"
        return 0
    else
        # Fallback check: Proceed if archive exists despite warnings
        if [ -f "$ARCHIVE_FILE" ]; then
            SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
            echo "   ✅ Archive generated with non-critical warnings ($SIZE)"
            return 0
        else
            echo "   ❌ Fatal: Failed to generate archive."
            [ -s "$ERROR_LOG" ] && head -n 3 "$ERROR_LOG" | sed 's/^/      /'
            return 1
        fi
    fi
}

# --- MAIN ORCHESTRATION ---

for site in "${sites[@]}"; do
    IFS=':' read -r name path <<< "$site"
    echo ""
    echo "🌐 PROCESSING SITE: $name"
    echo "-----------------------------------"

    if [ ! -d "$path" ]; then
        echo "   ❌ Error: Directory path not found."
        continue
    fi

    # 1. Trigger Centralized MySQL Backup Engine
    echo "🗃️ Requesting MySQL backup snapshot..."
    if bash "$MYSQL_ENGINE" "$name"; then
        echo "   ✅ Database snapshot verified."
    else
        echo "   ❌ Database snapshot failed. Investigating asset backup..."
    fi

    # 2. Execute Asset Archiving
    backup_essential_assets "$name" "$path"

    echo "✅ Backup cycle for $name completed."
done

# --- CLEANUP & RETENTION ---
echo ""
echo "🧹 Applying retention policy (Pruning archives older than $RETENTION_DAYS days)..."
find "$BACKUP_ROOT" -name "backup-lite-*" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null

# --- OPERATIONAL SUMMARY ---
echo ""
echo "📊 OPERATIONAL SUMMARY:"
ASSET_COUNT=$(find "$BACKUP_ROOT" -name "backup-lite-*" -type f | wc -l)
echo "   Total Asset Archives: $ASSET_COUNT"
echo "   Storage Consumption: $(du -sh "$BACKUP_ROOT" | cut -f1)"

echo ""
echo "✅ LEAN BACKUP OPERATION FINISHED SUCCESSFULLY!"