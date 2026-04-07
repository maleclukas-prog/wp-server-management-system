#!/bin/bash
# =================================================================
# 💾 FULL RECOVERY BACKUP - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

echo "💾 INITIATING FULL SYSTEM BACKUP"
echo "================================"
echo "⏰ Timestamp: $(date)"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_FULL_DIR"

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 Backing up: $name"
    
    if [ ! -f "$path/wp-config.php" ]; then
        echo "   ❌ Skipping - Invalid installation"
        continue
    fi
    
    # Pre-backup optimization
    sudo -u "$user" wp --path="$path" transient delete --expired --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" db optimize --quiet 2>/dev/null
    
    # Database backup
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    # Filesystem backup
    ARCHIVE="$BACKUP_FULL_DIR/backup-full-$name-files-$TIMESTAMP.tar.gz"
    sudo tar -czf "$ARCHIVE" -C "$path" --exclude="wp-content/cache" --exclude="*.log" . 2>/dev/null
    
    if [ -f "$ARCHIVE" ]; then
        SIZE=$(du -h "$ARCHIVE" | cut -f1)
        echo "   ✅ Filesystem: $SIZE"
    fi
done

# Cleanup old backups
find "$BACKUP_FULL_DIR" -name "backup-full-*" -type f -mtime +$RETENTION_FULL -delete
echo -e "\n✅ FULL BACKUP COMPLETED"
