#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🎯 INTERACTIVE BACKUP TOOL - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🛠️  ON-DEMAND BACKUP ENGINE${NC}"
echo "=========================================="

backup_site() {
    local name="$1"
    local path="$2"
    local user="$3"
    local type="$4"
    
    echo -e "\n${YELLOW}🌐 Backing up: $name ($type)${NC}"
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Database
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    
    # Filesystem
    if [ "$type" = "full" ]; then
        ARCHIVE="$BACKUP_FULL_DIR/backup-full-$name-$TIMESTAMP.tar.gz"
        sudo tar -czf "$ARCHIVE" -C "$path" --exclude="wp-content/cache" . 2>/dev/null
    else
        ARCHIVE="$BACKUP_MANUAL_DIR/backup-lite-$name-$TIMESTAMP.tar.gz"
        sudo tar -czf "$ARCHIVE" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    fi
    
    [ -f "$ARCHIVE" ] && echo -e "   ✅ ${GREEN}Success${NC}" || echo -e "   ❌ ${RED}Failed${NC}"
}

while true; do
    echo -e "\n${CYAN}🎯 SELECT SITE:${NC}"
    for i in "${!SITES[@]}"; do
        IFS=':' read -r name path user <<< "${SITES[$i]}"
        echo "  $((i+1))) $name"
    done
    echo "  a) All sites"
    echo "  q) Exit"
    read -p "Choice: " choice
    
    case $choice in
        q|Q) echo -e "${GREEN}Goodbye!${NC}"; break ;;
        a|A)
            read -p "Backup type (lite/full): " btype
            for site in "${SITES[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                backup_site "$name" "$path" "$user" "$btype"
            done
            ;;
        [0-9]*)
            idx=$((choice-1))
            [ -z "${SITES[$idx]}" ] && continue
            IFS=':' read -r name path user <<< "${SITES[$idx]}"
            read -p "Backup type (lite/full): " btype
            backup_site "$name" "$path" "$user" "$btype"
            ;;
    esac
done
