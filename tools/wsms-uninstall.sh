#!/bin/bash
# =================================================================
# 🧹 WSMS PRO v4.3 - UNIVERSAL UNINSTALLER
# Version: 1.1 | Works in any shell
# Description: Completely removes WSMS PRO from the system
# Usage: ./wsms-uninstall.sh [--force] [--dry-run]
# =================================================================

FORCE_MODE=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --force | -f) FORCE_MODE=true ;;
        --dry-run | -n) DRY_RUN=true ;;
    esac
done

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

WSMS_BASH_START="# >>> WSMS PRO v4.3 BASH >>>"
WSMS_BASH_END="# <<< WSMS PRO v4.3 BASH <<<"
WSMS_FISH_START="# >>> WSMS PRO v4.3 FISH >>>"
WSMS_FISH_END="# <<< WSMS PRO v4.3 FISH <<<"
WSMS_HOSTS_START="# >>> WSMS LOCAL HOSTS >>>"
WSMS_HOSTS_END="# <<< WSMS LOCAL HOSTS <<<"

# Wildcard patterns — match any WSMS PRO version (v4.0, v4.1, v4.2, v4.3 ...)
WSMS_BASH_PATTERN_START='# >>> WSMS PRO v'
WSMS_FISH_PATTERN_START='# >>> WSMS PRO v'

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] $*"
        return 0
    fi
    "$@"
}

sed_in_place() {
    # macOS/BSD sed uses: sed -i '' ; GNU sed uses: sed -i
    if sed --version > /dev/null 2>&1; then
        sed -i "$1" "$2"
    else
        sed -i '' "$1" "$2"
    fi
}

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.3 - UNIVERSAL UNINSTALLER                 ${NC}"
echo -e "${CYAN}   Completely removes WSMS from the system                  ${NC}"
echo -e "${CYAN}==========================================================${NC}"

CURRENT_SHELL=$(basename "$SHELL")
echo -e "${YELLOW}📍 Detected shell: $CURRENT_SHELL${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🧪 DRY-RUN MODE: no changes will be made${NC}"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# 1. CLEAN FISH CONFIG
# ============================================
echo -e "\n${YELLOW}🐟 Cleaning Fish configuration...${NC}"
if [ -f "$HOME/.config/fish/config.fish" ]; then
    run_cmd cp "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.backup.$TIMESTAMP"
    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] Remove marker block: $WSMS_FISH_START ... $WSMS_FISH_END"
        echo "   [DRY-RUN] Remove any older WSMS PRO vX.Y FISH blocks"
    else
        # Remove current v4.3 block
        sed_in_place "/${WSMS_FISH_START//\//\\/}/,/${WSMS_FISH_END//\//\\/}/d" "$HOME/.config/fish/config.fish"
        # Remove any older version blocks (v4.0, v4.1, v4.2 ...)
        sed_in_place '/# >>> WSMS PRO v[0-9][.][0-9] FISH >>>/,/# <<< WSMS PRO v[0-9][.][0-9] FISH <<</d' "$HOME/.config/fish/config.fish"
    fi
    echo -e "   ${GREEN}✅ Fish config cleaned${NC}"
fi

# ============================================
# 2. CLEAN BASH CONFIG
# ============================================
echo -e "\n${YELLOW}💻 Cleaning Bash configuration...${NC}"
if [ -f "$HOME/.bashrc" ]; then
    run_cmd cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$TIMESTAMP"
    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] Remove marker block: $WSMS_BASH_START ... $WSMS_BASH_END"
        echo "   [DRY-RUN] Remove any older WSMS PRO vX.Y BASH blocks"
    else
        # Remove current v4.3 block
        sed_in_place "/${WSMS_BASH_START//\//\\/}/,/${WSMS_BASH_END//\//\\/}/d" "$HOME/.bashrc"
        # Remove any older version blocks (v4.0, v4.1, v4.2 ...)
        sed_in_place '/# >>> WSMS PRO v[0-9][.][0-9] BASH >>>/,/# <<< WSMS PRO v[0-9][.][0-9] BASH <<</d' "$HOME/.bashrc"
    fi
    echo -e "   ${GREEN}✅ Bash config cleaned${NC}"
fi

# Also clean .bash_profile if it exists and has WSMS blocks
if [ -f "$HOME/.bash_profile" ]; then
    if grep -q 'WSMS PRO v' "$HOME/.bash_profile" 2>/dev/null; then
        run_cmd cp "$HOME/.bash_profile" "$HOME/.bash_profile.backup.$TIMESTAMP"
        if [ "$DRY_RUN" = true ]; then
            echo "   [DRY-RUN] Remove WSMS blocks from .bash_profile"
        else
            sed_in_place '/# >>> WSMS PRO v[0-9][.][0-9] BASH >>>/,/# <<< WSMS PRO v[0-9][.][0-9] BASH <<</d' "$HOME/.bash_profile"
        fi
        echo -e "   ${GREEN}✅ .bash_profile cleaned${NC}"
    fi
fi

# ============================================
# 3. REMOVE SCRIPTS
# ============================================
echo -e "\n${YELLOW}📂 Removing scripts...${NC}"
if [ -d "$HOME/scripts" ]; then
    run_cmd mkdir -p "$HOME/scripts-backup-old"
    run_cmd cp -r "$HOME/scripts" "$HOME/scripts-backup-old/scripts.$TIMESTAMP"
    run_cmd rm -rf "$HOME/scripts"
    echo -e "   ${GREEN}✅ Scripts removed (backup saved)${NC}"
fi

