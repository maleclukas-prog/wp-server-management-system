#!/bin/bash
# =================================================================
# 🧹 WSMS PRO v4.2 - UNIVERSAL UNINSTALLER
# Version: 1.0 | Works in any shell
# Description: Completely removes WSMS PRO from the system
# Usage: ./uninstall.sh [--force]
# =================================================================

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.2 - UNIVERSAL UNINSTALLER                 ${NC}"
echo -e "${CYAN}   Completely removes WSMS from the system                  ${NC}"
echo -e "${CYAN}==========================================================${NC}"

CURRENT_SHELL=$(basename "$SHELL")
echo -e "${YELLOW}📍 Detected shell: $CURRENT_SHELL${NC}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# 1. CLEAN FISH CONFIG
# ============================================
echo -e "\n${YELLOW}🐟 Cleaning Fish configuration...${NC}"
if [ -f "$HOME/.config/fish/config.fish" ]; then
    cp "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.backup.$TIMESTAMP"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.config/fish/config.fish"
    sed -i '/set -gx SCRIPTS_DIR/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias wp-/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias backup-/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias mysql-backup/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias nas-sync/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias clamav-/d' "$HOME/.config/fish/config.fish"
    sed -i '/^alias red-robin/d' "$HOME/.config/fish/config.fish"
    sed -i '/^function wp-update-safe/,/^end/d' "$HOME/.config/fish/config.fish"
    echo -e "   ${GREEN}✅ Fish config cleaned${NC}"
fi

# ============================================
# 2. CLEAN BASH CONFIG
# ============================================
echo -e "\n${YELLOW}💻 Cleaning Bash configuration...${NC}"
if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$TIMESTAMP"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.bashrc"
    sed -i '/export SCRIPTS_DIR/d' "$HOME/.bashrc"
    sed -i '/^alias wp-/d' "$HOME/.bashrc"
    sed -i '/^alias backup-/d' "$HOME/.bashrc"
    sed -i '/^alias mysql-backup/d' "$HOME/.bashrc"
    sed -i '/^alias nas-sync/d' "$HOME/.bashrc"
    sed -i '/^alias clamav-/d' "$HOME/.bashrc"
    sed -i '/^alias red-robin/d' "$HOME/.bashrc"
    echo -e "   ${GREEN}✅ Bash config cleaned${NC}"
fi

# ============================================
# 3. REMOVE SCRIPTS
# ============================================
echo -e "\n${YELLOW}📂 Removing scripts...${NC}"
if [ -d "$HOME/scripts" ]; then
    mkdir -p "$HOME/scripts-backup-old"
    cp -r "$HOME/scripts" "$HOME/scripts-backup-old/scripts.$TIMESTAMP" 2>/dev/null
    rm -rf "$HOME/scripts"
    echo -e "   ${GREEN}✅ Scripts removed (backup saved)${NC}"
fi

# ============================================
# 4. CLEAN CRONTAB
# ============================================
echo -e "\n${YELLOW}⏰ Cleaning crontab...${NC}"
if crontab -l &>/dev/null; then
    crontab -l > "$HOME/crontab.backup.$TIMESTAMP.txt" 2>/dev/null
    if crontab -l 2>/dev/null | grep -q "WSMS PRO"; then
        crontab -l 2>/dev/null | grep -v "# WSMS PRO" | grep -v "wp-" | grep -v "clamav" | grep -v "nas-sftp-sync" | grep -v "freshclam" | crontab -
        echo -e "   ${GREEN}✅ Crontab cleaned${NC}"
    fi
fi

# ============================================
# 5. REMOVE BACKUP DIRECTORIES
# ============================================
echo -e "\n${YELLOW}💾 Backup directories...${NC}"
BACKUP_DIRS="$HOME/backups-lite $HOME/backups-full $HOME/backups-manual $HOME/mysql-backups $HOME/backups-rollback"

if [ "$FORCE_MODE" = true ]; then
    for dir in $BACKUP_DIRS; do
        [ -d "$dir" ] && rm -rf "$dir" && echo "   🗑️ Removed: $dir"
    done
else
    echo -e "   ${YELLOW}⚠️ Use --force to remove backup directories${NC}"
fi

# ============================================
# 6. REMOVE LOGS
# ============================================
echo -e "\n${YELLOW}📝 Logs directory...${NC}"
if [ "$FORCE_MODE" = true ] && [ -d "$HOME/logs/wsms" ]; then
    rm -rf "$HOME/logs/wsms"
    echo -e "   ${GREEN}✅ Logs removed${NC}"
else
    echo -e "   ${YELLOW}⚠️ Use --force to remove logs${NC}"
fi

# ============================================
# 7. REMOVE INSTALLATION FILES
# ============================================
echo -e "\n${YELLOW}📦 Installation files...${NC}"
for file in "$HOME/install.sh" "$HOME/install-pl.sh" "$HOME/uninstall.sh"; do
    if [ -f "$file" ]; then
        rm -f "$file"
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
echo ""
echo -e "${YELLOW}🔄 Reload your shell:${NC}"
if [ "$CURRENT_SHELL" = "fish" ]; then
    echo "   source ~/.config/fish/config.fish"
else
    echo "   source ~/.bashrc"
fi