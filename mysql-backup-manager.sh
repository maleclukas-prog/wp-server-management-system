#!/bin/bash
# =================================================================
# 🗄️  MYSQL DATABASE BACKUP MANAGER (WordPress-Optimized)
# Description: Automatically discovers MySQL credentials from 
#              wp-config.php and performs secure backups.
# Author: [Your Name]
# =================================================================

echo "🗄️  MYSQL DATABASE BACKUP ENGINE"
echo "==========================================================="
echo "⏰ Execution Time: $(date)"
echo ""

# Configuration
BACKUP_DIR="/home/ubuntu/mysql-backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Logic: Extract MySQL credentials from wp-config.php using Regex
get_mysql_credentials() {
    local wp_path="$1"
    local config_file="$wp_path/wp-config.php"

    if [ ! -f "$config_file" ]; then
        echo "❌ WordPress configuration not found: $config_file"
        return 1
    fi

    # Parsing credentials (ignoring commented-out lines)
    DB_NAME=$(grep -E "define.*DB_NAME" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_NAME'.*'\(.*\)'.*/\1/p" | head -1)
    DB_USER=$(grep -E "define.*DB_USER" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_USER'.*'\(.*\)'.*/\1/p" | head -1)
    DB_PASSWORD=$(grep -E "define.*DB_PASSWORD" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=$(grep -E "define.*DB_HOST" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_HOST'.*'\(.*\)'.*/\1/p" | head -1)

    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
        echo "❌ Extraction failed: Metadata missing in $config_file"
        return 1
    fi

    echo "✅ Metadata extracted for: $DB_NAME"
    return 0
}

# Logic: Execute mysqldump with security flags
backup_single_database() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local db_host="$4"
    local backup_file="$5"

    echo "💾 Dumping database: $db_name"

    # --single-transaction: Prevents table locking (ideal for production)
    # --no-tablespaces: Prevents permission-related warnings
    if mysqldump --single-transaction --quick --lock-tables=false --no-tablespaces \
        -h "$db_host" \
        -u "$db_user" \
        -p"$db_password" \
        "$db_name" 2> /dev/null | gzip > "$backup_file"; then
        SIZE=$(du -h "$backup_file" | cut -f1)
        echo "✅ Success: $backup_file ($SIZE)"
        return 0
    else
        echo "❌ Critical: Backup failed for $db_name"
        rm -f "$backup_file" # Clean up failed file
        return 1
    fi
}

# Logic: Validate MySQL connectivity
test_mysql_connection() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local db_host="$4"

    if mysql -h "$db_host" -u "$db_user" -p"$db_password" -e "USE $db_name" 2> /dev/null; then
        echo "✅ Database connection: OK"
        return 0
    else
        echo "❌ Database connection: FAILED"
        return 1
    fi
}

# Logic: Backup Orchestrator for specific site
process_backup() {
    local site_id="$1"
    local wp_path="$2"

    echo ""
    echo "🌐 Processing Site: $site_id"
    echo "📁 Directory: $wp_path"

    if ! get_mysql_credentials "$wp_path"; then return 1; fi
    if ! test_mysql_connection "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "${DB_HOST:-localhost}"; then return 1; fi

    BACKUP_FILE="$BACKUP_DIR/mysql-$site_id-$DB_NAME-$TIMESTAMP.sql.gz"
    backup_single_database "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "${DB_HOST:-localhost}" "$BACKUP_FILE"
}

# Site Mapping (Associative Array)
declare -A sites=(
    ["site1"]="/var/www/site1/public_html"
    ["site2"]="/var/www/site2/public_html"
    ["site3"]="/var/www/site3/public_html"
)

# CLI Interface Logic
case "${1:-all}" in
    "all")
        echo "🔄 Starting full backup cycle..."
        for site in "${!sites[@]}"; do
            process_backup "$site" "${sites[$site]}"
        done
        ;;
    "list")
        echo "📋 Managed Sites:"
        for site in "${!sites[@]}"; do echo "  - $site ($sites[$site])"; done
        exit 0
        ;;
    *)
        if [[ -n "${sites[$1]}" ]]; then
            process_backup "$1" "${sites[$1]}"
        else
            echo "❌ Site '$1' not found. Use 'list' to see options."
            exit 1
        fi
        ;;
esac

# Cleanup Service (Standard Retention Policy)
echo ""
echo "🧹 Applying retention policy (Removing files > $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "mysql-*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

echo ""
echo "✅ MYSQL BACKUP OPERATION COMPLETED!"