#!/bin/bash
# =================================================================
# 🧠 SMART RETENTION & DISK SPACE MANAGER (PRO)
# Description: Heuristic cleanup engine that manages disk space 
#              while ensuring the "Last Known Good" backup is safe.
# =================================================================
source $HOME/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🧹 INITIATING SMART RETENTION ENGINE...${NC}"

# Logic: Check current disk usage
usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

apply_policy() {
    local dir=$1
    local days=$2
    echo -e "📂 Auditing: $(basename $dir)"

    if [ "$usage" -ge "$DISK_LIMIT" ]; then
        echo -e "   ${RED}⚠️ EMERGENCY MODE ($usage% usage): Keeping only 2 latest copies!${NC}"
        # Keeps 2 latest, deletes the rest regardless of age
        ls -t $dir/* 2>/dev/null | tail -n +3 | xargs -d '\n' rm -f 2>/dev/null
    else
        echo -e "   ✅ Standard Mode ($usage%): Policy $days days."
        # Standard retention but PROTECTS the last copy
        files_to_check=$(find $dir -type f -mtime +$days 2>/dev/null)
        for f in $files_to_check; do
            total_in_dir=$(ls -1 $dir | wc -l)
            if [ "$total_in_dir" -gt 1 ]; then
                rm -f "$f"
                echo -e "   ${YELLOW}🗑️ Purged expired:${NC} $(basename "$f")"
            else
                echo -e "   ${GREEN}🛡️ Protected:${NC} $(basename "$f") (Last available copy)"
            fi
        done
    fi
}

apply_policy "$HOME/backups-lite" "$RET_LITE"
apply_policy "$HOME/backups-full" "$RET_FULL"
apply_policy "$HOME/mysql-backups" "$RET_MYSQL"

echo -e "${GREEN}✅ RETENTION CYCLE COMPLETED.${NC}"