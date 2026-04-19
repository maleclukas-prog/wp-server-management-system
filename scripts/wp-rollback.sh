#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ROLLBACK ENGINE
# Automated disaster recovery with pre-update snapshots
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

ROLLBACK_DIR="$BACKUP_ROLLBACK_DIR"
mkdir -p "$ROLLBACK_DIR"

# Get site configuration by name
get_site_config() {
    local target=$1
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ "$name" = "$target" ]; then
            echo "$site"
            return 0
        fi
    done
    return 1
}

# Send notification (optional)
send_notification() {
    local message=$1
    local level=${2:-info}
    
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[$level] WSMS: $message\"}" \
            "$SLACK_WEBHOOK_URL" > /dev/null 2>&1 || true
    fi
    
    if [ -n "$EMAIL_ALERT" ] && [ "$level" = "error" ]; then
        echo "$message" | mail -s "WSMS Alert: $level" "$EMAIL_ALERT" 2>/dev/null || true
    fi
}

# Create a snapshot for a site
create_snapshot() {
    local site_name=$1
    local site_config=$(get_site_config "$site_name")
    
    if [ -z "$site_config" ]; then
        echo -e "${RED}❌ Site '$site_name' not found in configuration${NC}"
        return 1
    fi
    
    IFS=':' read -r name path user <<< "$site_config"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_path="$ROLLBACK_DIR/$name/$timestamp"
    
    echo -e "${CYAN}📸 Creating snapshot for $name at $timestamp...${NC}"
    
    mkdir -p "$snapshot_path"
    
    echo "   📊 Backing up database..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    local latest_db=$(ls -t "$BACKUP_MYSQL_DIR/db-$name-"*.sql.gz 2>/dev/null | head -1)
    if [ -n "$latest_db" ]; then
        cp "$latest_db" "$snapshot_path/"
        echo "   ✅ Database: $(basename "$latest_db")"
    else
        echo "   ⚠️ No database backup found"
    fi
    
    echo "   📁 Backing up files..."
    tar -czf "$snapshot_path/files.tar.gz" \
        -C "$path" \
        wp-content/plugins \
        wp-content/themes \
        wp-includes \
        wp-admin \
        2>/dev/null
    
    sudo -u "$user" wp --path="$path" core version > "$snapshot_path/core_version.txt" 2>/dev/null
    sudo -u "$user" wp --path="$path" plugin list --format=csv > "$snapshot_path/plugins_before.csv" 2>/dev/null
    sudo -u "$user" wp --path="$path" theme list --format=csv > "$snapshot_path/themes_before.csv" 2>/dev/null
    
    echo "$path" > "$snapshot_path/site_path.txt"
    echo "$user" > "$snapshot_path/site_user.txt"
    
    local snapshot_size=$(du -sh "$snapshot_path" 2>/dev/null | cut -f1)
    echo -e "${GREEN}✅ Snapshot created: $snapshot_path ($snapshot_size)${NC}"
    
    send_notification "Snapshot created for $name ($snapshot_size)" "info"
    
    echo "$snapshot_path"
}

