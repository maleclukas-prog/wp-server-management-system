#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - GŁÓWNY INSTALATOR (WERSJA POLSKA)
# Version: 4.2 (Pełna wersja produkcyjna)
# Opis: Kompletne automatyczne wdrożenie infrastruktury WSMS
# Autor: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

set -e

# =================================================================
# ⚙️ KONFIGURACJA INFRASTRUKTURY - EDYTUJ TYLKO TUTAJ!
# Format: "Identyfikator:ŚcieżkaDoPublic_html:UżytkownikSystemu"
# =================================================================
ZARZADZANE_STRONY=(
    "przyklad:/var/www/przyklad/public_html:wordpress_przyklad"
    "demo:/var/www/demo/public_html:wordpress_demo"
)

# Ustawienia Synology NAS (ZMIEŃ NA SWOJE)
NAS_HOST="twoj-nas.synology.me"
NAS_PORT="22"
NAS_USER="twoj_uzytkownik"
NAS_PATH="/homes/twoj_uzytkownik/server_backups"
NAS_SSH_KEY="$HOME/.ssh/klucz_nas"
# =================================================================

# Kolory
NIEBIESKI='\033[0;34m'; ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'
CYJAN='\033[0;36m'; CZERWONY='\033[0;31m'; NC='\033[0m'

echo -e "${CYJAN}==========================================================${NC}"
echo -e "${CYJAN}   WSMS PRO - INSTALATOR (WERSJA POLSKA v4.2)             ${NC}"
echo -e "${CYJAN}==========================================================${NC}"

# ==================== FAZA 1: INFRASTRUKTURA ====================
echo -e "\n${NIEBIESKI}📂 Faza 1: Tworzenie infrastruktury...${NC}"
KATALOGI=("$HOME/scripts" "$HOME/backups-lite" "$HOME/backups-full" 
          "$HOME/backups-manual" "$HOME/mysql-backups" "$HOME/logs" "$HOME/backups-rollback")
for kat in "${KATALOGI[@]}"; do
    mkdir -p "$kat" && echo -e "   ✅ $kat"
done

sudo mkdir -p /var/kwarantanna /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${ZIELONY}✅ Infrastruktura gotowa.${NC}"

# ==================== FAZA 2: ZALEŻNOŚCI ====================
echo -e "\n${NIEBIESKI}🔍 Faza 2: Instalowanie zależności...${NC}"
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon openssh-client bc curl rsync -qq
if ! command -v wp &> /dev/null; then
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi
echo -e "${ZIELONY}✅ Zależności zainstalowane.${NC}"

# ==================== FAZA 3: CENTRALNA KONFIGURACJA ====================
echo -e "\n${NIEBIESKI}📝 Faza 3: Generowanie centralnej konfiguracji...${NC}"
cat > "$HOME/scripts/wsms-config.sh" << EOF
#!/bin/bash
# =================================================================
# 🧠 WSMS GLOBALNA KONFIGURACJA - Wygenerowano: $(date)
# =================================================================

# Strony WordPress - Format: "nazwa:/ścieżka/do/public_html:użytkownik"
STRONY=(
$(for strona in "${ZARZADZANE_STRONY[@]}"; do echo "    \"$strona\""; done)
)

# Konfiguracja Synology NAS
NAS_HOST="$NAS_HOST"
NAS_PORT="$NAS_PORT"
NAS_USER="$NAS_USER"
NAS_PATH="$NAS_PATH"
NAS_SSH_KEY="$NAS_SSH_KEY"

# Czas przechowywania backupów (dni)
ZACHOWAJ_LITE=14
ZACHOWAJ_PELNE=35
ZACHOWAJ_MYSQL=7
ZACHOWAJ_ROLLBACK=30
NAS_ZACHOWAJ_DNI=120
NAS_MIN_KOPII=2

# Próg ostrzegania dysku
PROG_DYSKU=80

# Ścieżki
KATALOG_SCRIPT="\$HOME/scripts"
KATALOG_BACKUP_LITE="\$HOME/backups-lite"
KATALOG_BACKUP_PELNE="\$HOME/backups-full"
KATALOG_BACKUP_RECZNE="\$HOME/backups-manual"
KATALOG_BACKUP_MYSQL="\$HOME/mysql-backups"
KATALOG_BACKUP_ROLLBACK="\$HOME/backups-rollback"
KATALOG_LOGOW="\$HOME/logs"
KWARANTANNA="/var/kwarantanna"
CLAMAV_LOG="/var/log/clamav"

# Eksport zmiennych
export STRONY NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export ZACHOWAJ_LITE ZACHOWAJ_PELNE ZACHOWAJ_MYSQL ZACHOWAJ_ROLLBACK
export NAS_ZACHOWAJ_DNI NAS_MIN_KOPII PROG_DYSKU
export KATALOG_SCRIPT KATALOG_BACKUP_LITE KATALOG_BACKUP_PELNE KATALOG_BACKUP_RECZNE
export KATALOG_BACKUP_MYSQL KATALOG_BACKUP_ROLLBACK KATALOG_LOGOW
export KWARANTANNA CLAMAV_LOG
EOF

chmod +x "$HOME/scripts/wsms-config.sh"
echo -e "   ✅ Konfiguracja zapisana: ~/scripts/wsms-config.sh"
echo -e "   📋 Zarządzane strony: ${#ZARZADZANE_STRONY[@]}"

# ==================== FAZA 4: WDROŻENIE WSZYSTKICH SKRYPTÓW ====================
echo -e "\n${NIEBIESKI}📝 Faza 4: Wdrażanie modułów...${NC}"

wdroz() { echo -e "   📦 ${CYJAN}$1${NC}"; cat > "$HOME/scripts/$1"; chmod +x "$HOME/scripts/$1"; }

# 1. DIAGNOSTYKA SERWERA
wdroz "server-health-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; CZERWONY='\033[0;31m'
NIEBIESKI='\033[0;34m'; CYJAN='\033[0;36m'; NC='\033[0m'
clear
echo -e "${NIEBIESKI}🖥️  PANEL DIAGNOSTYKI SERWERA${NC}"
echo "=========================================================="
echo -e "⏰ Czas audytu: $(date)"
echo -e "💻 Serwer:      $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"
echo -e "\n${CYJAN}📈 OBCIĄŻENIE SYSTEMU:${NC}"
echo "   Rdzenie CPU:  $(nproc)"
echo "   Czas pracy:   $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Średnie obciążenie: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Pamięć RAM:   " && free -h | awk '/^Mem:/ {print $3 "/" $2 " użyte"}'
echo -e "\n${CYJAN}💾 STAN DYSKÓW:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v tmpfs | sed 's/^/   /'
echo -e "\n${CYJAN}🛠️  STATUS USŁUG:${NC}"
for u in nginx apache2 mysql mariadb ssh; do
    status=$(systemctl is-active "$u" 2>/dev/null || echo "nie zainstalowane")
    if [ "$status" = "active" ]; then
        echo -e "   ✅ $u: ${ZIELONY}Aktywna${NC}"
    elif [ "$status" != "nie zainstalowane" ]; then
        echo -e "   ❌ $u: ${CZERWONY}$status${NC}"
    fi
