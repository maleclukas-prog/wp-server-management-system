#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MYSQL BACKUP MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_MYSQL_BACKUP"
exec >> "$LOG_FILE" 2>&1

if [ "$target" = "list" ]; then
    echo -e "${YELLOW}📋 Available MySQL Backups:${NC}"
    echo "=========================================================="
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        count=$(find "$BACKUP_MYSQL_DIR" -name "db-$name-*.sql.gz" 2>/dev/null | wc -l)
        latest=$(ls -t "$BACKUP_MYSQL_DIR"/db-$name-*.sql.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null)
        echo "   📂 $name: $count backups (Latest: ${latest:-none})"
    done
    exit 0
fi

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [[ "$target" == "all" || "$target" == "$name" ]]; then
        if [ -f "$path/wp-config.php" ]; then
            DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=${DB_HOST:-localhost}
            
            if mysqldump --single-transaction --quick -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz"; then
                size=$(du -h "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz" | cut -f1)
                echo "   ${GREEN}✅ Database backup for $name: $size${NC}"
            else
                echo "   ${RED}❌ Failed to backup database for $name${NC}"
            fi
        else
            echo "   ${YELLOW}⚠️ wp-config.php not found for $name${NC}"
        fi
    fi
done

# Clean old backups
find "$BACKUP_MYSQL_DIR" -name "*.sql.gz" -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null