# List available snapshots
list_snapshots() {
    local site_name=$1
    
    if [ -n "$site_name" ]; then
        echo -e "${CYAN}📸 Snapshots for $site_name:${NC}"
        echo "=========================================================="
        
        if [ -d "$ROLLBACK_DIR/$site_name" ]; then
            for snapshot in $(ls -td "$ROLLBACK_DIR/$site_name"/*/ 2>/dev/null); do
                local name=$(basename "$snapshot")
                local size=$(du -sh "$snapshot" 2>/dev/null | cut -f1)
                local timestamp=$(echo "$name" | sed 's/_/ /g')
                echo "  📁 $name ($size) - $timestamp"
            done
        else
            echo "  No snapshots found for $site_name"
        fi
    else
        echo -e "${CYAN}📸 All Rollback Snapshots:${NC}"
        echo "=========================================================="
        
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            local count=$(find "$ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
            
            if [ "$count" -gt 0 ]; then
                local latest=$(ls -t "$ROLLBACK_DIR/$name" 2>/dev/null | head -1)
                local size=$(du -sh "$ROLLBACK_DIR/$name" 2>/dev/null | cut -f1)
                echo "  📂 $name: $count snapshots ($size) - Latest: $latest"
            else
                echo "  📂 $name: No snapshots"
            fi
        done
    fi
}

# Perform rollback
perform_rollback() {
    local site_name=$1
    local snapshot_name=$2
    
    local site_config=$(get_site_config "$site_name")
    if [ -z "$site_config" ]; then
        echo -e "${RED}❌ Site '$site_name' not found${NC}"
        return 1
    fi
    
    IFS=':' read -r name path user <<< "$site_config"
    
    local snapshot_path
    if [ -n "$snapshot_name" ]; then
        snapshot_path="$ROLLBACK_DIR/$name/$snapshot_name"
    else
        snapshot_path=$(ls -td "$ROLLBACK_DIR/$name"/*/ 2>/dev/null | head -1)
    fi
    
    if [ ! -d "$snapshot_path" ]; then
        echo -e "${RED}❌ No snapshot found for $name${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔄 ROLLING BACK $name to snapshot: $(basename "$snapshot_path")${NC}"
    echo "=========================================================="
    
    send_notification "Starting rollback for $name" "warning"
    
    # 1. Enable maintenance mode
    echo "   🔒 Enabling maintenance mode..."
    sudo -u "$user" wp --path="$path" maintenance-mode activate 2>/dev/null
    
    # 2. Restore files
    echo "   📁 Restoring files..."
    if [ -f "$snapshot_path/files.tar.gz" ]; then
        tar -xzf "$snapshot_path/files.tar.gz" -C "$path" 2>/dev/null
        echo "   ✅ Files restored"
    else
        echo "   ⚠️ No file backup found"
    fi
    
    # 3. Restore database
    echo "   🗄️ Restoring database..."
    local db_backup=$(ls "$snapshot_path"/db-*.sql.gz 2>/dev/null | head -1)
    if [ -f "$db_backup" ]; then
        DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_HOST=${DB_HOST:-localhost}
        
        if gunzip < "$db_backup" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null; then
            echo "   ✅ Database restored"
        else
            echo "   ${RED}❌ Database restore failed${NC}"
        fi
    else
        echo "   ⚠️ No database backup found"
    fi
    
    # 4. Disable maintenance mode and flush cache
    echo "   🔓 Disabling maintenance mode..."
    sudo -u "$user" wp --path="$path" maintenance-mode deactivate 2>/dev/null
    sudo -u "$user" wp --path="$path" cache flush 2>/dev/null
    
    # 5. Verify site
    echo "   🔍 Verifying site..."
    sleep 2
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$name" 2>/dev/null || echo "000")
    if [ "$http_code" = "000" ]; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
    fi
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        echo -e "${GREEN}✅ Rollback successful! Site is online (HTTP $http_code)${NC}"
        send_notification "Rollback successful for $name (HTTP $http_code)" "info"
    else
        echo -e "${RED}⚠️ Rollback completed but site returned HTTP $http_code${NC}"
        echo -e "${YELLOW}💡 Manual check recommended: http://$name${NC}"
        send_notification "Rollback completed for $name but HTTP $http_code - check manually" "error"
    fi
    
    echo -e "\n${GREEN}✅ Rollback operation completed${NC}"
}

# Clean up old snapshots
cleanup_snapshots() {
    local days=${1:-$RETENTION_ROLLBACK}
    
    echo -e "${CYAN}🧹 Cleaning snapshots older than $days days...${NC}"
    
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ -d "$ROLLBACK_DIR/$name" ]; then
            local deleted=$(find "$ROLLBACK_DIR/$name" -type d -mtime "+$days" -exec rm -rf {} \; -print 2>/dev/null | wc -l)
            if [ "$deleted" -gt 0 ]; then
                echo "   🗑️ $name: Deleted $deleted old snapshot(s)"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Main
case "${1:-}" in
    snapshot)
        if [ -z "$2" ]; then
            echo "Usage: wp-rollback snapshot <site-name|all>"
            echo "Examples:"
            echo "  wp-rollback snapshot all"
            echo "  wp-rollback snapshot mysite"
            exit 1
        fi
        
        if [ "$2" = "all" ]; then
            for site in "${SITES[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                create_snapshot "$name"
                echo ""
            done
        else
            create_snapshot "$2"
        fi
        ;;
    
    rollback)
        if [ -z "$2" ]; then
            echo "Usage: wp-rollback rollback <site-name> [snapshot-name]"
            exit 1
        fi
        perform_rollback "$2" "$3"
        ;;
    
    list)
        list_snapshots "$2"
        ;;
    
    clean)
        cleanup_snapshots "$2"
        ;;
    
    *)
        echo -e "${BLUE}🔄 WSMS ROLLBACK ENGINE v1.0${NC}"
        echo ""
        echo "Usage: wp-rollback {snapshot|rollback|list|clean} [site] [snapshot]"
        echo ""
        echo "Commands:"
        echo "  snapshot all              Create snapshots for all sites"
        echo "  snapshot <site>           Create snapshot for specific site"
        echo "  rollback <site>           Rollback to latest snapshot"
        echo "  rollback <site> <name>    Rollback to specific snapshot"
        echo "  list                      List all snapshots"
        echo "  list <site>               List snapshots for specific site"
        echo "  clean [days]              Clean old snapshots (default: $RETENTION_ROLLBACK days)"
        echo ""
        echo "Examples:"
        echo "  wp-rollback snapshot all"
        echo "  wp-rollback snapshot mysite"
        echo "  wp-rollback list mysite"
        echo "  wp-rollback rollback mysite"
        echo "  wp-rollback rollback mysite 20260115_143022"
        ;;
esac