done
echo -e "\n${CYJAN}🌐 ZARZĄDZANE STRONY WORDPRESS:${NC}"
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "   ${ZOLTY}[ $nazwa ]${NC}"
    if [ -f "$sciezka/wp-config.php" ]; then
        wp_ver=$(sudo -u "$uzytkownik" wp --path="$sciezka" core version 2>/dev/null || echo "nieznana")
        id "$uzytkownik" &>/dev/null && echo -e "      - Status: ${ZIELONY}Aktywna${NC} | WP: v$wp_ver" || echo -e "      - Status: ${CZERWONY}Brak użytkownika!${NC}"
    else 
        echo -e "      - ${CZERWONY}KRYTYCZNY: Brak wp-config.php!${NC}"
    fi
done
echo -e "\n${CYJAN}💾 STATUS BACKUPÓW:${NC}"
razem=0
for kat in "$KATALOG_BACKUP_LITE" "$KATALOG_BACKUP_PELNE" "$KATALOG_BACKUP_MYSQL"; do
    if [ -d "$kat" ]; then
        liczba=$(find "$kat" -type f 2>/dev/null | wc -l)
        rozmiar=$(du -sh "$kat" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$kat"): $liczba plików ($rozmiar)"
        razem=$((razem + liczba))
    fi
done
uzycie_dysku=$(df /home 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$razem" -eq 0 ]; then
    echo -e "   ${CZERWONY}⚠️ ALERT: Brak backupów! Uruchom 'wp-backup-lite'${NC}"
fi
if [ -n "$uzycie_dysku" ] && [ "$uzycie_dysku" -ge 80 ]; then
    echo -e "   ${CZERWONY}⚠️ KRYTYCZNY: Użycie dysku na poziomie ${uzycie_dysku}%${NC}"
fi
echo -e "\n${ZIELONY}✅ DIAGNOSTYKA ZAKOŃCZONA${NC}"
EOF

# 2. MONITOR STATUSU FLOTY
wdroz "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; CYJAN='\033[0;36m'; CZERWONY='\033[0;31m'; NC='\033[0m'
echo -e "${CYJAN}📊 INWENTARYZACJA FLOTY WORDPRESS${NC}"
echo "=========================================================="
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    if [ -f "$sciezka/wp-config.php" ]; then
        wer=$(sudo -u "$uzytkownik" wp --path="$sciezka" core version 2>/dev/null || echo "nieznana")
        aktualizacje_wtyczek=$(sudo -u "$uzytkownik" wp --path="$sciezka" plugin list --update=available --format=count 2>/dev/null || echo "0")
        aktualizacje_motywow=$(sudo -u "$uzytkownik" wp --path="$sciezka" theme list --update=available --format=count 2>/dev/null || echo "0")
        razem_aktualizacji=$((aktualizacje_wtyczek + aktualizacje_motywow))
        kod_http=$(curl -s -o /dev/null -w "%{http_code}" "https://$nazwa" 2>/dev/null || echo "000")
        if [ "$kod_http" = "200" ] || [ "$kod_http" = "301" ] || [ "$kod_http" = "302" ]; then
            ikona="${ZIELONY}✅${NC}"
        else
            ikona="${CZERWONY}❌${NC}"
        fi
        echo -e "   $ikona $nazwa: Core v$wer | ${ZOLTY}Aktualizacje: $razem_aktualizacji${NC}"
    else
        echo -e "   ${CZERWONY}❌ $nazwa: Błąd środowiska w $sciezka${NC}"
    fi
done
echo ""
echo -e "${CYJAN}📸 SNAPSHOTY ROLLBACK:${NC}"
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    liczba=$(find "$KATALOG_BACKUP_ROLLBACK/$nazwa" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$liczba" -gt 0 ]; then
        najnowszy=$(ls -t "$KATALOG_BACKUP_ROLLBACK/$nazwa" 2>/dev/null | head -1)
        echo "   📁 $nazwa: $liczba snapshotów (Najnowszy: $najnowszy)"
    fi
done
EOF

# 3. POGŁĘBIONY AUDYT
wdroz "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYJAN='\033[0;36m'; ZOLTY='\033[1;33m'; ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; NC='\033[0m'
echo -e "${CYJAN}🔍 POGŁĘBIONY AUDYT INFRASTRUKTURY${NC}"
echo "=========================================================="
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "\n${ZOLTY}--- $nazwa ---${NC}"
    if [ -f "$sciezka/wp-config.php" ]; then
        echo -e "${CYJAN}📊 Baza danych:${NC}"
        sudo -u "$uzytkownik" wp --path="$sciezka" db check 2>/dev/null && echo "   ✅ Baza danych OK" || echo "   ⚠️ Problemy z bazą"
        echo -e "${CYJAN}📦 Wtyczki wymagające aktualizacji:${NC}"
        aktualizacje=$(sudo -u "$uzytkownik" wp --path="$sciezka" plugin list --update=available --format=table 2>/dev/null)
        if [ -n "$aktualizacje" ]; then echo "$aktualizacje"; else echo "   ✅ Wszystkie wtyczki aktualne"; fi
        echo -e "${CYJAN}🔒 Bezpieczeństwo:${NC}"
        uprawnienia=$(stat -c "%a" "$sciezka/wp-config.php" 2>/dev/null)
        if [ "$uprawnienia" = "640" ] || [ "$uprawnienia" = "600" ]; then
            echo "   ✅ Uprawnienia wp-config.php: $uprawnienia"
        else
            echo "   ⚠️ Uprawnienia wp-config.php: $uprawnienia (powinno być 640)"
        fi
    else
        echo -e "   ${CZERWONY}❌ Brak wp-config.php${NC}"
    fi
done
echo -e "\n${ZIELONY}✅ AUDYT ZAKOŃCZONY${NC}"
EOF

# 4. SILNIK KONSERWACJI
wdroz "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYJAN='\033[0;36m'; ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; ZOLTY='\033[1;33m'; NC='\033[0m'
echo -e "${CYJAN}🔄 SILNIK KONSERWACJI FLOTY URUCHOMIONY${NC}"
echo "=========================================================="
echo -e "⏰ Rozpoczęto: $(date)"
sukces=0; bledy=0
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "\n${ZOLTY}🔄 Przetwarzanie: $nazwa${NC}"
    if [ -f "$sciezka/wp-config.php" ]; then
        echo "   📸 Tworzenie snapshotu przed aktualizacją..."
        bash "$KATALOG_SCRIPT/wp-rollback.sh" snapshot "$nazwa" 2>/dev/null
        echo "   ⚙️ Aktualizacja core..."
        sudo -u "$uzytkownik" wp --path="$sciezka" core update --quiet 2>/dev/null
        echo "   ⚙️ Aktualizacja wtyczek..."
        sudo -u "$uzytkownik" wp --path="$sciezka" plugin update --all --quiet 2>/dev/null
        echo "   ⚙️ Aktualizacja bazy danych..."
        sudo -u "$uzytkownik" wp --path="$sciezka" core update-db --quiet 2>/dev/null
        echo "   ⚙️ Czyszczenie cache..."
        sudo -u "$uzytkownik" wp --path="$sciezka" cache flush --quiet 2>/dev/null
        kod_http=$(curl -s -o /dev/null -w "%{http_code}" "https://$nazwa" 2>/dev/null || echo "000")
        if [ "$kod_http" = "200" ] || [ "$kod_http" = "301" ] || [ "$kod_http" = "302" ]; then
            echo -e "   ${ZIELONY}✅ $nazwa zaktualizowana pomyślnie (HTTP $kod_http)${NC}"
            ((sukces++))
        else
            echo -e "   ${CZERWONY}❌ $nazwa może mieć problemy (HTTP $kod_http) - przywracanie...${NC}"
            bash "$KATALOG_SCRIPT/wp-rollback.sh" rollback "$nazwa" 2>/dev/null
            ((bledy++))
        fi
    else
        echo -e "   ${CZERWONY}❌ Brak wp-config.php${NC}"
        ((bledy++))
    fi
done
echo -e "\n${CYJAN}📊 PODSUMOWANIE:${NC}"
echo -e "   ${ZIELONY}✅ Udanych: $sukces${NC}"
echo -e "   ${CZERWONY}❌ Nieudanych: $bledy${NC}"
echo -e "${ZIELONY}✅ CYKL KONSERWACJI ZAKOŃCZONY${NC}"
EOF

# 5. ORKIESTRATOR UPRAWNIEŃ
wdroz "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
NIEBIESKI='\033[0;34m'; ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; NC='\033[0m'
echo -e "${NIEBIESKI}🔐 ORKIESTRATOR UPRAWNIEŃ BEZPIECZEŃSTWA${NC}"
echo "=========================================================="
SERWWEB=""
systemctl is-active --quiet nginx && SERWWEB="nginx"
systemctl is-active --quiet apache2 && SERWWEB="apache2"
[ -n "$SERWWEB" ] && { echo "⏸️ Zatrzymywanie $SERWWEB..."; sudo systemctl stop "$SERWWEB" 2>/dev/null || true; }
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "\n${ZOLTY}🔧 Naprawianie $nazwa (Użytkownik: $uzytkownik)${NC}"
    if [ -d "$sciezka" ]; then
        sudo chown -R "$uzytkownik":"$uzytkownik" "$sciezka" 2>/dev/null
        sudo find "$sciezka" -type d -exec chmod 755 {} \; 2>/dev/null
        sudo find "$sciezka" -type f -exec chmod 644 {} \; 2>/dev/null
        [ -f "$sciezka/wp-config.php" ] && sudo chmod 640 "$sciezka/wp-config.php" 2>/dev/null && echo "   ✅ wp-config.php zabezpieczony"
        command -v setfacl &>/dev/null && sudo setfacl -R -m "u:$USER:r-x" "$sciezka" 2>/dev/null && echo "   ✅ ACL ustawione"
        echo -e "   ${ZIELONY}✅ Uprawnienia naprawione${NC}"
    else
        echo -e "   ${ZOLTY}⚠️ Katalog nie znaleziony${NC}"
    fi
done
for kat in "$KATALOG_BACKUP_LITE" "$KATALOG_BACKUP_PELNE" "$KATALOG_BACKUP_MYSQL"; do
    [ -d "$kat" ] && sudo chown -R "$USER":"$USER" "$kat" 2>/dev/null && sudo chmod 755 "$kat" 2>/dev/null
done
[ -n "$SERWWEB" ] && { echo -e "\n▶️ Uruchamianie $SERWWEB..."; sudo systemctl start "$SERWWEB" 2>/dev/null || true; }
echo -e "\n${ZIELONY}✅ POLITYKI BEZPIECZEŃSTWA ZASTOSOWANE${NC}"
EOF

# 6. PEŁNY BACKUP
wdroz "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
NIEBIESKI='\033[0;34m'; ZIELONY='\033[0;32m'; NC='\033[0m'
echo -e "${NIEBIESKI}💾 PEŁNY BACKUP FLOTY${NC}"
echo "=========================================================="
echo -e "⏰ Rozpoczęto: $(date)"
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "\n📦 Backup $nazwa..."
    bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" "$nazwa" 2>/dev/null
    tar -czf "$KATALOG_BACKUP_PELNE/pelny-$nazwa-$TS.tar.gz" -C "$sciezka" . 2>/dev/null
    if [ -f "$KATALOG_BACKUP_PELNE/pelny-$nazwa-$TS.tar.gz" ]; then
        rozmiar=$(du -h "$KATALOG_BACKUP_PELNE/pelny-$nazwa-$TS.tar.gz" | cut -f1)
        echo -e "   ${ZIELONY}✅ Pełny backup utworzony: $rozmiar${NC}"
    else
        echo -e "   ${CZERWONY}❌ Nie udało się utworzyć backupu${NC}"
    fi
done
echo -e "\n🧹 Czyszczenie starych backupów (starsze niż $ZACHOWAJ_PELNE dni)..."
find "$KATALOG_BACKUP_PELNE" -name "*.tar.gz" -mtime "+$ZACHOWAJ_PELNE" -delete 2>/dev/null
echo -e "\n⏰ Zakończono: $(date)"
echo -e "${ZIELONY}✅ PEŁNY BACKUP ZAKOŃCZONY${NC}"
EOF

# 7. LEKKI BACKUP
wdroz "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
NIEBIESKI='\033[0;34m'; ZIELONY='\033[0;32m'; NC='\033[0m'
echo -e "${NIEBIESKI}⚡ LEKKI BACKUP ASSETÓW${NC}"
echo "=========================================================="
echo -e "⏰ Rozpoczęto: $(date)"
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo -e "\n📁 Archiwizacja $nazwa..."
    bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" "$nazwa" 2>/dev/null
    tar -czf "$KATALOG_BACKUP_LITE/lekki-$nazwa-$TS.tar.gz" -C "$sciezka" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php .htaccess 2>/dev/null
    if [ -f "$KATALOG_BACKUP_LITE/lekki-$nazwa-$TS.tar.gz" ]; then
        rozmiar=$(du -h "$KATALOG_BACKUP_LITE/lekki-$nazwa-$TS.tar.gz" | cut -f1)
        echo -e "   ${ZIELONY}✅ Lekki backup utworzony: $rozmiar${NC}"
    fi
done
echo -e "\n🧹 Czyszczenie starych backupów (starsze niż $ZACHOWAJ_LITE dni)..."
find "$KATALOG_BACKUP_LITE" -name "*.tar.gz" -mtime "+$ZACHOWAJ_LITE" -delete 2>/dev/null
echo -e "\n⏰ Zakończono: $(date)"
echo -e "${ZIELONY}✅ LEKKI BACKUP ZAKOŃCZONY${NC}"
EOF

# 8. MENEDŻER MYSQL
wdroz "mysql-backup-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
cel="${1:-all}"
ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; ZOLTY='\033[1;33m'; NC='\033[0m'
if [ "$cel" = "list" ]; then
    echo -e "${ZOLTY}📋 Dostępne backupy MySQL:${NC}"
    echo "=========================================================="
    for strona in "${STRONY[@]}"; do
        IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
        liczba=$(find "$KATALOG_BACKUP_MYSQL" -name "db-$nazwa-*.sql.gz" 2>/dev/null | wc -l)
        najnowszy=$(ls -t "$KATALOG_BACKUP_MYSQL"/db-$nazwa-*.sql.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null)
        echo "   📂 $nazwa: $liczba backupów (Najnowszy: ${najnowszy:-brak})"
    done
    exit 0
fi
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    if [[ "$cel" == "all" || "$cel" == "$nazwa" ]]; then
        if [ -f "$sciezka/wp-config.php" ]; then
            NAZWA_BAZY=$(grep -E "DB_NAME" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
            UZYTKOWNIK_BAZY=$(grep -E "DB_USER" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
            HASLO_BAZY=$(grep -E "DB_PASSWORD" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
            HOST_BAZY=$(grep -E "DB_HOST" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
            HOST_BAZY=${HOST_BAZY:-localhost}
            if mysqldump --single-transaction --quick -h "$HOST_BAZY" -u "$UZYTKOWNIK_BAZY" -p"$HASLO_BAZY" "$NAZWA_BAZY" 2>/dev/null | gzip > "$KATALOG_BACKUP_MYSQL/db-$nazwa-$TS.sql.gz"; then
                rozmiar=$(du -h "$KATALOG_BACKUP_MYSQL/db-$nazwa-$TS.sql.gz" | cut -f1)
                echo -e "   ${ZIELONY}✅ Backup bazy dla $nazwa: $rozmiar${NC}"
            else
                echo -e "   ${CZERWONY}❌ Nie udało się wykonać backupu bazy dla $nazwa${NC}"
            fi
        else
            echo -e "   ${ZOLTY}⚠️ Brak wp-config.php dla $nazwa${NC}"
        fi
    fi
done
find "$KATALOG_BACKUP_MYSQL" -name "*.sql.gz" -mtime "+$ZACHOWAJ_MYSQL" -delete 2>/dev/null
EOF

# 9. SYNCHRONIZACJA NAS (POLSKA)
wdroz "nas-sftp-sync.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; CZERWONY='\033[0;31m'; CYJAN='\033[0;36m'; NC='\033[0m'
echo ""
echo "=========================================================="
echo -e "${CYJAN}☁️ SYNCHRONIZACJA NAS - $(date)${NC}"
echo "=========================================================="
if [ ! -f "$NAS_SSH_KEY" ]; then
    echo -e "${CZERWONY}❌ Klucz SSH nie znaleziony: $NAS_SSH_KEY${NC}"
    exit 1
fi
sync_sukces=0; sync_fail=0
for modul in backups-lite backups-full backups-manual mysql-backups; do
    echo -e "\n${CYJAN}📤 Przetwarzanie: $modul${NC}"
    if [ ! -d "$HOME/$modul" ] || [ -z "$(ls -A "$HOME/$modul" 2>/dev/null)" ]; then
        echo -e "   ${ZOLTY}⚠️ Brak plików - pomijanie${NC}"
        continue
    fi
    echo -e "   📁 Znaleziono $(ls -1 "$HOME/$modul" | wc -l) plik(ów)"
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << EOF
mkdir -p $NAS_PATH/$modul
cd $NAS_PATH/$modul
lcd $HOME/$modul
mput *
bye
EOF
    then
        echo -e "   ${ZIELONY}✅ $modul zsynchronizowany${NC}"
        ((sync_sukces++))
    else
        echo -e "   ${CZERWONY}❌ $modul - BŁĄD synchronizacji${NC}"
        ((sync_fail++))
    fi
done
echo ""
echo "=========================================================="
echo -e "${CYJAN}📊 PODSUMOWANIE SYNCHRONIZACJI:${NC}"
echo -e "   ${ZIELONY}✅ Udane: $sync_sukces moduł(y)${NC}"
echo -e "   ${CZERWONY}❌ Nieudane: $sync_fail moduł(y)${NC}"
echo "=========================================================="
echo -e "${ZIELONY}✅ Synchronizacja NAS zakończona: $(date)${NC}"
echo ""
EOF

# 10. INTELIGENTNE ZARZĄDZANIE PRZECHOWYWANIEM
wdroz "wp-smart-retention-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; CZERWONY='\033[0;31m'; CYJAN='\033[0;36m'; NC='\033[0m'
pobierz_uzycie_dysku() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }
lista_backupow() {
    echo -e "${CYJAN}📋 WSZYSTKIE BACKUPY ZE SZCZEGÓŁAMI${NC}"
    echo "=========================================================="
    for kat in "$KATALOG_BACKUP_LITE" "$KATALOG_BACKUP_PELNE" "$KATALOG_BACKUP_MYSQL" "$KATALOG_BACKUP_ROLLBACK"; do
        if [ -d "$kat" ]; then
            echo -e "\n${ZOLTY}📂 $(basename "$kat"):${NC}"
            find "$kat" -type f 2>/dev/null | while read -r plik; do
                rozmiar=$(du -h "$plik" 2>/dev/null | cut -f1)
                data=$(stat -c "%y" "$plik" 2>/dev/null | cut -d' ' -f1)
                echo "   📁 $(basename "$plik") ($rozmiar, $data)"
            done
        fi
    done
}
pokaz_rozmiar() {
    echo -e "${CYJAN}💽 ZUŻYCIE MIEJSCA NA BACKUPY${NC}"
    echo "=========================================================="
    for kat in "$KATALOG_BACKUP_LITE" "$KATALOG_BACKUP_PELNE" "$KATALOG_BACKUP_MYSQL" "$KATALOG_BACKUP_ROLLBACK"; do
        if [ -d "$kat" ]; then
            rozmiar=$(du -sh "$kat" 2>/dev/null | cut -f1)
            liczba=$(find "$kat" -type f 2>/dev/null | wc -l)
            echo "   📂 $(basename "$kat"): $rozmiar ($liczba plików)"
        fi
    done
    uzycie_dysku=$(pobierz_uzycie_dysku)
    echo -e "\n   💿 Całkowite użycie dysku: ${uzycie_dysku}%"
    if [ "$uzycie_dysku" -ge "$PROG_DYSKU" ]; then
        echo -e "   ${CZERWONY}⚠️ OSTRZEŻENIE: Użycie dysku powyżej progu!${NC}"
    fi
}
wymuszone_czyszczenie() {
    uzycie=$(pobierz_uzycie_dysku)
    if [ "$uzycie" -ge "$PROG_DYSKU" ]; then
        echo -e "${ZOLTY}⚠️ Użycie dysku na poziomie ${uzycie}% - uruchamianie trybu awaryjnego${NC}"
        for kat in "$KATALOG_BACKUP_LITE" "$KATALOG_BACKUP_PELNE" "$KATALOG_BACKUP_MYSQL"; do
            if [ -d "$kat" ]; then
                for strona in "${STRONY[@]}"; do
                    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
                    pliki=$(find "$kat" -type f -name "*$nazwa*" 2>/dev/null | sort -r)
                    liczba=$(echo "$pliki" | grep -c . 2>/dev/null || echo 0)
                    if [ "$liczba" -gt 2 ]; then
                        echo "$pliki" | tail -n +3 | xargs rm -f 2>/dev/null
                        echo "   🗑️ $nazwa: Zachowano 2 najnowsze"
                    fi
                done
            fi
        done
    else
        echo -e "${ZIELONY}✅ Standardowe czyszczenie: Usuwanie plików starszych niż okres przechowywania${NC}"
        find "$KATALOG_BACKUP_LITE" -type f -mtime "+$ZACHOWAJ_LITE" -delete 2>/dev/null
        find "$KATALOG_BACKUP_PELNE" -type f -mtime "+$ZACHOWAJ_PELNE" -delete 2>/dev/null
        find "$KATALOG_BACKUP_MYSQL" -type f -mtime "+$ZACHOWAJ_MYSQL" -delete 2>/dev/null
        find "$KATALOG_BACKUP_ROLLBACK" -type d -mtime "+$ZACHOWAJ_ROLLBACK" -exec rm -rf {} \; 2>/dev/null
        echo "   🗑️ Czyszczenie zakończone"
    fi
}
case "${1:-}" in
    list|l) lista_backupow ;;
    size|s) pokaz_rozmiar ;;
    clean|c) wymuszone_czyszczenie ;;
    *) echo "Użycie: $0 {list|size|clean}" ;;
esac
EOF

# 11. SYSTEM POMOCY
wdroz "wp-help.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CZERWONY='\033[0;31m'; ZIELONY='\033[0;32m'; ZOLTY='\033[1;33m'; NIEBIESKI='\033[0;34m'; CYJAN='\033[0;36m'; BIALY='\033[1;37m'; NC='\033[0m'
clear
echo -e "${BIALY}🆘 WSMS PRO - POMOC I REFERENCJA${NC}"
echo -e "${BIALY}=================================================${NC}"
echo -e "${NIEBIESKI}⏰ $(date)${NC}"
echo -e "${NIEBIESKI}📋 Zarządzane strony: ${#STRONY[@]}${NC}\n"
echo -e "${CYJAN}⚡ SZYBKI START${NC}"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-status" "Pełny przegląd infrastruktury"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-help" "To menu pomocy"
printf "  ${ZIELONY}%-26s${NC} %s\n" "system-diag" "Diagnostyka serwera"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-fleet" "Status stron WordPress"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-update-all" "Aktualizacja wszystkich stron"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-fix-perms" "Naprawa uprawnień"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-backup-lite" "Lekki backup"
printf "  ${ZIELONY}%-26s${NC} %s\n" "wp-backup-full" "Pełny backup"
printf "  ${ZIELONY}%-26s${NC} %s\n" "nas-sync" "Synchronizacja z NAS"
printf "  ${ZIELONY}%-26s${NC} %s\n" "backup-clean" "Czyszczenie starych backupów"
echo -e "\n${CYJAN}📋 POLITYKA PRZECHOWYWANIA DANYCH${NC}"
echo -e "  ⚡ Lekkie backupy:   ${ZOLTY}$ZACHOWAJ_LITE dni${NC}"
echo -e "  💾 Pełne backupy:    ${ZOLTY}$ZACHOWAJ_PELNE dni${NC}"
echo -e "  🗄️ Backupy MySQL:    ${ZOLTY}$ZACHOWAJ_MYSQL dni${NC}"
echo -e "  🔄 Przechowywanie na NAS: ${ZOLTY}$NAS_ZACHOWAJ_DNI dni${NC}"
echo -e "\n${ZIELONY}✅ SYSTEM GOTOWY${NC}"
EOF

# 12. INTERAKTYWNE NARZĘDZIE BACKUPU
wdroz "wp-interactive-backup-tool.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
NIEBIESKI='\033[0;34m'; ZIELONY='\033[0;32m'; CYJAN='\033[0;36m'; NC='\033[0m'
echo -e "${NIEBIESKI}🎯 INTERAKTYWNE NARZĘDZIE BACKUPU${NC}"
echo "=========================================================="
echo -e "\n${CYJAN}Wybierz stronę do backupu:${NC}"
echo "   0) Wszystkie strony"
i=1; declare -A map_stron
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    echo "   $i) $nazwa"
    map_stron[$i]="$strona"
    ((i++))
done
echo "   q) Wyjście"
echo ""; read -p "Wybierz opcję: " wybor
if [ "$wybor" = "q" ] || [ "$wybor" = "Q" ]; then echo "Do widzenia!"; exit 0; fi
echo -e "\n${CYJAN}Wybierz typ backupu:${NC}"
echo "   1) Lekki backup (motywy, wtyczki, uploady, konfiguracja)"
echo "   2) Pełny backup (cała strona)"
echo "   3) Tylko baza danych"
echo "   4) Snapshot rollback"
echo "   q) Wyjście"
echo ""; read -p "Wybierz opcję: " typ_backupu
case $typ_backupu in
    1) [ "$wybor" = "0" ] && bash "$KATALOG_SCRIPT/wp-essential-assets-backup.sh" || { IFS=':' read -r nazwa sciezka uzytkownik <<< "${map_stron[$wybor]}"; echo "Uruchamianie lekkiego backupu dla $nazwa..."; bash "$KATALOG_SCRIPT/wp-essential-assets-backup.sh" "$nazwa"; } ;;
    2) [ "$wybor" = "0" ] && bash "$KATALOG_SCRIPT/wp-full-recovery-backup.sh" || { IFS=':' read -r nazwa sciezka uzytkownik <<< "${map_stron[$wybor]}"; echo "Uruchamianie pełnego backupu dla $nazwa..."; bash "$KATALOG_SCRIPT/wp-full-recovery-backup.sh" "$nazwa"; } ;;
    3) [ "$wybor" = "0" ] && bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" all || { IFS=':' read -r nazwa sciezka uzytkownik <<< "${map_stron[$wybor]}"; echo "Uruchamianie backupu bazy dla $nazwa..."; bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" "$nazwa"; } ;;
    4) [ "$wybor" = "0" ] && bash "$KATALOG_SCRIPT/wp-rollback.sh" snapshot all || { IFS=':' read -r nazwa sciezka uzytkownik <<< "${map_stron[$wybor]}"; echo "Tworzenie snapshotu rollback dla $nazwa..."; bash "$KATALOG_SCRIPT/wp-rollback.sh" snapshot "$nazwa"; } ;;
    q|Q) echo "Do widzenia!"; exit 0 ;;
    *) echo "Nieprawidłowy wybór" ;;