# ============================================
# 4. CLEAN CRONTAB
# ============================================
echo -e "\n${YELLOW}⏰ Cleaning crontab...${NC}"
if crontab -l &> /dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] Backup crontab to: $HOME/crontab.backup.$TIMESTAMP.txt"
        echo "   [DRY-RUN] Remove WSMS-related cron entries"
    else
        crontab -l > "$HOME/crontab.backup.$TIMESTAMP.txt" 2> /dev/null
        crontab -l 2> /dev/null | grep -v "# WSMS PRO" \
            | grep -v "server-health-audit.sh" \
            | grep -v "wp-automated-maintenance-engine.sh" \
            | grep -v "wp-essential-assets-backup.sh" \
            | grep -v "wp-full-recovery-backup.sh" \
            | grep -v "wp-smart-retention-manager.sh" \
            | grep -v "wp-rollback.sh" \
            | grep -v "wp-hosts-sync.sh" \
            | grep -v "mysql-backup-manager.sh" \
            | grep -v "nas-sftp-sync.sh" \
            | grep -v "clamav-auto-scan.sh" \
            | grep -v "clamav-full-scan.sh" \
            | grep -v "freshclam" \
            | crontab -
    fi
    echo -e "   ${GREEN}✅ Crontab cleaned${NC}"
fi

# ============================================
# 5. CLEAN /etc/hosts WSMS BLOCK
# ============================================
echo -e "\n${YELLOW}🌐 Cleaning /etc/hosts WSMS block...${NC}"
if [ -f "/etc/hosts" ]; then
    TMP_HOSTS="$(mktemp)"
    awk -v start="$WSMS_HOSTS_START" -v end="$WSMS_HOSTS_END" '
        $0 == start { skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
    ' /etc/hosts > "$TMP_HOSTS"

    HOSTS_BACKUP="/tmp/hosts.wsms.uninstall.backup.$TIMESTAMP"
    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] Backup hosts to: $HOSTS_BACKUP"
        echo "   [DRY-RUN] Remove marker block: $WSMS_HOSTS_START ... $WSMS_HOSTS_END"
        echo -e "   ${GREEN}✅ /etc/hosts cleanup simulated${NC}"
    elif sudo cp /etc/hosts "$HOSTS_BACKUP" && sudo cp "$TMP_HOSTS" /etc/hosts; then
        echo -e "   ${GREEN}✅ /etc/hosts cleaned${NC}"
        echo "   Backup: $HOSTS_BACKUP"
    else
        echo -e "   ${YELLOW}⚠️ Could not update /etc/hosts (sudo required?)${NC}"
    fi
    run_cmd rm -f "$TMP_HOSTS"
fi

# ============================================
# 6. REMOVE BACKUP DIRECTORIES
# ============================================
echo -e "\n${YELLOW}💾 Backup directories...${NC}"
BACKUP_DIRS="$HOME/backups-lite $HOME/backups-full $HOME/backups-manual $HOME/mysql-backups $HOME/backups-rollback"

if [ "$FORCE_MODE" = true ]; then
    for dir in $BACKUP_DIRS; do
        [ -d "$dir" ] && run_cmd rm -rf "$dir" && echo "   🗑️ Removed: $dir"
    done
else
    echo -e "   ${YELLOW}⚠️ Use --force to remove backup directories${NC}"
fi

# ============================================
# 6b. REMOVE MANUAL SCRIPT COPY DIRECTORIES
# ============================================
echo -e "\n${YELLOW}📂 Script copy/backup directories...${NC}"
SCRIPT_COPY_DIRS=("$HOME/scripts-backup-old" "$HOME/scripts-backup" "$HOME/scripts_copy_"*)

if [ "$FORCE_MODE" = true ]; then
    removed_script_dirs=0
    for dir in "${SCRIPT_COPY_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            run_cmd rm -rf "$dir"
            echo "   🗑️ Removed: $dir"
            ((removed_script_dirs++))
        fi
    done
    if [ "$removed_script_dirs" -eq 0 ]; then
        echo "   ✅ No script copy directories found"
    fi
else
    found_script_copy=false
    for dir in "${SCRIPT_COPY_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            found_script_copy=true
            echo "   ⚠️ Preserved: $dir"
        fi
    done
    if [ "$found_script_copy" = true ]; then
        echo -e "   ${YELLOW}💡 Use --force to remove script copy directories too${NC}"
    else
        echo "   ✅ No script copy directories found"
    fi
fi

# ============================================
# 7. REMOVE LOGS
# ============================================
echo -e "\n${YELLOW}📝 Logs directory...${NC}"
if [ "$FORCE_MODE" = true ] && [ -d "$HOME/logs/wsms" ]; then
    run_cmd rm -rf "$HOME/logs/wsms"
    echo -e "   ${GREEN}✅ Logs removed${NC}"
else
    echo -e "   ${YELLOW}⚠️ Use --force to remove logs${NC}"
fi

# ============================================
# 8. REMOVE INSTALLATION FILES
# ============================================
echo -e "\n${YELLOW}📦 Installation files...${NC}"
for file in "$HOME/install_wsms.sh" "$HOME/install_wsms_pl.sh" "$HOME/wsms-uninstall.sh" "$HOME/uninstall.sh"; do
    if [ -f "$file" ]; then
        run_cmd rm -f "$file"
        echo "   🗑️ Removed: $(basename "$file")"
    fi
done

# ============================================
# FINAL
# ============================================
echo ""
echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO UNINSTALL COMPLETE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo -e "${YELLOW}📦 Backups saved with timestamp: $TIMESTAMP${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🧪 Dry-run completed: no files were modified${NC}"
fi
echo ""
echo -e "${YELLOW}🔄 Reload your shell:${NC}"
if [ "$CURRENT_SHELL" = "fish" ]; then
    echo "   source ~/.config/fish/config.fish"
else
    echo "   source ~/.bashrc"
fi
