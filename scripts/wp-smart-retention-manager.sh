#!/bin/bash
# =================================================================
# 🧠 SMART RETENTION MANAGER - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

BACKUP_DIRS=("$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MANUAL_DIR" "$BACKUP_MYSQL_DIR")
declare -A RETENTION=(
    ["$BACKUP_LITE_DIR"]=$RETENTION_LITE
    ["$BACKUP_FULL_DIR"]=$RETENTION_FULL
    ["$BACKUP_MANUAL_DIR"]=$RETENTION_LITE
    ["$BACKUP_MYSQL_DIR"]=$RETENTION_MYSQL
)

apply_retention() {
    local dir="$1"
    local days="${RETENTION[$dir]}"
    [ ! -d "$dir" ] && return
    
    echo -e "${CYAN}📂 Auditing: $(basename "$dir") (Policy: $days days)${NC}"
    
    # Find latest file per pattern
    declare -A latest
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ "$file" =~ (backup-[a-z0-9-]+|mysql-[a-z0-9-]+) ]]; then
            pattern="${BASH_REMATCH[1]}"
            mtime=$(stat -c %Y "$file")
            if [ -z "${latest[$pattern]}" ] || [ "$mtime" -gt "${latest[$pattern]}" ]; then
                latest[$pattern]="$mtime"
                latest["${pattern}_path"]="$file"
            fi
        fi
    done < <(find "$dir" -type f 2>/dev/null)
    
    # Delete expired files (keep latest per pattern)
    local deleted=0
    for file in "$dir"/*; do
        [ ! -f "$file" ] && continue
        mtime=$(stat -c %Y "$file")
        age=$((( $(date +%s) - mtime ) / 86400))
        
        if [ "$age" -gt "$days" ]; then
            # Check if this is the latest for its pattern
            is_latest=0
            for p in "${!latest[@]}"; do
                [[ "$p" =~ _path$ ]] && continue
                if [ "$file" = "${latest[${p}_path]}" ]; then
                    is_latest=1; break
                fi
            done
            
            if [ "$is_latest" -eq 0 ]; then
                rm -f "$file"
                ((deleted++))
            fi
        fi
    done
    
    echo -e "   🗑️  Deleted: $deleted files"
}

case "${1:-list}" in
    "list")
        echo "📊 BACKUP REPOSITORY OVERVIEW:"
        for dir in "${BACKUP_DIRS[@]}"; do
            [ -d "$dir" ] && echo "   📂 $(basename "$dir"): $(find "$dir" -type f | wc -l) files ($(du -sh "$dir" 2>/dev/null | cut -f1))"
        done
        ;;
    "apply")
        echo -e "${YELLOW}🔄 Applying retention policies...${NC}"
        for dir in "${BACKUP_DIRS[@]}"; do apply_retention "$dir"; done
        echo -e "${GREEN}✅ Retention completed${NC}"
        ;;
esac
