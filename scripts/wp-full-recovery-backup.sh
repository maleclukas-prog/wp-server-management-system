#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - FULL RECOVERY BACKUP
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_FULL_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "💾 FULL BACKUP v4.2 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📦 Snapshotting $name..."
    
    # Database backup first
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    # Full files backup
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    
    if [ -f "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Full backup created: $size${NC}"
    else
        echo "   ❌ Failed to create full backup"
    fi
done

# Clean old backups
echo -e "\n🧹 Cleaning old backups (older than $RETENTION_FULL days)..."
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime "+$RETENTION_FULL" -delete 2>/dev/null

echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ FULL BACKUP CYCLE COMPLETED${NC}"