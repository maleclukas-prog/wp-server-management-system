#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SYSTEM CLEANUP SCRIPT
# Description: Cleans old logs, backups, and temporary files
# Usage: ./wsms-clean.sh [--force]
# =================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.2 - SYSTEM CLEANUP                       ${NC}"
echo -e "${CYAN}==========================================================${NC}"

cd ~ || exit 1

# ============================================
# 1. OLD LOGS IN HOME DIRECTORY
# ============================================
echo -e "\n${YELLOW}📝 Cleaning old logs from home directory...${NC}"

OLD_LOGS=(
    "aliases.fish"
    "backup-cron.log"
    "backup_sync.log"
    "clamav-full.log"
    "clamav-scan.log"
    "clamav-update.log"
    "update-cron.log"
    "nas-sync.log"
    "retention.log"
    "security-scan.log"
    "updates.log"
    "install_log.txt"
    "crontab_backup.txt"
)

deleted_logs=0
for file in "${OLD_LOGS[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "   🗑️  $file"
        ((deleted_logs++))
    fi
done

if [ $deleted_logs -eq 0 ]; then
    echo "   ✅ No old logs found"
else
    echo -e "   ${GREEN}✅ Deleted $deleted_logs old log file(s)${NC}"
fi

# ============================================
# 2. EXCESSIVE .bashrc BACKUPS
# ============================================
echo -e "\n${YELLOW}💻 Cleaning excessive .bashrc backups...${NC}"

bashrc_backups=$(ls -t .bashrc.backup.* 2>/dev/null)
bashrc_count=$(echo "$bashrc_backups" | grep -c . 2>/dev/null || echo 0)

if [ "$bashrc_count" -gt 1 ]; then
    echo "$bashrc_backups" | tail -n +2 | while read -r file; do
        [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"
    done
    echo -e "   ${GREEN}✅ Kept newest .bashrc.backup, deleted $((bashrc_count - 1)) old copies${NC}"
else
    echo "   ✅ No excessive .bashrc backups"
fi

# ============================================
# 3. EXCESSIVE CRONTAB BACKUPS
# ============================================
echo -e "\n${YELLOW}⏰ Cleaning excessive crontab backups...${NC}"

crontab_backups=$(ls -t crontab*.txt 2>/dev/null)
crontab_count=$(echo "$crontab_backups" | grep -c . 2>/dev/null || echo 0)

if [ "$crontab_count" -gt 1 ]; then
    echo "$crontab_backups" | tail -n +2 | while read -r file; do
        [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"
    done
    echo -e "   ${GREEN}✅ Kept newest crontab backup, deleted $((crontab_count - 1)) old copies${NC}"
else
    echo "   ✅ No excessive crontab backups"
fi

# ============================================
# 4. OLD SCRIPTS BACKUP DIRECTORIES
# ============================================
echo -e "\n${YELLOW}📂 Cleaning old scripts backup directories...${NC}"

OLD_DIRS=(
    "scripts-backup-old"
    "scripts_copy_"*
    "scripts-backup"
)

deleted_dirs=0
for dir in "${OLD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "   🗑️  $dir/"
        ((deleted_dirs++))
    fi
done

if [ $deleted_dirs -eq 0 ]; then
    echo "   ✅ No old script backup directories found"
else
    echo -e "   ${GREEN}✅ Deleted $deleted_dirs old directories${NC}"
fi

# ============================================
# 5. TEMPORARY AND MISC FILES
# ============================================
echo -e "\n${YELLOW}📦 Cleaning temporary files...${NC}"

TEMP_FILES=(
    "*.sql"
    "*.tmp"
    "*.temp"
    "*_BACKUP_*"
    "*_backup_*"
    ".bashrc.swp"
    ".config/fish/config.fish.swp"
)

deleted_temp=0
for pattern in "${TEMP_FILES[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "   🗑️  $file"
            ((deleted_temp++))
        fi
    done 2>/dev/null
done

if [ $deleted_temp -eq 0 ]; then
    echo "   ✅ No temporary files found"
else
    echo -e "   ${GREEN}✅ Deleted $deleted_temp temporary file(s)${NC}"
fi

# ============================================
# 6. OLD INSTALLER FILES (OPTIONAL)
# ============================================
echo -e "\n${YELLOW}📦 Checking for old installer files...${NC}"

OLD_INSTALLERS=(
    "install_wsms.sh"
    "install_wsms.fish"
    "wsms-cleanup.fish"
    "wsms-uninstall.fish"
)

deleted_installers=0
for file in "${OLD_INSTALLERS[@]}"; do
    if [ -f "$file" ]; then
        if [ "$FORCE_MODE" = true ]; then
            rm -f "$file"
            echo "   🗑️  $file"
            ((deleted_installers++))
        else
            echo -e "   ${YELLOW}⚠️  $file (use --force to remove)${NC}"
        fi
    fi
done

if [ $deleted_installers -gt 0 ]; then
    echo -e "   ${GREEN}✅ Deleted $deleted_installers old installer file(s)${NC}"
fi

# ============================================
# 7. EMPTY LOG FILES (OPTIONAL)
# ============================================
echo -e "\n${YELLOW}📝 Checking for empty log files...${NC}"

if [ -d "$HOME/logs/wsms" ]; then
    empty_logs=$(find "$HOME/logs/wsms" -name "*.log" -type f -empty 2>/dev/null)
    if [ -n "$empty_logs" ]; then
        if [ "$FORCE_MODE" = true ]; then
            echo "$empty_logs" | while read -r file; do
                rm -f "$file"
                echo "   🗑️  $file (empty)"
            done
        else
            echo -e "   ${YELLOW}⚠️  Empty log files found (use --force to remove)${NC}"
            echo "$empty_logs" | head -5 | sed 's/^/      /'
        fi
    else
        echo "   ✅ No empty log files"
    fi
fi

# ============================================
# SUMMARY
# ============================================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ CLEANUP COMPLETE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""

echo -e "${CYAN}📁 Remaining files in ~/ (non-hidden):${NC}"
ls -la ~ 2>/dev/null | grep -E "^-" | grep -v "^\." | awk '{print "   " $9}' | head -20

echo ""
echo -e "${YELLOW}💡 Tip: Use --force to remove old installer files and empty logs${NC}"