esac
echo -e "\n${ZIELONY}✅ Operacja backupu zakończona!${NC}"
EOF

# 13. SAMODZIELNY MYSQL
wdroz "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "⚙️ Samodzielny silnik MySQL: Wykonywanie globalnego dumpa"
bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" "all"
EOF

# 14. RED ROBIN
wdroz "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
WYJSCIE="$KATALOG_BACKUP_RECZNE/red-robin-sys-$TS.tar.gz"
ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; NC='\033[0m'
echo "🔴 AWARYJNY BACKUP SYSTEMU"
echo "=========================================================="
sudo tar -cpzf "$WYJSCIE" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="/tmp" --exclude="/run" --exclude="$HOME/backups-*" /etc /var/log /home 2>/dev/null
if [ -f "$WYJSCIE" ]; then
    rozmiar=$(du -h "$WYJSCIE" | cut -f1)
    echo -e "${ZIELONY}✅ Backup systemu utworzony: $WYJSCIE ($rozmiar)${NC}"
else
    echo -e "${CZERWONY}❌ Nie udało się utworzyć backupu systemu${NC}"
fi
EOF

# 15. CLAMAV AUTO SKAN
wdroz "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
LOG="/var/log/clamav/auto_scan.log"
sudo mkdir -p /var/log/clamav
echo "=== Skanowanie ClamAV - $(date) ===" | sudo tee -a $LOG
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a $LOG
echo "=== Skanowanie zakończone ===" | sudo tee -a $LOG
EOF

