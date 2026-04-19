#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - PEŁNY SPIS KOMEND
# Kompletny przewodnik z systemem rollback
# Wersja rozszerzona o Health Check, Logi i Pomoc Interaktywną
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}🆘 WSMS PRO v4.2 - PEŁNY SPIS KOMEND${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ Czas systemowy: $(date)"
echo -e "📦 Wersja: 4.2 (Rozszerzona o Rollback Engine)"
echo -e "📂 Konfiguracja: $(basename "$HOME")/scripts/wsms-config.sh"
echo ""

# ============================================
# SZYBKI START
# ============================================
echo -e "${CYAN}▶ SZYBKI START - Najważniejsze komendy${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Pełny przegląd: sprzęt + WordPress + backupy"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "Wersje WordPress i dostępne aktualizacje"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Bezpieczna aktualizacja (Backup → Migawka → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Utwórz migawki rollback dla wszystkich stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [strona]" "Przywróć stronę do ostatniej migawki"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Szybkie sprawdzenie stanu systemu"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "Ten dokument"
echo ""

# ============================================
# SYSTEM ROLLBACK (NOWOŚĆ!)
# ============================================
echo -e "${CYAN}▶ 🔄 SYSTEM ROLLBACK - NOWOŚĆ w v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczne migawki przed aktualizacją umożliwiają"
echo -e "       natychmiastowe przywrócenie strony w razie problemów."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "wp-snapshot all" "Utwórz migawki dla WSZYSTKICH stron"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-snapshot [strona]" "Utwórz migawkę dla konkretnej strony"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-snapshots" "Lista wszystkich dostępnych migawek"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-snapshots [strona]" "Lista migawek dla konkretnej strony"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-rollback [strona]" "Przywróć do NAJNOWSZEJ migawki"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-rollback [strona] [data]" "Przywróć do konkretnej migawki"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-rollback-safe [strona]" "Przywracanie z potwierdzeniem"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-rollback-clean [dni]" "Wyczyść stare migawki (domyślnie: $RETENTION_ROLLBACK dni)"
echo ""
echo -e "${YELLOW}Przykłady:${NC}"
echo "   wp-snapshot mojastrona"
echo "   wp-snapshots mojastrona"
echo "   wp-rollback mojastrona"
echo "   wp-rollback mojastrona 20260419_143022"
echo ""

# ============================================
# ZARZĄDZANIE BACKUPAMI
# ============================================
echo -e "${CYAN}▶ 💾 ZARZĄDZANIE BACKUPAMI${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Trójwarstwowy system backupów (Lite/Full/MySQL)"
echo "       z automatycznym zarządzaniem retencją."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "wp-backup-lite" "Szybki backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-backup-full" "Pełny backup całej strony"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-backup-ui" "Interaktywne narzędzie do backupów"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-backup-site" "Alias do wp-backup-ui"
printf "  ${GREEN}%-30s${NC} %s\n" "red-robin" "Awaryjny backup konfiguracji systemu"
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "backup-list" "Lista wszystkich backupów ze szczegółami"
printf "  ${GREEN}%-30s${NC} %s\n" "backup-size" "Wykorzystanie miejsca na backupy"
printf "  ${GREEN}%-30s${NC} %s\n" "backup-dirs" "Struktura katalogów backupów"
printf "  ${GREEN}%-30s${NC} %s\n" "backup-clean" "Interaktywne czyszczenie (z potwierdzeniem)"
printf "  ${GREEN}%-30s${NC} %s\n" "backup-force-clean" "Automatyczne czyszczenie wg retencji"
printf "  ${GREEN}%-30s${NC} %s\n" "backup-emergency" "AWARYJNE: zachowaj tylko 2 najnowsze kopie"
echo ""

# ============================================
# BAZY DANYCH
# ============================================
echo -e "${CYAN}▶ 🗄️ BAZY DANYCH${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczne backupy baz danych z odczytem konfiguracji"
echo "       bezpośrednio z plików wp-config.php."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "mysql-backup-all" "Backup wszystkich baz WordPress"
printf "  ${GREEN}%-30s${NC} %s\n" "mysql-backup-list" "Lista dostępnych backupów baz"
printf "  ${GREEN}%-30s${NC} %s\n" "mysql-backup [strona]" "Backup konkretnej bazy"
printf "  ${GREEN}%-30s${NC} %s\n" "db-backup" "Alias do mysql-backup"
echo ""

# ============================================
# UTRZYMANIE I BEZPIECZEŃSTWO
# ============================================
echo -e "${CYAN}▶ 🔧 UTRZYMANIE I BEZPIECZEŃSTWO${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Narzędzia do utrzymania i zabezpieczania infrastruktury."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "wp-update-all" "Aktualizacja wszystkich stron (bez backupu)"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-update" "Alias do wp-update-all"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-fix-perms" "Napraw uprawnienia plików i ACL"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-fix-permissions" "Alias do wp-fix-perms"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-audit" "Głęboki audyt bezpieczeństwa i wydajności"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-diagnoza" "Alias do wp-audit"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-cli-validator" "Test połączenia WP-CLI dla wszystkich stron"
printf "  ${GREEN}%-30s${NC} %s\n" "system-diag" "Diagnostyka systemu operacyjnego"
echo ""

# ============================================
# SYNCHRONIZACJA Z NAS
# ============================================
echo -e "${CYAN}▶ ☁️ SYNCHRONIZACJA Z NAS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Automatyczna replikacja backupów na zdalny serwer NAS/SFTP."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "nas-sync" "Ręczne uruchomienie synchronizacji"
printf "  ${GREEN}%-30s${NC} %s\n" "nas-sync-status" "Status ostatniej synchronizacji"
printf "  ${GREEN}%-30s${NC} %s\n" "nas-sync-logs" "Podgląd logów synchronizacji (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "nas-sync-errors" "Podgląd błędów synchronizacji (na żywo)"
echo ""

# ============================================
# CLAMAV - ANTYWIRUS
# ============================================
echo -e "${CYAN}▶ 🛡️ CLAMAV - ANTYWIRUS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Skanowanie malware i automatyczna kwarantanna."
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-scan" "Codzienny szybki skan (/var/www, /home)"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-deep-scan" "Pełny skan systemu (wszystko)"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-status" "Status usługi ClamAV"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-update" "Aktualizacja definicji wirusów"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-logs" "Podgląd logów skanowania (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-quarantine" "Lista plików w kwarantannie"
printf "  ${GREEN}%-30s${NC} %s\n" "clamav-clean-quarantine" "Wyczyść kwarantannę"
echo ""

# ============================================
# SYSTEM SPRAWDZANIA STANU (NOWOŚĆ!)
# ============================================
echo -e "${CYAN}▶ 🏥 SYSTEM SPRAWDZANIA STANU - NOWOŚĆ w v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Szybka diagnostyka stanu systemu"
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "wp-health" "Pełne sprawdzenie stanu"
printf "  ${GREEN}%-30s${NC} %s\n" "wp-quick-status" "Alias do wp-status"
echo ""

# ============================================
# ZARZĄDZANIE LOGAMI (NOWOŚĆ!)
# ============================================
echo -e "${CYAN}▶ 📝 ZARZĄDZANIE LOGAMI - NOWOŚĆ w v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Szybki dostęp do plików logów"
echo ""
printf "  ${GREEN}%-30s${NC} %s\n" "wp-logs" "Pokaż status wszystkich logów"
printf "  ${GREEN}%-30s${NC} %s\n" "logs-backup" "Podgląd logów backupów (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "logs-update" "Podgląd logów aktualizacji (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "logs-sync" "Podgląd logów synchronizacji NAS (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "logs-scan" "Podgląd logów skanowania malware (na żywo)"
printf "  ${GREEN}%-30s${NC} %s\n" "logs-all" "Lista wszystkich katalogów logów"
echo ""

# ============================================
# WP-CLI DLA POSZCZEGÓLNYCH STRON
# ============================================
echo -e "${CYAN}▶ 🎯 WP-CLI DLA POSZCZEGÓLNYCH STRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Opis:${NC} Bezpośredni dostęp do WP-CLI dla każdej strony"
echo "       z odpowiednim użytkownikiem systemowym."
echo ""

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-30s${NC} %s\n" "wp-$name" "WP-CLI dla $name (użytkownik: $user)"
done

echo ""
echo -e "${YELLOW}Przykłady użycia:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   wp-$name plugin list"
    echo "   wp-$name core version"
    echo "   wp-$name user list"
    break
done
echo ""

# ============================================
# SZYBKIE KOMENDY DLA STRON
# ============================================
echo -e "${CYAN}▶ ⚡ SZYBKIE KOMENDY DLA STRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-30s${NC} %s\n" "wp-backup-$name" "Szybki backup dla $name"
    printf "  ${GREEN}%-30s${NC} %s\n" "wp-snapshot-$name" "Migawka rollback dla $name"
    printf "  ${GREEN}%-30s${NC} %s\n" "wp-rollback-$name" "Rollback dla $name"
    echo ""
done

# ============================================
# POLITYKI RETENCJI DANYCH
# ============================================
echo -e "${CYAN}▶ 📊 POLITYKI RETENCJI DANYCH${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Katalogi i okresy przechowywania:${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %-18s %s\n" "Typ backupu" "Katalog" "Retencja"
echo "  ------------------------------------------------------------------"
printf "  %-22s %-18s %s\n" "⚡ Lite Assets" "~/backups-lite/" "$RETENTION_LITE dni"
printf "  %-22s %-18s %s\n" "💾 Full Snapshots" "~/backups-full/" "$RETENTION_FULL dni"
printf "  %-22s %-18s %s\n" "🗄️ MySQL Dumps" "~/mysql-backups/" "$RETENTION_MYSQL dni"
printf "  %-22s %-18s %s\n" "📸 Rollback Snapshots" "~/backups-rollback/" "$RETENTION_ROLLBACK dni"
printf "  %-22s %-18s %s\n" "☁️ NAS Vault" "Zdalny NAS" "$NAS_RETENTION_DAYS dni"
echo ""
echo -e "${RED}⚠️ TRYB AWARYJNY:${NC} Gdy wykorzystanie dysku > ${DISK_ALERT_THRESHOLD}%,"
echo "   system automatycznie zachowuje tylko 2 najnowsze kopie."
echo ""

# ============================================
# PROCEDURY AWARYJNE (SOP)
# ============================================
echo -e "${CYAN}▶ 🚨 PROCEDURY AWARYJNE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Szybka reakcja na problemy:${NC}"
echo ""

printf "  ${RED}%-35s${NC} %s\n" "Strona nie działa po aktualizacji:" "wp-rollback [nazwa-strony]"
printf "  ${RED}%-35s${NC} %s\n" "Mało miejsca na dysku:" "backup-emergency"
printf "  ${RED}%-35s${NC} %s\n" "Błędy uprawnień (403/500):" "wp-fix-perms"
printf "  ${RED}%-35s${NC} %s\n" "Podejrzenie malware:" "clamav-deep-scan"
printf "  ${RED}%-35s${NC} %s\n" "Backup się nie wykonał:" "df -h && wp-backup-ui"
printf "  ${RED}%-35s${NC} %s\n" "NAS sync nie działa:" "nas-sync-status && nas-sync-errors"
printf "  ${RED}%-35s${NC} %s\n" "WP-CLI nie łączy się:" "wp-cli-validator"
printf "  ${RED}%-35s${NC} %s\n" "Biały ekran śmierci (WSOD):" "wp-rollback [nazwa-strony]"
echo ""

# ============================================
# LOKALIZACJE PLIKÓW LOGÓW
# ============================================
echo -e "${CYAN}▶ 📝 LOKALIZACJE PLIKÓW LOGÓW${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Logi zorganizowane w ~/logs/wsms/:${NC}"
echo ""
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/backups/lite.log" "Szybkie backupy"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/backups/full.log" "Pełne backupy"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/backups/mysql.log" "Backupy baz danych"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/maintenance/updates.log" "Aktualizacje WordPress"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/maintenance/permissions.log" "Naprawy uprawnień"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/retention/retention.log" "Zarządzanie retencją"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/sync/nas-sync.log" "Synchronizacja NAS"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/sync/nas-errors.log" "Błędy synchronizacji NAS"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/security/clamav-scan.log" "Skanowanie ClamAV (dzienne)"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/security/clamav-full.log" "Skanowanie ClamAV (pełne)"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/rollback/snapshots.log" "Tworzenie migawek"
printf "  ${GREEN}%-40s${NC} %s\n" "~/logs/wsms/rollback/rollback-clean.log" "Czyszczenie migawek"
echo ""

# ============================================
# HARMONOGRAM CRON
# ============================================
echo -e "${CYAN}▶ ⏰ HARMONOGRAM CRON${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Zaplanowane zadania (9 zautomatyzowanych zadań):${NC}"
echo ""
echo "   Codziennie:"
echo "   • 01:00 - Aktualizacja definicji ClamAV"
echo "   • 02:00 - Synchronizacja z NAS"
echo "   • 03:00 - Szybki skan malware"
echo "   • 04:00 - Zarządzanie retencją backupów"
echo ""
echo "   Co tydzień:"
echo "   • Niedziela 02:00 - Szybki backup"
echo "   • Środa 02:00 - Szybki backup"
echo "   • Niedziela 04:00 - Pełny skan malware"
echo "   • Niedziela 06:00 - Aktualizacje WordPress (z migawką!)"
echo "   • Poniedziałek 05:00 - Czyszczenie starych migawek"
echo ""
echo "   Co miesiąc:"
echo "   • 1. dnia miesiąca 03:00 - Pełny backup"
echo ""

# ============================================
# ŚCIEŻKI SYSTEMOWE
# ============================================
echo -e "${CYAN}▶ 📂 ŚCIEŻKI SYSTEMOWE${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   📁 Skrypty:        $SCRIPT_DIR"
echo "   💾 Szybkie backupy: $BACKUP_LITE_DIR"
echo "   💾 Pełne backupy:   $BACKUP_FULL_DIR"
echo "   🗄️ Backupy MySQL:   $BACKUP_MYSQL_DIR"
echo "   📸 Rollback:        $BACKUP_ROLLBACK_DIR"
echo "   📋 Logi:            $LOG_BASE_DIR"
echo "   🛡️ Kwarantanna:     $QUARANTINE_DIR"
echo ""

# ============================================
# PORADY EKSPERTA
# ============================================
echo -e "${CYAN}▶ 💡 PORADY EKSPERTA${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   🔹 Używaj 'wp-update-safe' zamiast 'wp-update-all' - tworzy migawkę"
echo "   🔹 Przed większymi zmianami: 'wp-snapshot all'"
echo "   🔹 Monitoruj miejsce: 'backup-size' raz w tygodniu"
echo "   🔹 Po awarii: 'wp-rollback [strona]' przywraca w 30 sekund"
echo "   🔹 Sprawdzaj stan: 'wp-health' dla szybkiej diagnostyki"
echo "   🔹 Podgląd logów: 'logs-backup' lub 'logs-update' na żywo"
echo "   🔹 Testuj WP-CLI po zmianach uprawnień: 'wp-cli-validator'"
echo ""

# ============================================
# STOPKA
# ============================================
echo -e "${GREEN}✅ WSMS PRO v4.2 - GOTOWY DO PRACY${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}📚 Pełna dokumentacja:${NC} ~/scripts/, docs/ w repozytorium"
echo -e "${WHITE}🐛 Zgłoś problem:${NC} https://github.com/maleclukas-prog/wp-server-management-system/issues"
echo -e "${WHITE}👤 Autor:${NC} Lukasz Malec"
echo ""