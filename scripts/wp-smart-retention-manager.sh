#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SMART RETENTION MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
exec >> "$LOG_FILE" 2>&1

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS v4.2${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n${YELLOW}📂 $(basename "$dir"):${NC}"
            find "$dir" -type f 2>/dev/null | while read -r file; do
                size=$(du -h "$file" 2>/dev/null | cut -f1)
                date_str=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1)
                echo "   📁 $(basename "$file") ($size, $date_str)"
            done
        fi
    done
}

show_size() {
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE v4.2${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        if [ -d "$dir" ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "   📂 $(basename "$dir"): $size ($count files)"
        fi
    done
    
    disk_usage=$(get_disk_usage)
    echo -e "\n   💿 Total disk usage: ${disk_usage}%"
    
    if [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "   ${RED}⚠️ WARNING: Disk usage above threshold ($DISK_ALERT_THRESHOLD%)!${NC}"
        echo -e "   ${YELLOW}💡 Run 'backup-emergency' to free space urgently${NC}"
    fi
}

show_dirs() {
    echo -e "${CYAN}📁 BACKUP DIRECTORY STRUCTURE${NC}"
    echo "=========================================================="
    ls -la "$HOME"/backups-* "$HOME"/mysql-backups 2>/dev/null
}

emergency_cleanup() {
    echo -e "${RED}🚨 EMERGENCY MODE: Keeping only 2 latest copies per site!${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n📂 Processing $(basename "$dir")..."
            
            for site in "${SITES[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                
                # Find and keep only 2 latest files per site
                files=$(find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r)
                count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
                
                if [ "$count" -gt 2 ]; then
                    echo "$files" | tail -n +3 | xargs rm -f 2>/dev/null
                    deleted=$((count - 2))
                    echo "   🗑️ $name: Kept 2 latest, deleted $deleted"
                fi
            done
        fi
    done
    
    echo -e "\n${GREEN}✅ EMERGENCY CLEANUP COMPLETE${NC}"
}

force_clean() {
    usage=$(get_disk_usage)
    
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "${YELLOW}⚠️ Disk usage at ${usage}% - triggering emergency mode${NC}"
        emergency_cleanup
    else
        echo -e "${GREEN}✅ Standard cleanup: Deleting files older than retention period${NC}"
        echo "=========================================================="
        
        find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null
        echo "   🗑️ Lite backups: Deleted files older than $RETENTION_LITE days"
        
        find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null
        echo "   🗑️ Full backups: Deleted files older than $RETENTION_FULL days"
        
        find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
        echo "   🗑️ MySQL backups: Deleted files older than $RETENTION_MYSQL days"
        
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null
        echo "   🗑️ Rollback snapshots: Deleted older than $RETENTION_ROLLBACK days"
    fi
}

interactive_clean() {
    echo -e "${CYAN}🧹 INTERACTIVE CLEANUP MODE${NC}"
    echo "=========================================================="
    show_size
    echo ""
    echo -e "${YELLOW}What would you like to clean?${NC}"
    echo "   1) Lite backups (older than $RETENTION_LITE days)"
    echo "   2) Full backups (older than $RETENTION_FULL days)"
    echo "   3) MySQL backups (older than $RETENTION_MYSQL days)"
    echo "   4) Rollback snapshots (older than $RETENTION_ROLLBACK days)"
    echo "   5) ALL (standard retention)"
    echo "   6) EMERGENCY (keep only 2 latest)"
    echo "   0) Cancel"
    echo ""
    read -p "Enter choice [0-6]: " choice
    
    case $choice in
        1) find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null && echo "✅ Lite backups cleaned" ;;
        2) find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null && echo "✅ Full backups cleaned" ;;
        3) find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null && echo "✅ MySQL backups cleaned" ;;
        4) find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null && echo "✅ Rollback snapshots cleaned" ;;
        5) force_clean ;;
        6) emergency_cleanup ;;
        0) echo "Cancelled." ;;
        *) echo "Invalid choice." ;;
    esac
}

case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    dirs|d) show_dirs ;;
    clean|c) interactive_clean ;;
    force-clean|force|f) force_clean ;;
    emergency|e) emergency_cleanup ;;
    *) 
        echo "Usage: $0 {list|size|dirs|clean|force-clean|emergency}"
        echo ""
        echo "Commands:"
        echo "  list, l        - List all backups with details"
        echo "  size, s        - Show storage usage per directory"
        echo "  dirs, d        - Show directory structure"
        echo "  clean, c       - Interactive cleanup"
        echo "  force-clean, f - Automatic cleanup based on retention"
        echo "  emergency, e   - Keep only 2 latest copies per site"
        ;;
esac