# 16. CLAMAV PEŁNE SKANOWANIE
wdroz "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
TS=$(date +%Y%m%d-%H%M%S)
LOG="/var/log/clamav/audyt_$TS.log"
KWARANTANNA="/var/kwarantanna"
echo "=== Pełne skanowanie systemu - $(date) ===" | sudo tee "$LOG"
sudo clamscan -r --infected --move="$KWARANTANNA" --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" / 2>&1 | sudo tee -a "$LOG"
echo "=== Skanowanie zakończone: $(date) ===" | sudo tee -a "$LOG"
zainfekowane=$(grep -c "FOUND" "$LOG" 2>/dev/null || echo "0")
echo "Znaleziono zainfekowanych plików: $zainfekowane" | sudo tee -a "$LOG"
EOF

# 17. WALIDATOR WP-CLI
wdroz "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; ZOLTY='\033[1;33m'; NC='\033[0m'
echo "🧪 WALIDACJA WP-CLI"
echo "=========================================================="
for strona in "${STRONY[@]}"; do
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"
    if [ ! -f "$sciezka/wp-config.php" ]; then
        echo -e "   ${CZERWONY}❌ $nazwa: Brak wp-config.php${NC}"
        continue
    fi
    if sudo -u "$uzytkownik" wp --path="$sciezka" core version &>/dev/null; then
        wersja=$(sudo -u "$uzytkownik" wp --path="$sciezka" core version 2>/dev/null)
        echo -e "   ${ZIELONY}✅ $nazwa: Połączono (WP v$wersja)${NC}"
    else
        echo -e "   ${CZERWONY}❌ $nazwa: Błąd połączenia WP-CLI${NC}"
    fi
