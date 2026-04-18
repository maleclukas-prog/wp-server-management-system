#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# ⚡ ESSENTIAL ASSETS BACKUP (LITE) - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

echo "⚡ INITIATING LITE ASSETS BACKUP"
echo "================================"
echo "⏰ Timestamp: $(date)"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_LITE_DIR"

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 Processing: $name"
    
    if [ ! -f "$path/wp-config.php" ]; then
        echo "   ❌ Skipping"
        continue
    fi
    
    # Database backup
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    # Asset backup (uploads, themes, plugins, config)
    ARCHIVE="$BACKUP_LITE_DIR/backup-lite-$name-assets-$TIMESTAMP.tar.gz"
    sudo tar -czf "$ARCHIVE" -C "$path" \
        wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    
    if [ -f "$ARCHIVE" ]; then
        SIZE=$(du -h "$ARCHIVE" | cut -f1)
        echo "   ✅ Assets: $SIZE"
    fi
done

find "$BACKUP_LITE_DIR" -name "backup-lite-*" -type f -mtime +$RETENTION_LITE -delete
echo -e "\n✅ LITE BACKUP COMPLETED"
