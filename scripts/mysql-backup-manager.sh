#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🗄️ MYSQL BACKUP MANAGER - WITH LIST OPTION
# Description: Automatic credential extraction from wp-config.php
# Usage: mysql-backup-manager.sh [all|site_name|list]
# =================================================================

source $HOME/scripts/wsms-config.sh

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_MYSQL_DIR"

mkdir -p "$BACKUP_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function: Extract MySQL credentials from wp-config.php
get_mysql_credentials() {
    local wp_path="$1"
    local config_file="$wp_path/wp-config.php"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    DB_NAME=$(grep -E "define.*DB_NAME" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_NAME'.*'\(.*\)'.*/\1/p" | head -1)
    DB_USER=$(grep -E "define.*DB_USER" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_USER'.*'\(.*\)'.*/\1/p" | head -1)
    DB_PASS=$(grep -E "define.*DB_PASSWORD" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=$(grep -E "define.*DB_HOST" "$config_file" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_HOST'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=${DB_HOST:-localhost}
    
    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
        return 1
    fi
    
    return 0
}

# Function: Backup single database
backup_database() {
    local site_name="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local db_host="$5"
    
    local backup_file="$BACKUP_DIR/db-$site_name-$db_name-$TIMESTAMP.sql.gz"
    
    echo -e "   💾 Dumping: $db_name"
    
    if mysqldump --single-transaction --quick --lock-tables=false --no-tablespaces \
        -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" 2>/dev/null | gzip > "$backup_file"; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "   ${GREEN}✅ $db_name: $backup_file ($size)${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Backup failed for $db_name${NC}"
        rm -f "$backup_file"
        return 1
    fi
}

# Function: Backup WordPress site
backup_wordpress_site() {
    local site_name="$1"
    local wp_path="$2"
    
    echo -e "\n${YELLOW}🌐 Processing: $site_name${NC}"
    
    if [ ! -d "$wp_path" ] || [ ! -f "$wp_path/wp-config.php" ]; then
        echo -e "   ${RED}❌ WordPress not found at: $wp_path${NC}"
        return 1
    fi
    
    if ! get_mysql_credentials "$wp_path"; then
        echo -e "   ${RED}❌ Cannot extract MySQL credentials${NC}"
        return 1
    fi
    
    backup_database "$site_name" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
}

# Function: List available sites
list_sites() {
    echo -e "${CYAN}📋 AVAILABLE WORDPRESS SITES:${NC}"
    echo "=========================================================="
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        echo -e "   ${GREEN}✅${NC} $name: $path"
    done
    echo -e "\n${CYAN}📋 BACKUP DIRECTORY:${NC} $BACKUP_DIR"
    
    # Show existing backups
    echo -e "\n${CYAN}📋 EXISTING DATABASE BACKUPS:${NC}"
    local count=$(find "$BACKUP_DIR" -name "db-*.sql.gz" -type f 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
        echo "   Found $count database backups:"
        find "$BACKUP_DIR" -name "db-*.sql.gz" -type f 2>/dev/null | sort | while read -r file; do
            local size=$(du -h "$file" 2>/dev/null | cut -f1)
            local date_str=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
            echo "      📁 $(basename "$file") ($size, $date_str)"
        done | head -10
        if [ $count -gt 10 ]; then
            echo "      ... and $((count - 10)) more"
        fi
    else
        echo "   No database backups found"
    fi
}

# Function: Clean old backups
clean_old_backups() {
    echo -e "\n${CYAN}🧹 Cleaning old MySQL backups (>$RETENTION_MYSQL days)...${NC}"
    local deleted=$(find "$BACKUP_DIR" -name "db-*.sql.gz" -type f -mtime +$RETENTION_MYSQL -delete -print 2>/dev/null | wc -l)
    if [ $deleted -gt 0 ]; then
        echo -e "   ${GREEN}✅ Deleted $deleted old files${NC}"
    else
        echo -e "   ${GREEN}✅ No old files to delete${NC}"
    fi
}

# ============================================
# MAIN
# ============================================
case "${1:-all}" in
    all)
        echo -e "${CYAN}🗄️ MYSQL BACKUP - ALL SITES${NC}"
        echo "=========================================================="
        echo "⏰ $(date)"
        
        local success=0
        local total=0
        
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            if backup_wordpress_site "$name" "$path"; then
                success=$((success + 1))
            fi
            total=$((total + 1))
        done
        
        echo -e "\n${CYAN}==========================================================${NC}"
        echo -e "${CYAN}📊 SUMMARY:${NC} $success/$total sites backed up"
        clean_old_backups
        ;;
    
    list|l|--list)
        list_sites
        ;;
    
    uszatek|test|photo)
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            if [ "$name" = "$1" ]; then
                backup_wordpress_site "$name" "$path"
                break
            fi
        done
        ;;
    
    *)
        echo "❌ Unknown option: $1"
        echo ""
        echo "Usage: $0 [all|list|uszatek|test|photo]"
        echo ""
        echo "Examples:"
        echo "  $0 all          # Backup all WordPress databases"
        echo "  $0 uszatek      # Backup only uszatek database"
        echo "  $0 list         # List available sites and existing backups"
        echo "  $0 list         # Show all sites and existing backups"
        exit 1
        ;;
esac