done
echo -e "\n${ZOLTY}📋 Wersja WP-CLI:${NC}"
wp --version 2>/dev/null || echo "   ❌ WP-CLI nie znaleziony"
EOF

# 18. SILNIK ROLLBACK
wdroz "wp-rollback.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
ZIELONY='\033[0;32m'; CZERWONY='\033[0;31m'; ZOLTY='\033[1;33m'; CYJAN='\033[0;36m'; NC='\033[0m'
KATALOG_ROLLBACK="$KATALOG_BACKUP_ROLLBACK"; mkdir -p "$KATALOG_ROLLBACK"
pobierz_konfig_strony() { local cel=$1; for strona in "${STRONY[@]}"; do IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"; [ "$nazwa" = "$cel" ] && { echo "$strona"; return 0; }; done; return 1; }
utworz_snapshot() {
    local nazwa_strony=$1; local konfig=$(pobierz_konfig_strony "$nazwa_strony")
    [ -z "$konfig" ] && { echo -e "${CZERWONY}❌ Strona '$nazwa_strony' nie znaleziona${NC}"; return 1; }
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$konfig"; local timestamp=$(date +%Y%m%d_%H%M%S); local snapshot_path="$KATALOG_ROLLBACK/$nazwa/$timestamp"
    echo -e "${CYJAN}📸 Tworzenie snapshotu dla $nazwa...${NC}"; mkdir -p "$snapshot_path"
    echo "   📊 Backup bazy danych..."; bash "$KATALOG_SCRIPT/mysql-backup-manager.sh" "$nazwa" 2>/dev/null
    local najnowsza_baza=$(ls -t "$KATALOG_BACKUP_MYSQL/db-$nazwa-"*.sql.gz 2>/dev/null | head -1)
    [ -n "$najnowsza_baza" ] && cp "$najnowsza_baza" "$snapshot_path/" && echo "   ✅ Backup bazy wykonany"
    echo "   📁 Backup plików..."; tar -czf "$snapshot_path/files.tar.gz" -C "$sciezka" wp-content/plugins wp-content/themes wp-includes wp-admin 2>/dev/null
    echo -e "${ZIELONY}✅ Snapshot utworzony${NC}"
}
lista_snapshotow() {
    local nazwa_strony=$1
    if [ -n "$nazwa_strony" ]; then
        echo -e "${CYJAN}📸 Snapshoty dla $nazwa_strony:${NC}"
        [ -d "$KATALOG_ROLLBACK/$nazwa_strony" ] && for snapshot in $(ls -td "$KATALOG_ROLLBACK/$nazwa_strony"/*/ 2>/dev/null); do echo "  📁 $(basename "$snapshot") ($(du -sh "$snapshot" 2>/dev/null | cut -f1))"; done || echo "  Brak snapshotów"
    else
        echo -e "${CYJAN}📸 Wszystkie snapshoty rollback:${NC}"
        for strona in "${STRONY[@]}"; do IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"; liczba=$(find "$KATALOG_ROLLBACK/$nazwa" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l); [ "$liczba" -gt 0 ] && echo "  📂 $nazwa: $liczba snapshotów" || echo "  📂 $nazwa: Brak snapshotów"; done
    fi
}
wykonaj_rollback() {
    local nazwa_strony=$1; local nazwa_snapshotu=$2
    local konfig=$(pobierz_konfig_strony "$nazwa_strony"); [ -z "$konfig" ] && { echo -e "${CZERWONY}❌ Strona '$nazwa_strony' nie znaleziona${NC}"; return 1; }
    IFS=':' read -r nazwa sciezka uzytkownik <<< "$konfig"
    local snapshot_path; [ -n "$nazwa_snapshotu" ] && snapshot_path="$KATALOG_ROLLBACK/$nazwa/$nazwa_snapshotu" || snapshot_path=$(ls -td "$KATALOG_ROLLBACK/$nazwa"/*/ 2>/dev/null | head -1)
    [ ! -d "$snapshot_path" ] && { echo -e "${CZERWONY}❌ Nie znaleziono snapshotu${NC}"; return 1; }
    echo -e "${ZOLTY}🔄 Przywracanie $nazwa...${NC}"
    echo "   🔒 Włączanie trybu konserwacyjnego..."; sudo -u "$uzytkownik" wp --path="$sciezka" maintenance-mode activate 2>/dev/null
    echo "   📁 Przywracanie plików..."; [ -f "$snapshot_path/files.tar.gz" ] && tar -xzf "$snapshot_path/files.tar.gz" -C "$sciezka" 2>/dev/null && echo "   ✅ Pliki przywrócone"
    echo "   🗄️ Przywracanie bazy danych..."; local backup_bazy=$(ls "$snapshot_path"/db-*.sql.gz 2>/dev/null | head -1)
    if [ -f "$backup_bazy" ]; then
        NAZWA_BAZY=$(grep -E "DB_NAME" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
        UZYTKOWNIK_BAZY=$(grep -E "DB_USER" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
        HASLO_BAZY=$(grep -E "DB_PASSWORD" "$sciezka/wp-config.php" | awk -F"['\"]" '{print $4}')
        gunzip < "$backup_bazy" | mysql -u "$UZYTKOWNIK_BAZY" -p"$HASLO_BAZY" "$NAZWA_BAZY" 2>/dev/null && echo "   ✅ Baza danych przywrócona"
    fi
    echo "   🔓 Wyłączanie trybu konserwacyjnego..."; sudo -u "$uzytkownik" wp --path="$sciezka" maintenance-mode deactivate 2>/dev/null
    echo -e "${ZIELONY}✅ Przywracanie zakończone${NC}"
}
case "${1:-}" in
    snapshot) [ -z "$2" ] && { echo "Użycie: wp-rollback snapshot <strona|all>"; exit 1; }; [ "$2" = "all" ] && for strona in "${STRONY[@]}"; do IFS=':' read -r nazwa sciezka uzytkownik <<< "$strona"; utworz_snapshot "$nazwa"; echo ""; done || utworz_snapshot "$2" ;;
    rollback) [ -z "$2" ] && { echo "Użycie: wp-rollback rollback <strona> [snapshot]"; exit 1; }; wykonaj_rollback "$2" "$3" ;;
    list) lista_snapshotow "$2" ;;
    *) echo -e "${CYJAN}🔄 SILNIK ROLLBACK WSMS${NC}"; echo "Użycie: wp-rollback {snapshot|rollback|list} [strona]"; exit 1 ;;
