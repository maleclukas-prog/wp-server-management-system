#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🧠 SMART RETENTION & DISK SPACE MANAGER (PRO)
# Description: Unified backup management with emergency mode
# Usage: wp-smart-retention-manager.sh [list|size|clean|force-clean|emergency]
# =================================================================

source $HOME/scripts/wsms-config.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# FUNCTION: List backups with details (age in days)
# ============================================
list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS${NC}"
    echo "=========================================================="
    
    local total_count=0
    local total_size=0
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "\n${YELLOW}📂 $(basename "$dir"):${NC}"
            
            # Find and sort files by date (newest first)
            local files=$(find "$dir" -maxdepth 1 -type f \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null | sort)
            
            if [ -z "$files" ]; then
                echo "   (empty)"
                continue
            fi
            
            while IFS= read -r file; do
                if [ -n "$file" ] && [ -f "$file" ]; then
                    local size=$(du -h "$file" 2>/dev/null | cut -f1)
                    local date_str=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
                    local file_mtime=$(stat -c %Y "$file" 2>/dev/null)
                    local current_time=$(date +%s)
                    local age_days=$(((current_time - file_mtime) / 86400))
                    local size_bytes=$(stat -c %s "$file" 2>/dev/null || echo "0")
                    
                    # Color based on age
                    if [ $age_days -gt 30 ]; then
                        local age_color=$RED
                    elif [ $age_days -gt 14 ]; then
                        local age_color=$YELLOW
                    else
                        local age_color=$GREEN
                    fi
                    
                    printf "   📁 %-50s %8s  %s  ${age_color}%3d dni${NC}\n" \
                        "$(basename "$file")" "$size" "$date_str" "$age_days"
                    
                    total_count=$((total_count + 1))
                    total_size=$((total_size + size_bytes))
                fi
            done <<< "$files"
        fi
    done
    
    # Summary
    echo -e "\n${CYAN}==========================================================${NC}"
    echo -e "${CYAN}📈 TOTAL SUMMARY:${NC}"
    echo "   📄 Files: $total_count"
    
    if [ $total_size -gt 1073741824 ]; then
        local human_size=$(echo "scale=2; $total_size/1073741824" | bc 2>/dev/null || echo "0")
        echo "   💾 Total size: ${human_size} GB"
    elif [ $total_size -gt 1048576 ]; then
        local human_size=$(echo "scale=2; $total_size/1048576" | bc 2>/dev/null || echo "0")
        echo "   💾 Total size: ${human_size} MB"
    else
        local human_size=$(echo "scale=2; $total_size/1024" | bc 2>/dev/null || echo "0")
        echo "   💾 Total size: ${human_size} KB"
    fi
}

# ============================================
# FUNCTION: Show storage usage by directory
# ============================================
show_size() {
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE${NC}"
    echo "=========================================================="
    
    local total_size=0
    local total_files=0
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            local count=$(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null | wc -l)
            local size_bytes=$(du -sb "$dir" 2>/dev/null | cut -f1)
            
            printf "   📂 %-20s %10s  (%4d files)\n" "$(basename "$dir")" "$size" "$count"
            
            total_size=$((total_size + size_bytes))
            total_files=$((total_files + count))
        else
            echo "   ❌ $(basename "$dir"): (directory doesn't exist)"
        fi
    done
    
    echo -e "\n${CYAN}==========================================================${NC}"
    
    if [ $total_size -gt 1073741824 ]; then
        local human_size=$(echo "scale=2; $total_size/1073741824" | bc 2>/dev/null || echo "0")
        echo -e "${CYAN}📈 TOTAL:${NC} $total_files files, ${human_size} GB"
    elif [ $total_size -gt 1048576 ]; then
        local human_size=$(echo "scale=2; $total_size/1048576" | bc 2>/dev/null || echo "0")
        echo -e "${CYAN}📈 TOTAL:${NC} $total_files files, ${human_size} MB"
    else
        local human_size=$(echo "scale=2; $total_size/1024" | bc 2>/dev/null || echo "0")
        echo -e "${CYAN}📈 TOTAL:${NC} $total_files files, ${human_size} KB"
    fi
}

