#!/bin/bash
# =================================================================
# 🗄️  MYSQL BACKUP MANAGER - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

BACKUP_DIR="$BACKUP_MYSQL_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

get_mysql_creds() {
    local config="$1/wp-config.php"
    [ ! -f "$config" ] && return 1
    
    DB_NAME=$(grep -E "define.*DB_NAME" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_NAME'.*'\(.*\)'.*/\1/p" | head -1)
    DB_USER=$(grep -E "define.*DB_USER" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_USER'.*'\(.*\)'.*/\1/p" | head -1)
    DB_PASS=$(grep -E "define.*DB_PASSWORD" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=$(grep -E "define.*DB_HOST" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_HOST'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=${DB_HOST:-localhost}
    
    [ -z "$DB_NAME" ] && return 1
    return 0
}

backup_site() {
    local name="$1"
    local path="$2"
    
    if ! get_mysql_creds "$path"; then
        echo "   ❌ Failed to extract credentials"
        return 1
    fi
    
    local backup_file="$BACKUP_DIR/mysql-$name-$DB_NAME-$TIMESTAMP.sql.gz"
    
    if mysqldump --single-transaction --quick --no-tablespaces \
        -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$backup_file"; then
        echo "   ✅ Database: $DB_NAME"
        return 0
    else
        rm -f "$backup_file"
        return 1
    fi
}

case "${1:-all}" in
    "all")
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            echo -e "\n🌐 Processing: $name"
            backup_site "$name" "$path"
        done
        ;;
    "list")
        echo "📋 Managed Sites:"
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            echo "  - $name ($path)"
        done
        exit 0
        ;;
    *)
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            if [ "$name" = "$1" ]; then
                backup_site "$name" "$path"
                exit $?
            fi
        done
        echo "❌ Site '$1' not found"
        exit 1
        ;;
esac

find "$BACKUP_DIR" -name "mysql-*.sql.gz" -type f -mtime +$RETENTION_MYSQL -delete
echo -e "\n✅ MYSQL BACKUP COMPLETED"
