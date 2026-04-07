#!/bin/bash
# =================================================================
# 🎯 INTERACTIVE WORDPRESS BACKUP MANAGER
# Description: A menu-driven utility for manual on-demand backups. 
#              Supports Lite (Assets) and Full (Snapshots) modes 
#              with integrated database optimization.
# Author: [Your Name]
# =================================================================

# UI Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🛠️  ON-DEMAND SITE BACKUP ENGINE${NC}"
echo "=========================================="

# Infrastructure Mapping
# Format: "site_id:path_to_public_html:system_user"
sites=(
    "production-site-1:/var/www/site1/public_html:user1"
    "staging-site-2:/var/www/site2/public_html:user2"
    "dev-site-3:/var/www/site3/public_html:user3"
)

# Core Logic: Filesystem Archiving
archive_files() {
    local name="$1"
    local path="$2"
    local type="$3"
    local timestamp="$4"

    # Define directory and naming based on backup type
    if [[ "$type" == "full" ]]; then
        BACKUP_DIR="$HOME/backups-full"
        FILES_FILE="$BACKUP_DIR/backup-full-$name-complete-$timestamp.tar.gz"
        EXCLUDES=('--exclude=wp-content/cache' '--exclude=wp-content/upgrade' '--exclude=*.log' '--exclude=cache/*' '--exclude=tmp/*')
        LABEL="Complete Filesystem Snapshot"
    else
        BACKUP_DIR="$HOME/backups-manual"
        FILES_FILE="$BACKUP_DIR/backup-lite-$name-assets-$timestamp.tar.gz"
        EXCLUDES=()
        LABEL="Essential Assets Only"
    fi

    mkdir -p "$BACKUP_DIR"
    echo -e "   📦 Archiving: $LABEL..."

    # Execution using sudo to ensure data integrity across permissions
    if [[ "$type" == "full" ]]; then
        # Full backup logic
        sudo tar -czf "$FILES_FILE" -C "$path" "${EXCLUDES[@]}" . 2> /dev/null
    else
        # Lite/Manual backup logic (selective folders)
        sudo tar -czf "$FILES_FILE" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2> /dev/null
    fi

    if [ -f "$FILES_FILE" ]; then
        SIZE=$(du -h "$FILES_FILE" | cut -f1)
        echo -e "   ✅ Success: $FILES_FILE (${GREEN}$SIZE${NC})"
        return 0
    else
        echo -e "   ❌ ${RED}Error: Backup file was not generated.${NC}"
        return 1
    fi
}

# Core Logic: Backup Orchestrator
execute_backup() {
    local name="$1"
    local path="$2"
    local user="$3"
    local type="$4"

    echo -e "\n${YELLOW}🌐 Processing Instance: $name ($type)${NC}"
    [ ! -d "$path" ] && { echo -e "   ❌ ${RED}Path not found: $path${NC}"; return 1; }

    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local MYSQL_ENGINE="$HOME/scripts/mysql-backup-manager.sh"

    # Optimization Logic (Exclusive to Full Backups)
    if [ "$type" = "full" ]; then
        echo "   📊 Running pre-backup maintenance (wp-cli)..."
        sudo -u "$user" wp --path="$path" transient delete --expired --quiet 2>/dev/null
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        sudo -u "$user" wp --path="$path" db optimize --quiet 2>/dev/null
        sleep 2
    fi

    # Database Export
    echo "   🗃️ Triggering MySQL Snapshot Engine..."
    if bash "$MYSQL_ENGINE" "$name"; then
        echo -e "   ✅ Database snapshot: ${GREEN}Verified${NC}"
    else
        echo -e "   ⚠️  ${RED}Database backup failed. Site might be offline.${NC}"
        return 1
    fi

    # Filesystem Archive
    if archive_files "$name" "$path" "$type" "$TIMESTAMP"; then
        echo -e "✅ ${GREEN}Operational success: $name backup completed.${NC}"
        return 0
    else
        return 1
    fi
}

# --- USER INTERFACE (MENU SYSTEM) ---

show_menu() {
    echo -e "\n${CYAN}🎯 SELECT TARGET SITE:${NC}"
    for i in "${!sites[@]}"; do
        IFS=':' read -r name path user <<< "${sites[$i]}"
        echo -e "  $((i + 1))) $name"
    done
    echo "  a) Backup ALL sites"
    echo "  q) Exit tool"
    echo ""
    read -r -p "📝 Selection [1-3, a, q]: " choice
}

while true; do
    show_menu

    case $choice in
        [1-9]) # Dynamically handle based on site count
            index=$((choice - 1))
            [ -z "${sites[$index]}" ] && { echo "Invalid selection."; continue; }
            
            IFS=':' read -r name path user <<< "${sites[$index]}"
            echo -e "\n${YELLOW}📦 SELECT BACKUP DEPTH for $name:${NC}"
            echo "  1) Lite (Database + Themes/Plugins/Uploads)"
            echo "  2) Full (Database + Complete Web Root)"
            read -r -p "📝 Type [1-2]: " b_type

            case $b_type in
                1) execute_backup "$name" "$path" "$user" "lite" ;;
                2) execute_backup "$name" "$path" "$user" "full" ;;
                *) echo "Operation cancelled: Invalid type." ;;
            esac
            ;;

        "a" | "A")
            echo -e "\n${YELLOW}📦 SELECT BACKUP DEPTH for ALL SITES:${NC}"
            echo "  1) Lite"
            echo "  2) Full"
            read -r -p "📝 Type [1-2]: " b_type
            
            [[ "$b_type" != "1" && "$b_type" != "2" ]] && { echo "Invalid choice."; continue; }
            
            for site in "${sites[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                type="lite"; [ "$b_type" = "2" ] && type="full"
                execute_backup "$name" "$path" "$user" "$type"
            done
            ;;

        "q" | "Q")
            echo -e "${GREEN}Safe exit. Goodbye!${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
done