# ============================================
# FUNCTION: Clean with confirmation (interactive)
# ============================================
clean_with_confirm() {
    echo -e "${CYAN}🧹 SMART CLEANUP (with confirmation)${NC}"
    echo "=========================================================="
    
    local current_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo -e "   Current disk usage: ${YELLOW}$current_usage%${NC}"
    
    if [ $current_usage -ge $DISK_ALERT_THRESHOLD ]; then
        echo -e "   ${RED}⚠️ WARNING: Disk usage exceeds ${DISK_ALERT_THRESHOLD}%!${NC}"
        echo -e "   ${RED}Emergency mode will keep only 2 latest copies per category!${NC}"
        echo ""
        read -p "   Continue with emergency cleanup? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "   ❌ Cancelled"
            return 0
        fi
        emergency_cleanup
        return $?
    fi
    
    local total_deleted=0
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "\n${YELLOW}📂 $(basename "$dir"):${NC}"
            
            local days=${RETENTION_MAP[$dir]}
            local files_to_delete=$(find "$dir" -type f -mtime +$days \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null)
            local delete_count=$(echo "$files_to_delete" | grep -c -v "^$")
            
            if [ $delete_count -eq 0 ]; then
                echo "   ✅ No old files to delete"
                continue
            fi
            
            echo "   Found $delete_count files older than $days days:"
            while IFS= read -r file; do
                if [ -n "$file" ] && [ -f "$file" ]; then
                    local size=$(du -h "$file" 2>/dev/null | cut -f1)
                    local date_str=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
                    echo "      📁 $(basename "$file") ($size, $date_str)"
                fi
            done <<< "$files_to_delete"
            
            echo ""
            read -p "   Delete these $delete_count files? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                while IFS= read -r file; do
                    if [ -n "$file" ] && [ -f "$file" ]; then
                        rm -f "$file"
                        echo "      ✅ Deleted: $(basename "$file")"
                        total_deleted=$((total_deleted + 1))
                    fi
                done <<< "$files_to_delete"
            else
                echo "      Skipped"
            fi
        fi
    done
    
    echo -e "\n${GREEN}✅ Deleted $total_deleted files${NC}"
}

# ============================================
# FUNCTION: Force clean (no confirmation, for cron)
# ============================================
force_clean() {
    local current_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo -e "${CYAN}🧹 FORCE CLEANUP (no confirmation)${NC}"
    echo "=========================================================="
    echo -e "   Current disk usage: ${YELLOW}$current_usage%${NC}"
    
    if [ $current_usage -ge $DISK_ALERT_THRESHOLD ]; then
        echo -e "   ${RED}⚠️ DISK USAGE: $current_usage% - ACTIVATING EMERGENCY MODE!${NC}"
        emergency_cleanup
        return $?
    fi
    
    local total_deleted=0
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            local days=${RETENTION_MAP[$dir]}
            local files_to_delete=$(find "$dir" -type f -mtime +$days \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null)
            
            while IFS= read -r file; do
                if [ -n "$file" ] && [ -f "$file" ]; then
                    # Protect last copy
                    local total_in_dir=$(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null | wc -l)
                    if [ $total_in_dir -gt 1 ]; then
                        rm -f "$file"
                        echo "   🗑️ Deleted: $(basename "$file")"
                        total_deleted=$((total_deleted + 1))
                    else
                        echo "   🛡️ Protected: $(basename "$file") (last copy)"
                    fi
                fi
            done <<< "$files_to_delete"
        fi
    done
    
    echo -e "\n${GREEN}✅ Deleted $total_deleted files${NC}"
}

