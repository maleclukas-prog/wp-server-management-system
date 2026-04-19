#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MASTER REFERENCE GUIDE
# Complete command reference with rollback system documentation
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}🆘 WSMS PRO v4.2 - MASTER REFERENCE GUIDE${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ System Time: $(date)"
echo -e "📦 Version: 4.2 (Enhanced with Rollback Engine)"
echo -e "📂 Config: $(basename "$HOME")/scripts/wsms-config.sh"
echo ""

# ============================================
# QUICK START
# ============================================
echo -e "${CYAN}▶ QUICK START - Najważniejsze komendy${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Pełny przegląd: sprzęt + WordPress + backupy"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "Wersje WordPress i dostępne aktualizacje"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Bezpieczna aktualizacja (Backup → Snapshot → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Utwórz snapshoty rollback dla wszystkich stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Przywróć stronę do ostatniego snapshota"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "Ten dokument"
echo ""

# ============================================
# ROLLBACK SYSTEM (NOWOŚĆ!)
# ============================================
echo -e "${CYAN}▶ 🔄 SYSTEM ROLLBACK - NOWOŚĆ w v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczne snapshoty przed aktualizacją umożliwiają"
echo -e "       natychmiastowe przywrócenie strony w razie problemów."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Utwórz snapshoty dla WSZYSTKICH stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot [site]" "Utwórz snapshot dla konkretnej strony"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshots" "Lista wszystkich dostępnych snapshotów"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshots [site]" "Lista snapshotów dla konkretnej strony"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Przywróć do NAJNOWSZEGO snapshota"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site] [data]" "Przywróć do konkretnego snapshota"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-clean [dni]" "Wyczyść stare snapshoty (domyślnie: $RETENTION_ROLLBACK dni)"
echo ""
echo -e "${YELLOW}Przykłady:${NC}"
echo "   wp-snapshot uszatek"
echo "   wp-snapshots uszatek"
echo "   wp-rollback uszatek"
echo "   wp-rollback uszatek 20260419_143022"
echo ""

# ============================================
# BACKUP MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 💾 ZARZĄDZANIE BACKUPAMI${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Trójwarstwowy system backupów (Lite/Full/MySQL)"
echo "       z automatycznym zarządzaniem retencją."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-lite" "Szybki backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-full" "Pełny backup całej strony"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-ui" "Interaktywne narzędzie do backupów"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-site" "Alias do wp-backup-ui"
printf "  ${GREEN}%-22s${NC} %s\n" "red-robin" "Awaryjny backup konfiguracji systemu"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "backup-list" "Lista wszystkich backupów ze szczegółami"
printf "  ${GREEN}%-22s${NC} %s\n" "backup-size" "Wykorzystanie miejsca na backupy"
printf "  ${GREEN}%-22s${NC} %s\n" "backup-dirs" "Struktura katalogów backupów"
printf "  ${GREEN}%-22s${NC} %s\n" "backup-clean" "Interaktywne czyszczenie (z potwierdzeniem)"
printf "  ${GREEN}%-22s${NC} %s\n" "backup-force-clean" "Automatyczne czyszczenie wg retencji"
printf "  ${GREEN}%-22s${NC} %s\n" "backup-emergency" "AWARYJNE: zachowaj tylko 2 najnowsze kopie"
echo ""

# ============================================
# DATABASE MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 🗄️ BAZY DANYCH${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczne backupy baz danych z odczytem konfiguracji"
echo "       bezpośrednio z wp-config.php."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "mysql-backup-all" "Backup wszystkich baz WordPress"
printf "  ${GREEN}%-22s${NC} %s\n" "mysql-backup-list" "Lista dostępnych backupów baz"
printf "  ${GREEN}%-22s${NC} %s\n" "mysql-backup [site]" "Backup konkretnej bazy"
printf "  ${GREEN}%-22s${NC} %s\n" "db-backup" "Alias do mysql-backup"
echo ""

# ============================================
# MAINTENANCE & SECURITY
# ============================================
echo -e "${CYAN}▶ 🔧 UTRZYMANIE I BEZPIECZEŃSTWO${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Narzędzia do utrzymania i zabezpieczania infrastruktury."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-all" "Aktualizacja wszystkich stron (bez backupu)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update" "Alias do wp-update-all"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fix-perms" "Napraw uprawnienia plików i ACL"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fix-permissions" "Alias do wp-fix-perms"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-audit" "Głęboki audyt bezpieczeństwa i wydajności"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-diagnoza" "Alias do wp-audit"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-cli-validator" "Test połączenia WP-CLI dla wszystkich stron"
printf "  ${GREEN}%-22s${NC} %s\n" "system-diag" "Diagnostyka systemu operacyjnego"
echo ""

# ============================================
# NAS SYNC
# ============================================
echo -e "${CYAN}▶ ☁️ SYNCHRONIZACJA Z NAS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczna replikacja backupów na zdalny serwer NAS/SFTP."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync" "Ręczne uruchomienie synchronizacji"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-status" "Status ostatniej synchronizacji"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-logs" "Podgląd logów synchronizacji (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-errors" "Podgląd błędów synchronizacji (live)"
echo ""

# ============================================
# CLAMAV ANTIVIRUS
# ============================================
echo -e "${CYAN}▶ 🛡️ CLAMAV - ANTYWIRUS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Skanowanie malware i automatyczna kwarantanna."
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-scan" "Codzienny szybki skan (/var/www, /home)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-deep-scan" "Pełny skan systemu (wszystko)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-status" "Status usługi ClamAV"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-update" "Aktualizacja definicji wirusów"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-logs" "Podgląd logów skanowania (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-quarantine" "Lista plików w kwarantannie"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-clean-quarantine" "Wyczyść kwarantannę"
echo ""

# ============================================
# PER-SITE WP-CLI
# ============================================
echo -e "${CYAN}▶ 🎯 WP-CLI DLA POSZCZEGÓLNYCH STRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Bezpośredni dostęp do WP-CLI dla każdej strony"
echo "       z odpowiednim użytkownikiem systemowym."
echo ""

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-$name" "WP-CLI dla $name (użytkownik: $user)"
done

echo ""
echo -e "${YELLOW}Przykłady użycia:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   wp-$name plugin list"
    echo "   wp-$name core version"
    echo "   wp-$name user list"
    break  # Pokaż tylko dla pierwszej strony jako przykład
done
echo ""

# ============================================
# PER-SITE QUICK COMMANDS
# ============================================
echo -e "${CYAN}▶ ⚡ SZYBKIE KOMENDY DLA STRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-$name" "Backup lite dla $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot-$name" "Snapshot rollback dla $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-$name" "Rollback dla $name"
    echo ""
done

# ============================================
# RETENTION POLICIES
# ============================================
echo -e "${CYAN}▶ 📊 POLITYKI RETENCJI DANYCH${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Katalogi i okresy przechowywania:${NC}"
echo ""
printf "  ${GREEN}%-20s${NC} %-15s %s\n" "Typ backupu" "Katalog" "Retencja"
echo "  ----------------------------------------------------------------"
printf "  %-20s %-15s %s\n" "⚡ Lite Assets" "~/backups-lite/" "$RETENTION_LITE dni"
printf "  %-20s %-15s %s\n" "💾 Full Snapshots" "~/backups-full/" "$RETENTION_FULL dni"
printf "  %-20s %-15s %s\n" "🗄️ MySQL Dumps" "~/mysql-backups/" "$RETENTION_MYSQL dni"
printf "  %-20s %-15s %s\n" "📸 Rollback Snapshots" "~/backups-rollback/" "$RETENTION_ROLLBACK dni"
printf "  %-20s %-15s %s\n" "☁️ NAS Vault" "Remote NAS" "$NAS_RETENTION_DAYS dni"
echo ""
echo -e "${RED}⚠️ TRYB AWARYJNY:${NC} Gdy wykorzystanie dysku > ${DISK_ALERT_THRESHOLD}%,"
echo "   system automatycznie zachowuje tylko 2 najnowsze kopie."
echo ""

# ============================================
# INCIDENT RESPONSE - QUICK REFERENCE
# ============================================
echo -e "${CYAN}▶ 🚨 PROCEDURY AWARYJNE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Szybka reakcja na problemy:${NC}"
echo ""

printf "  ${RED}%-30s${NC} %s\n" "Strona nie działa po aktualizacji:" "wp-rollback [nazwa-strony]"
printf "  ${RED}%-30s${NC} %s\n" "Mało miejsca na dysku:" "backup-emergency"
printf "  ${RED}%-30s${NC} %s\n" "Błędy uprawnień (403/500):" "wp-fix-perms"
printf "  ${RED}%-30s${NC} %s\n" "Podejrzenie malware:" "clamav-deep-scan"
printf "  ${RED}%-30s${NC} %s\n" "Backup się nie wykonał:" "df -h && wp-backup-ui"
printf "  ${RED}%-30s${NC} %s\n" "NAS sync nie działa:" "nas-sync-status && nas-sync-errors"
printf "  ${RED}%-30s${NC} %s\n" "WP-CLI nie łączy się:" "wp-cli-validator"
printf "  ${RED}%-30s${NC} %s\n" "Biały ekran śmierci (WSOD):" "wp-rollback [nazwa-strony]"
echo ""

# ============================================
# LOG FILES LOCATION
# ============================================
echo -e "${CYAN}▶ 📝 PLIKI LOGÓW${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Lokalizacje logów:${NC}"
echo ""
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/backup-lite.log" "Backupy lite"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/backup-full.log" "Backupy pełne"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/updates.log" "Aktualizacje WordPress"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/retention.log" "Zarządzanie retencją"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/nas_sync.log" "Synchronizacja NAS"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/nas_errors.log" "Błędy synchronizacji NAS"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/clamav-scan.log" "Skanowanie ClamAV (dzienne)"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/clamav-full.log" "Skanowanie ClamAV (pełne)"
printf "  ${GREEN}%-25s${NC} %s\n" "~/logs/rollback-clean.log" "Czyszczenie snapshotów"
echo ""

# ============================================
# CRONTAB SCHEDULE
# ============================================
echo -e "${CYAN}▶ ⏰ HARMONOGRAM CRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Zaplanowane zadania:${NC}"
echo ""
echo "   Codziennie:"
echo "   • 01:00 - Aktualizacja definicji ClamAV"
echo "   • 02:00 - Synchronizacja z NAS"
echo "   • 03:00 - Szybki skan malware"
echo "   • 04:00 - Zarządzanie retencją backupów"
echo ""
echo "   Co tydzień:"
echo "   • Niedziela 02:00 - Backup lite"
echo "   • Środa 02:00 - Backup lite"
echo "   • Niedziela 04:00 - Pełny skan malware"
echo "   • Niedziela 06:00 - Aktualizacje WordPress (ze snapshotem!)"
echo "   • Poniedziałek 05:00 - Czyszczenie starych snapshotów"
echo ""
echo "   Co miesiąc:"
echo "   • 1. dnia miesiąca 03:00 - Pełny backup"
echo ""

# ============================================
# SYSTEM PATHS
# ============================================
echo -e "${CYAN}▶ 📂 ŚCIEŻKI SYSTEMOWE${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   📁 Skrypty:        $SCRIPT_DIR"
echo "   💾 Backupy lite:   $BACKUP_LITE_DIR"
echo "   💾 Backupy pełne:  $BACKUP_FULL_DIR"
echo "   🗄️ Backupy MySQL:  $BACKUP_MYSQL_DIR"
echo "   📸 Rollback:       $BACKUP_ROLLBACK_DIR"
echo "   📋 Logi:           $LOG_DIR"
echo "   🛡️ Kwarantanna:    $QUARANTINE_DIR"
echo ""

# ============================================
# PRO TIPS
# ============================================
echo -e "${CYAN}▶ 💡 PORADY EKSPERTA${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   🔹 Używaj 'wp-update-safe' zamiast 'wp-update-all' - tworzy snapshot"
echo "   🔹 Przed większymi zmianami: 'wp-snapshot all'"
echo "   🔹 Monitoruj miejsce: 'backup-size' raz w tygodniu"
echo "   🔹 Po awarii: 'wp-rollback [strona]' przywraca w 30 sekund"
echo "   🔹 Sprawdzaj logi: 'tail -f ~/logs/updates.log' podczas aktualizacji"
echo "   🔹 Testuj WP-CLI: 'wp-cli-validator' po zmianach uprawnień"
echo ""

# ============================================
# FOOTER
# ============================================
echo -e "${GREEN}✅ WSMS PRO v4.2 - GOTOWY DO PRACY${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}📚 Pełna dokumentacja:${NC} ~/scripts/, docs/ w repozytorium"
echo -e "${WHITE}🐛 Zgłoś problem:${NC} https://github.com/maleclukas-prog/wp-server-management-system/issues"
echo -e "${WHITE}👤 Maintainer:${NC} Lukasz Malec"
echo ""