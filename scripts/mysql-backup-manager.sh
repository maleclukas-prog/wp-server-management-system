#!/bin/bash
# =================================================================
# 🗄️  ZERO-CONFIG MYSQL SNAPSHOT ENGINE
# Description: Automatically extracts credentials from wp-config.php 
#              to perform secure, compressed production dumps.
# =================================================================
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/mysql-backups"
target=${1:-all}

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [[ "$target" == "all" || "$target" == "$name" ]]; then
        echo -e "💾 Snapshotting database for: ${CYAN}$name${NC}"
        
        # Restore full Regex discovery logic
        DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"'" '{print $4}')
        DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"'" '{print $4}')
        DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"'" '{print $4}')
        DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"'" '{print $4}')

        if [ -z "$DB_NAME" ]; then
            echo -e "   ${RED}❌ Error: Could not extract metadata for $name${NC}"
            continue
        fi

        OUT="$BACKUP_DIR/db-$name-$DB_NAME-$TS.sql.gz"
        mysqldump --single-transaction --quick -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$OUT"
        
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Success:${NC} $(du -h "$OUT" | cut -f1)"
        else
            echo -e "   ${RED}❌ Dump Failed!${NC}"
        fi
    fi
done