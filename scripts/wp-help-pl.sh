#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - PEŁNY SPIS KOMEND
# Logicznie ułożony: Diagnostyka → Backupy → Sync → Odzyskiwanie
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║             🆘 WSMS PRO v4.2 — SPIS KOMEND                  ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}⏰ $(date) │ 📦 v4.2 │ 🖥️  $(hostname)${NC}"
echo ""

# ============================================
# SEKCJA 1: DIAGNOSTYKA SYSTEMU
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔍 DIAGNOSTYKA SYSTEMU                                     │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Pełny przegląd (CPU, RAM, usługi, backupy)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Szybki test (dysk, usługi, WP-CLI)"
printf "  ${GREEN}%-22s${NC} %s\n" "system-diag" "Diagnostyka systemu operacyjnego"
echo ""

# ============================================
# SEKCJA 2: ZARZĄDZANIE FLOTĄ WORDPRESS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🌐 ZARZĄDZANIE FLOTĄ WORDPRESS                             │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "Wszystkie strony: wersje + oczekujące aktualizacje"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-audit" "Głęboki audyt: DB, wtyczki, motywy, bezpieczeństwo"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-cli-validator" "Test połączenia WP-CLI dla wszystkich stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fix-perms" "Napraw uprawnienia plików i ACL"
echo ""

# ============================================
# SEKCJA 3: ZARZĄDZANIE BACKUPAMI
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  💾 ZARZĄDZANIE BACKUPAMI                                   │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${YELLOW}  Tworzenie backupów:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-lite" "Szybki: motywy, wtyczki, uploads, config"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-full" "Pełny: wszystkie pliki + baza danych"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-all" "Wszystkie bazy WordPress"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-ui" "Menu interaktywne"
echo ""
echo -e "${YELLOW}  Przeglądanie backupów:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-list" "Lista wszystkich backupów z rozmiarem i datą"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-size" "Wykorzystanie miejsca na katalog"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-dirs" "Pokaż strukturę katalogów"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-list" "Lista backupów baz danych"
echo ""
echo -e "${YELLOW}  Czyszczenie:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-clean" "Interaktywne (z potwierdzeniem)"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-force-clean" "Automatyczne wg polityki retencji"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency" "AWARYJNE: zachowaj tylko 2 najnowsze"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean" "Wyczyść stare logi i pliki tymczasowe"
echo ""

# ============================================
# SEKCJA 4: SYNCHRONIZACJA ZDALNA (NAS)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ☁️ SYNCHRONIZACJA ZDALNA (NAS)                              │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync" "Ręczna synchronizacja z NAS"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-status" "Pokaż status ostatniej synchronizacji"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-logs" "Podgląd logów synchronizacji (na żywo)"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-errors" "Podgląd błędów synchronizacji (na żywo)"
echo ""

# ============================================
# SEKCJA 5: AKTUALIZACJE I UTRZYMANIE
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 AKTUALIZACJE I UTRZYMANIE                               │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "ZALECANE: Backup → Migawka → Aktualizacja"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-all" "Aktualizuj wszystkie strony (bez backupu)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update" "Alias do wp-update-all"
echo ""

# ============================================
# SEKCJA 6: SYSTEM ROLLBACK (NOWOŚĆ!)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 SYSTEM ROLLBACK — NOWOŚĆ w v4.2                         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}  Natychmiastowe odzyskiwanie po nieudanych aktualizacjach!${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Utwórz migawki dla WSZYSTKICH stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot [strona]" "Utwórz migawkę dla jednej strony"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshots" "Lista wszystkich migawek"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [strona]" "Przywróć do NAJNOWSZEJ migawki"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-safe [strona]" "Przywracanie z potwierdzeniem"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-clean [dni]" "Wyczyść stare migawki"
echo ""
echo -e "${YELLOW}  Przykłady:${NC}"
echo "     wp-snapshot mojastrona"
echo "     wp-rollback mojastrona"
echo "     wp-rollback mojastrona 20260419_143022"
echo ""

# ============================================
# SEKCJA 7: BEZPIECZEŃSTWO
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🛡️ BEZPIECZEŃSTWO                                          │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-scan" "Codzienny szybki skan (/var/www, /home)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-deep-scan" "Pełny skan systemu"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-status" "Status usługi ClamAV"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-update" "Aktualizacja definicji wirusów"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-quarantine" "Lista plików w kwarantannie"
echo ""

# ============================================
# SEKCJA 8: ROZWIĄZYWANIE PROBLEMÓW
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🚨 ROZWIĄZYWANIE PROBLEMÓW                                 │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${RED}%-30s${NC} %s\n" "Strona padła po aktualizacji:" "wp-rollback [strona]"
printf "  ${RED}%-30s${NC} %s\n" "Mało miejsca na dysku:" "backup-emergency"
printf "  ${RED}%-30s${NC} %s\n" "Błędy uprawnień:" "wp-fix-perms"
printf "  ${RED}%-30s${NC} %s\n" "Podejrzenie malware:" "clamav-deep-scan"
printf "  ${RED}%-30s${NC} %s\n" "Awaria synchronizacji NAS:" "nas-sync-status"
printf "  ${RED}%-30s${NC} %s\n" "WP-CLI nie działa:" "wp-cli-validator"
echo ""

# ============================================
# SEKCJA 9: LOGI
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📝 PLIKI LOGÓW (~/logs/wsms/)                              │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "logs-backup" "Podgląd logów backupów (na żywo)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-update" "Podgląd logów aktualizacji (na żywo)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-sync" "Podgląd logów synchronizacji NAS (na żywo)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-scan" "Podgląd logów skanowania malware"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-logs" "Pokaż status wszystkich plików logów"
echo ""

# ============================================
# SEKCJA 10: KOMENDY DLA STRON
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🎯 KOMENDY DLA POSZCZEGÓLNYCH STRON                        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-$name" "WP-CLI dla $name"
done
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-$name" "Szybki backup dla $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot-$name" "Migawka dla $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-$name" "Rollback dla $name"
    echo ""
done

# ============================================
# SEKCJA 11: INNE
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📦 INNE KOMENDY                                            │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "red-robin" "Awaryjny backup systemu"
printf "  ${GREEN}%-22s${NC} %s\n" "wsms-clean" "Wyczyść stare logi i pliki tymczasowe"
printf "  ${GREEN}%-22s${NC} %s\n" "scripts-dir" "Lista katalogu skryptów"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "Ten spis"
echo ""

# ============================================
# STOPKA
# ============================================
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.2 — GOTOWY DO PRACY${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}📚 Dokumentacja: ~/scripts/ │ 🐛 Zgłoś problem: github.com/maleclukas-prog${NC}"
echo -e "${WHITE}👤 Autor: Lukasz Malec${NC}"
echo ""