esac
EOF

echo -e "${ZIELONY}✅ Wszystkie skrypty wdrożone.${NC}"

# ==================== FAZA 5: ALIASY ====================
echo -e "\n${NIEBIESKI}🔧 Faza 5: Konfigurowanie aliasów...${NC}"
sed -i '/# WSMS/d' ~/.bashrc 2>/dev/null
cat >> ~/.bashrc << 'BASH_EOF'
# ==================== ALIASY WSMS PRO ==================== # WSMS
export KATALOG_SCRIPT="$HOME/scripts"
alias wp-help="bash $KATALOG_SCRIPT/wp-help.sh"
alias help-wp="wp-help"
alias wp-status="system-diag && echo '' && wp-fleet && echo '' && backup-size"
alias system-diag="bash $KATALOG_SCRIPT/server-health-audit.sh"
alias wp-fleet="bash $KATALOG_SCRIPT/wp-fleet-status-monitor.sh"
alias wp-audit="bash $KATALOG_SCRIPT/wp-multi-instance-audit.sh"
alias wp-cli-validator="bash $KATALOG_SCRIPT/wp-cli-infrastructure-validator.sh"
alias scripts-dir="ls -la $KATALOG_SCRIPT"
alias wp-update-all="bash $KATALOG_SCRIPT/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all"
alias wp-fix-perms="bash $KATALOG_SCRIPT/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash $KATALOG_SCRIPT/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $KATALOG_SCRIPT/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash $KATALOG_SCRIPT/wp-interactive-backup-tool.sh"
alias red-robin="bash $KATALOG_SCRIPT/red-robin-system-backup.sh"
alias db-backup="bash $KATALOG_SCRIPT/mysql-backup-manager.sh"
alias db-backup-all="db-backup all"
alias db-backup-list="db-backup list"
alias backup-clean="bash $KATALOG_SCRIPT/wp-smart-retention-manager.sh clean"
alias backup-size="bash $KATALOG_SCRIPT/wp-smart-retention-manager.sh size"
alias backup-list="backup-size"
alias nas-sync="bash $KATALOG_SCRIPT/nas-sftp-sync.sh"
alias nas-sync-logs="tail -f $HOME/logs/nas_sync.log"
alias nas-sync-status="echo '📊 Ostatnia synchronizacja NAS:'; tail -20 $HOME/logs/nas_sync.log 2>/dev/null || echo 'Brak logów'"
alias clamav-scan="bash $KATALOG_SCRIPT/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $KATALOG_SCRIPT/clamav-full-scan.sh"
alias clamav-status="sudo systemctl status clamav-daemon --no-pager | head -15"
alias clamav-update="sudo freshclam"
alias clamav-logs="sudo tail -f /var/log/clamav/auto_scan.log"
alias clamav-quarantine="sudo ls -la /var/kwarantanna/"
alias clamav-clean-quarantine="sudo rm -rf /var/kwarantanna/* && echo '✅ Kwarantanna wyczyszczona'"
alias wp-snapshot="bash $KATALOG_SCRIPT/wp-rollback.sh snapshot"
alias wp-rollback="bash $KATALOG_SCRIPT/wp-rollback.sh rollback"
alias wp-snapshots="bash $KATALOG_SCRIPT/wp-rollback.sh list"
# Kompatybilność wsteczna
alias wp-list="wp-fleet"
alias wp-diagnoza="wp-audit"
alias wp-update="wp-update-all"
alias wp-fix-permissions="wp-fix-perms"
alias mysql-backup="db-backup"
alias mysql-backup-all="db-backup all"
alias mysql-backup-list="db-backup list"
alias backup-smart-clean="backup-clean"
alias sync-backup="nas-sync"
echo "✅ WSMS PRO - aliasy załadowane (bash)"
BASH_EOF