# ============================================
# FUNCTION: Emergency cleanup (keeps only 2 latest copies)
# ============================================
emergency_cleanup() {
    local current_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo -e "${RED}🚨 EMERGENCY CLEANUP MODE${NC}"
    echo "=========================================================="
    echo -e "   Disk usage: ${RED}$current_usage%${NC} (exceeds ${DISK_ALERT_THRESHOLD}% threshold)"
    echo -e "   Policy: Keeping only ${YELLOW}2 latest copies${NC} per category"
    echo ""
    
    local total_deleted=0
    local total_kept=0
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${YELLOW}📂 $(basename "$dir"):${NC}"
            
            # Group files by pattern (site)
            declare -A pattern_files
            
            while IFS= read -r file; do
                if [ -n "$file" ] && [ -f "$file" ]; then
                    # Extract pattern: backup-lite-uszatek, backup-full-photo, mysql-uszatek, db-uszatek
                    if [[ "$file" =~ (backup-lite-([a-z]+)|backup-full-([a-z]+)|mysql-([a-z]+)|db-([a-z]+)) ]]; then
                        local pattern=""
                        if [ -n "${BASH_REMATCH[2]}" ]; then pattern="lite-${BASH_REMATCH[2]}"
                        elif [ -n "${BASH_REMATCH[3]}" ]; then pattern="full-${BASH_REMATCH[3]}"
                        elif [ -n "${BASH_REMATCH[4]}" ]; then pattern="${BASH_REMATCH[4]}"
                        elif [ -n "${BASH_REMATCH[5]}" ]; then pattern="${BASH_REMATCH[5]}"
                        else pattern="other"
                        fi
                        pattern_files["$pattern"]+="$file"$'\n'
                    fi
                fi
            done < <(find "$dir" -maxdepth 1 -type f \( -name "*backup*" -o -name "mysql-*" -o -name "db-*" \) 2>/dev/null | sort)
            
            for pattern in "${!pattern_files[@]}"; do
                local files="${pattern_files[$pattern]}"
                # Sort by date (newest first)
                local sorted_files=$(echo "$files" | while read -r f; do
                    [ -n "$f" ] && echo "$(stat -c %Y "$f" 2>/dev/null):$f"
                done | sort -rn | cut -d':' -f2)
                
                local counter=0
                while IFS= read -r file; do
                    [ -z "$file" ] && continue
                    counter=$((counter + 1))
                    if [ $counter -le 2 ]; then
                        echo "   🟢 KEEP: $(basename "$file")"
                        total_kept=$((total_kept + 1))
                    else
                        echo "   🔴 DELETE: $(basename "$file")"
                        rm -f "$file"
                        total_deleted=$((total_deleted + 1))
                    fi
                done <<< "$sorted_files"
            done
            echo ""
        fi
    done
    
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${GREEN}✅ EMERGENCY CLEANUP COMPLETED${NC}"
    echo -e "   Kept: $total_kept files (2 per category)"
    echo -e "   Deleted: $total_deleted files"
}

# ============================================
# FUNCTION: Show directory structure
# ============================================
show_dirs() {
    echo -e "${CYAN}📁 BACKUP DIRECTORY STRUCTURE${NC}"
    echo "=========================================================="
    
    for dir in "${BACKUP_DIRS[@]}"; do
        echo -e "\n${YELLOW}📂 $dir:${NC}"
        if [ -d "$dir" ]; then
            ls -la "$dir" 2>/dev/null | head -15 | sed 's/^/   /'
            local count=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "   Total files: $count"
        else
            echo "   ❌ Directory does not exist"
        fi
    done
}

# ============================================
# MAIN
# ============================================
case "${1:-}" in
    list|l)
        list_backups
        ;;
    size|s)
        show_size
        ;;
    clean|c)
        clean_with_confirm
        ;;
    force-clean|force|f)
        force_clean
        ;;
    emergency|emergency-clean|e)
        emergency_cleanup
        ;;
    dirs|d)
        show_dirs
        ;;
    *)
        echo "❌ Usage: $0 {list|size|clean|force-clean|emergency|dirs}"
        echo ""
        echo "  list           - List all backups with details (size, date, age in days)"
        echo "  size           - Show storage usage per directory"
        echo "  clean          - Cleanup with confirmation (interactive)"
        echo "  force-clean    - Cleanup without confirmation (for cron)"
        echo "  emergency      - Emergency: keep only 2 latest copies per site"
        echo "  dirs           - Show directory structure"
        echo ""
        echo "Examples:"
        echo "  $0 list        # Show all backups"
        echo "  $0 clean       # Interactive cleanup"
        echo "  $0 emergency   # Emergency cleanup when disk is full"
        exit 1
        ;;
esac