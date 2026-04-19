#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - INTERACTIVE BACKUP TOOL
# =================================================================

source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${BLUE}🎯 WSMS INTERACTIVE BACKUP ENGINE v4.2${NC}"
echo "=========================================================="

echo -e "\n${CYAN}Select a site to backup:${NC}"
echo "   0) All sites"
i=1
declare -A site_map
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   $i) $name"
    site_map[$i]="$site"
    ((i++))
done
echo "   q) Quit"

echo ""
read -p "Enter choice: " choice

if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
    echo "Goodbye!"
    exit 0
fi

echo -e "\n${CYAN}Select backup type:${NC}"
echo "   1) Lite backup (themes, plugins, uploads, config)"
echo "   2) Full backup (complete site)"
echo "   3) Database only"
echo "   4) Rollback snapshot"
echo "   q) Quit"

echo ""
read -p "Enter choice: " backup_type

case $backup_type in
    1)
        if [ "$choice" = "0" ]; then
            bash "$SCRIPT_DIR/wp-essential-assets-backup.sh"
        else
            IFS=':' read -r name path user <<< "${site_map[$choice]}"
            echo "Running Lite Backup for $name..."
            bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" "$name"
        fi
        ;;
    2)
        if [ "$choice" = "0" ]; then
            bash "$SCRIPT_DIR/wp-full-recovery-backup.sh"
        else
            IFS=':' read -r name path user <<< "${site_map[$choice]}"
            echo "Running Full Backup for $name..."
            bash "$SCRIPT_DIR/wp-full-recovery-backup.sh" "$name"
        fi
        ;;
    3)
        if [ "$choice" = "0" ]; then
            bash "$SCRIPT_DIR/mysql-backup-manager.sh" all
        else
            IFS=':' read -r name path user <<< "${site_map[$choice]}"
            echo "Running Database Backup for $name..."
            bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"
        fi
        ;;
    4)
        if [ "$choice" = "0" ]; then
            bash "$SCRIPT_DIR/wp-rollback.sh" snapshot all
        else
            IFS=':' read -r name path user <<< "${site_map[$choice]}"
            echo "Creating rollback snapshot for $name..."
            bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name"
        fi
        ;;
    q|Q) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice" ;;
esac

echo -e "\n${GREEN}✅ Backup operation completed!${NC}"