# Aliasy dla fish
mkdir -p ~/.config/fish
cat >> ~/.config/fish/config.fish << 'FISH_EOF'
# ==================== ALIASY WSMS PRO ==================== # WSMS
set -gx KATALOG_SCRIPT "$HOME/scripts"
alias wp-help="bash $KATALOG_SCRIPT/wp-help.sh"
alias wp-status="system-diag; and echo ''; and wp-fleet; and echo ''; and backup-size"
alias system-diag="bash $KATALOG_SCRIPT/server-health-audit.sh"
alias wp-fleet="bash $KATALOG_SCRIPT/wp-fleet-status-monitor.sh"
alias wp-audit="bash $KATALOG_SCRIPT/wp-multi-instance-audit.sh"
alias wp-update-all="bash $KATALOG_SCRIPT/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite; and sleep 5; and wp-update-all"
alias wp-fix-perms="bash $KATALOG_SCRIPT/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash $KATALOG_SCRIPT/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $KATALOG_SCRIPT/wp-full-recovery-backup.sh"
alias db-backup="bash $KATALOG_SCRIPT/mysql-backup-manager.sh"
alias backup-clean="bash $KATALOG_SCRIPT/wp-smart-retention-manager.sh clean"
alias backup-size="bash $KATALOG_SCRIPT/wp-smart-retention-manager.sh size"
alias nas-sync="bash $KATALOG_SCRIPT/nas-sftp-sync.sh"
alias clamav-scan="bash $KATALOG_SCRIPT/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $KATALOG_SCRIPT/clamav-full-scan.sh"
alias wp-snapshot="bash $KATALOG_SCRIPT/wp-rollback.sh snapshot"
alias wp-rollback="bash $KATALOG_SCRIPT/wp-rollback.sh rollback"
alias wp-snapshots="bash $KATALOG_SCRIPT/wp-rollback.sh list"
echo "✅ WSMS PRO - aliasy załadowane (fish)"
FISH_EOF

