#!/bin/bash
# =================================================================
# 🧠 SMART RETENTION & DISK SPACE MANAGER
# Description: Automated backup rotation engine with proactive disk 
#              monitoring and "Last-Copy-Safe" preservation logic.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

echo -e "\033[0;36m🧹 BACKUP INFRASTRUCTURE: SMART RETENTION ENGINE\033[0m"
echo "=========================================================="

# --- CONFIGURATION ---
BACKUP_DIRS=(
    "$HOME/backups-lite"
    "$HOME/backups-full"
    "$HOME/backups-manual"
    "$HOME/mysql-backups"
)

# Retention Policy (Days)
declare -A RETENTION=(
    ["$HOME/backups-lite"]=14
    ["$HOME/backups-full"]=35
    ["$HOME/backups-manual"]=14
    ["$HOME/mysql-backups"]=7
)

# Thresholds
DISK_ALERT_THRESHOLD=80 # Trigger emergency purge if disk usage > 80%

# UI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- CORE HEURISTICS ---

# Logic: Get current disk utilization percentage
get_disk_utilization() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Logic: Emergency Purge
# Triggered when storage is critical. Keeps ONLY the 2 most recent copies 
# regardless of age to restore system stability.
trigger_emergency_purge() {
    local dir="$1"
    echo -e "${RED}⚠️  CRITICAL STORAGE ALERT: Executing Emergency Purge for $dir${NC}"
    
    # Identify the 2 latest files per site/pattern to prevent total data loss
    declare -A latest
    declare -A second_latest
    
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        # Regex to identify site-specific backup patterns
        if [[ "$file" =~ (backup-[a-z0-9-]+|mysql-[a-z0-9-]+) ]]; then
            pattern="${BASH_REMATCH[1]}"
            file_mtime=$(stat -c %Y "$file")
            
            if [ -z "${latest[$pattern]}" ] || [ "$file_mtime" -gt "${latest[$pattern]}" ]; then
                second_latest[$pattern]="${latest[$pattern]}"
                second_latest["${pattern}_name"]="${latest[${pattern}_name]}"
                latest[$pattern]="$file_mtime"
                latest["${pattern}_name"]="$file"
            elif [ -z "${second_latest[$pattern]}" ] || [ "$file_mtime" -gt "${second_latest[$pattern]}" ]; then
                second_latest[$pattern]="$file_mtime"
                second_latest["${pattern}_name"]="$file"
            fi
        fi
    done < <(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" \) 2>/dev/null)
    
    # Purge everything except the 2 identified "Safe Copies"
    for file in "$dir"/*; do
        [ ! -f "$file" ] && continue
        keep=0
        for p in "${!latest[@]}"; do
            if [[ ! "$p" =~ _name$ ]]; then
                if [ "$file" = "${latest[${p}_name]}" ] || [ "$file" = "${second_latest[${p}_name]}" ]; then
                    keep=1; break
                fi
            fi
        done
        if [ $keep -eq 0 ]; then
            rm -f "$file"
            echo -e "   ${RED}🗑️ Purged:${NC} $(basename "$file")"
        fi
    done
}

# Logic: Smart Retention (Standard Mode)
# Deletes old files based on policy but ALWAYS preserves the "Last Known Good" copy.
apply_retention_policy() {
    local dir="$1"
    local days="${RETENTION[$dir]}"
    local force_mode="$2" # If "true", skips user confirmation

    [ ! -d "$dir" ] && return 0
    local usage=$(get_disk_utilization)
    
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        trigger_emergency_purge "$dir"
        return $?
    fi

    echo -e "${CYAN}📂 Auditing Module: $(basename "$dir") (Policy: $days days)${NC}"

    # 1. Map the latest files for each site category
    declare -A latest_map
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ "$file" =~ (backup-[a-z0-9-]+|mysql-[a-z0-9-]+) ]]; then
            pattern="${BASH_REMATCH[1]}"
            mtime=$(stat -c %Y "$file")
            if [ -z "${latest_map[$pattern]}" ] || [ "${latest_map[$pattern]}" -lt "$mtime" ]; then
                latest_map[$pattern]="$mtime"
                latest_map["${pattern}_path"]="$file"
            fi
        fi
    done < <(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" \) 2>/dev/null)

    # 2. Identify and prune expired files
    local deleted=0
    local kept_by_safety=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        mtime=$(stat -c %Y "$file")
        age=$((( $(date +%s) - mtime ) / 86400))

        if [ "$age" -gt "$days" ]; then
            # Verify if this is the only copy left
            is_latest=0
            for p in "${!latest_map[@]}"; do
                if [[ ! "$p" =~ _path$ ]] && [ "$file" = "${latest_map[${p}_path]}" ]; then
                    is_latest=1; break
                fi
            done

            if [ "$is_latest" -eq 1 ]; then
                echo -e "     ${GREEN}🟢 PRESERVED:${NC} $(basename "$file") (${YELLOW}Last Copy Safety Rule${NC})"
                ((kept_by_safety++))
            else
                if [ "$force_mode" = "true" ]; then
                    rm -f "$file"
                    echo -e "     ${RED}🔴 DELETED:${NC} $(basename "$file") ($age days old)"
                    ((deleted++))
                else
                    echo -e "     ${YELLOW}⚠️  EXPIRED:${NC} $(basename "$file") ($age days old)"
                fi
            fi
        fi
    done < <(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" \) 2>/dev/null)

    return $deleted
}

# --- CLI INTERFACE ---

case "${1:-list}" in
    "list")
        echo "📊 BACKUP REPOSITORY OVERVIEW:"
        for dir in "${BACKUP_DIRS[@]}"; do
            [ ! -d "$dir" ] && continue
            count=$(find "$dir" -type f | wc -l)
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo -e "   📂 $(basename "$dir"): ${CYAN}$count files ($size)${NC}"
        done
        ;;
    "apply")
        echo -e "${YELLOW}🔄 Applying retention policies across all modules...${NC}"
        for dir in "${BACKUP_DIRS[@]}"; do apply_retention_policy "$dir" "true"; done
        echo -e "${GREEN}✅ Retention sync completed.${NC}"
        ;;
    *)
        echo "Usage: $0 {list|apply}"
        echo "  list  : Show storage utilization"
        echo "  apply : Execute pruning based on retention policy"
        ;;
esac