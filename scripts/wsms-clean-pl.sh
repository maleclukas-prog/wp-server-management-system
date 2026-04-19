#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SKRYPT CZYSZCZĄCY SYSTEM
# Opis: Czyści stare logi, backupy i pliki tymczasowe
# Użycie: ./wsms-clean.sh [--force]
# =================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.2 - CZYSZCZENIE SYSTEMU                  ${NC}"
echo -e "${CYAN}==========================================================${NC}"

cd ~ || exit 1

# ============================================
# 1. STARE LOGI W KATALOGU GŁÓWNYM
# ============================================
echo -e "\n${YELLOW}📝 Czyszczenie starych logów z katalogu domowego...${NC}"

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
    echo "   ✅ Nie znaleziono starych logów"
else
    echo -e "   ${GREEN}✅ Usunięto $deleted_logs starych logów${NC}"
fi

# ============================================
# 2. NADMIAROWE KOPIE .bashrc
# ============================================
echo -e "\n${YELLOW}💻 Czyszczenie nadmiarowych kopii .bashrc...${NC}"

bashrc_backups=$(ls -t .bashrc.backup.* 2>/dev/null)
bashrc_count=$(echo "$bashrc_backups" | grep -c . 2>/dev/null || echo 0)

if [ "$bashrc_count" -gt 1 ]; then
    echo "$bashrc_backups" | tail -n +2 | while read -r file; do
        [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"
    done
    echo -e "   ${GREEN}✅ Zachowano najnowszą kopię .bashrc.backup, usunięto $((bashrc_count - 1)) starych${NC}"
else
    echo "   ✅ Brak nadmiarowych kopii .bashrc"
fi

# ============================================
# 3. NADMIAROWE KOPIE CRONTAB
# ============================================
echo -e "\n${YELLOW}⏰ Czyszczenie nadmiarowych kopii crontab...${NC}"

crontab_backups=$(ls -t crontab*.txt 2>/dev/null)
crontab_count=$(echo "$crontab_backups" | grep -c . 2>/dev/null || echo 0)

if [ "$crontab_count" -gt 1 ]; then
    echo "$crontab_backups" | tail -n +2 | while read -r file; do
        [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"
    done
    echo -e "   ${GREEN}✅ Zachowano najnowszą kopię crontab, usunięto $((crontab_count - 1)) starych${NC}"
else
    echo "   ✅ Brak nadmiarowych kopii crontab"
fi

# ============================================
# 4. STARE KOPIE ZAPASOWE SKRYPTÓW
# ============================================
echo -e "\n${YELLOW}📂 Czyszczenie starych katalogów zapasowych...${NC}"

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
    echo "   ✅ Nie znaleziono starych katalogów"
else
    echo -e "   ${GREEN}✅ Usunięto $deleted_dirs starych katalogów${NC}"
fi

# ============================================
# 5. PLIKI TYMCZASOWE
# ============================================
echo -e "\n${YELLOW}📦 Czyszczenie plików tymczasowych...${NC}"

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
    echo "   ✅ Nie znaleziono plików tymczasowych"
else
    echo -e "   ${GREEN}✅ Usunięto $deleted_temp plików tymczasowych${NC}"
fi

# ============================================
# 6. STARE PLIKI INSTALATORA (OPCJONALNIE)
# ============================================
echo -e "\n${YELLOW}📦 Sprawdzanie starych plików instalatora...${NC}"

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
            echo -e "   ${YELLOW}⚠️  $file (użyj --force aby usunąć)${NC}"
        fi
    fi
done

if [ $deleted_installers -gt 0 ]; then
    echo -e "   ${GREEN}✅ Usunięto $deleted_installers starych plików instalatora${NC}"
fi

# ============================================
# 7. PUSTE PLIKI LOGÓW (OPCJONALNIE)
# ============================================
echo -e "\n${YELLOW}📝 Sprawdzanie pustych plików logów...${NC}"

if [ -d "$HOME/logs/wsms" ]; then
    empty_logs=$(find "$HOME/logs/wsms" -name "*.log" -type f -empty 2>/dev/null)
    if [ -n "$empty_logs" ]; then
        if [ "$FORCE_MODE" = true ]; then
            echo "$empty_logs" | while read -r file; do
                rm -f "$file"
                echo "   🗑️  $file (pusty)"
            done
        else
            echo -e "   ${YELLOW}⚠️  Znaleziono puste pliki logów (użyj --force aby usunąć)${NC}"
            echo "$empty_logs" | head -5 | sed 's/^/      /'
        fi
    else
        echo "   ✅ Brak pustych plików logów"
    fi
fi

# ============================================
# PODSUMOWANIE
# ============================================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ CZYSZCZENIE ZAKOŃCZONE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""

echo -e "${CYAN}📁 Pozostałe pliki w ~/ (nieukryte):${NC}"
ls -la ~ 2>/dev/null | grep -E "^-" | grep -v "^\." | awk '{print "   " $9}' | head -20

echo ""
echo -e "${YELLOW}💡 Wskazówka: Użyj --force aby usunąć stare pliki instalatora i puste logi${NC}"