echo -e "${ZIELONY}✅ Aliasy skonfigurowane.${NC}"

# ==================== FAZA 6: CRONTAB ====================
echo -e "\n${NIEBIESKI}🗓️ Faza 6: Konfigurowanie harmonogramu...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
# --- AUTOMATYCZNY HARMONOGRAM WSMS PRO ---
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1 # WSMS
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas_sync.log 2>&1 # WSMS
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/bezpieczenstwo.log 2>&1 # WSMS
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh clean >> $HOME/logs/czyszczenie.log 2>&1 # WSMS
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/aktualizacje.log 2>&1 # WSMS
0 2 * * 0,3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lekki.log 2>&1 # WSMS
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-pelny.log 2>&1 # WSMS
") | crontab -
echo -e "${ZIELONY}✅ Harmonogram skonfigurowany.${NC}"

# ==================== PODSUMOWANIE KOŃCOWE ====================
echo -e "\n${ZIELONY}===========================================${NC}"
echo -e "${ZIELONY}✅ INSTALACJA WSMS PRO ZAKOŃCZONA!${NC}"
echo -e "${ZIELONY}===========================================${NC}"
echo -e "   📋 Zarządzane strony: ${#ZARZADZANE_STRONY[@]}"
echo -e "   🔧 Plik konfiguracyjny: ~/scripts/wsms-config.sh"
echo ""
echo -e "${ZOLTY}🚀 NASTĘPNE KROKI:${NC}"
echo -e "   1. ${CYJAN}source ~/.bashrc${NC} (lub otwórz nowy terminal dla fish)"
echo -e "   2. ${CYJAN}wp-status${NC} - Sprawdź wszystkie strony"
echo -e "   3. ${CYJAN}wp-help${NC} - Wyświetlenie pomocy"
echo -e "   4. ${CYJAN}wp-backup-lite${NC} - Test backupu"
echo ""
echo -e "${NIEBIESKI}💡 Edytuj ~/scripts/wsms-config.sh aby zaktualizować swoje strony i ustawienia NAS.${NC}"
INSTALL_PL_EOF

chmod +x ~/install_wsms_pl.sh
echo "✅ Polski instalator utworzony: ~/install_wsms_pl.sh"

# Uruchom polski instalator
~/install_wsms_pl.sh