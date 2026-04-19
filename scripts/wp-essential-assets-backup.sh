#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ESSENTIAL ASSETS BACKUP (LITE)
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_LITE_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "⚡ LITE BACKUP v4.2 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📁 Archiving $name assets..."
    
    # Database backup first
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    # Essential assets only
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" \
        -C "$path" \
        wp-content/uploads \
        wp-content/themes \
        wp-content/plugins \
        wp-config.php \
        .htaccess \
        2>/dev/null
    
    if [ -f "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Lite backup created: $size${NC}"
    fi
done

# Clean old backups
echo -e "\n🧹 Cleaning old lite backups (older than $RETENTION_LITE days)..."
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime "+$RETENTION_LITE" -delete 2>/dev/null

echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ LITE BACKUP CYCLE COMPLETED${NC}"