#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.2 - UNIWERSALNY INSTALATOR
# Wersja: 4.2 | Działa w każdej powłoce (Bash, Fish, Zsh, Sh)
# Autor: Lukasz Malec / GitHub: maleclukas-prog
# Licencja: MIT
# Opis: Kompletny instalator WordPress Server Management System
# =================================================================

set -eE
trap 'echo -e "${RED}❌ Instalacja nie powiodła się w linii $LINENO${NC}"; exit 1' ERR

# Kolory
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; WHITE='\033[1;37m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.2 - UNIWERSALNY INSTALATOR               ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Działa w Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# Wykryj aktualną powłokę
CURRENT_SHELL=$(basename "$SHELL")
echo -e "${BLUE}📍 Wykryta powłoka: $CURRENT_SHELL${NC}"

# =================================================================
# ⚙️ KONFIGURACJA - EDYTUJ TYLKO TUTAJ!
# =================================================================
# Format: "nazwa_strony:/pelna/sciezka/do/public_html:uzytkownik_systemowy"
MANAGED_SITES=(
    "site1:/var/www/site1/public_html:wordpress_site1"
    "site2:/var/www/site2/public_html:wordpress_site2"
)

# Ustawienia Synology NAS (Zdalny magazyn backupów)
NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"
# =================================================================

# Funkcja walidacji
validate_config() {
    local errors=0
    
    echo -e "\n${CYAN}🔍 Faza 0: Walidacja konfiguracji...${NC}"
    
    if [ ${#MANAGED_SITES[@]} -eq 0 ]; then
        echo -e "   ${RED}❌ BŁĄD: Brak skonfigurowanych stron w MANAGED_SITES${NC}"
        ((errors++))
    fi
    
    for site in "${MANAGED_SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ -z "$name" ] || [ -z "$path" ] || [ -z "$user" ]; then
            echo -e "   ${RED}❌ BŁĄD: Nieprawidłowy format: '$site'${NC}"
            echo -e "      Oczekiwano: 'nazwa:/sciezka/do/strony:uzytkownik'"
            ((errors++))
        fi
        if ! id "$user" &>/dev/null; then
            echo -e "   ${YELLOW}⚠️  Ostrzeżenie: Użytkownik '$user' nie istnieje${NC}"
        fi
    done
    
    if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
        echo -e "   ${YELLOW}⚠️  Ostrzeżenie: NAS_HOST nie skonfigurowany${NC}"
    fi
    
    if [ -n "$NAS_SSH_KEY" ] && [ ! -f "$NAS_SSH_KEY" ]; then
        echo -e "   ${YELLOW}⚠️  Ostrzeżenie: Klucz SSH '$NAS_SSH_KEY' nie znaleziony${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}❌ Walidacja nie powiodła się ($errors błędów)${NC}"
        echo -e "${YELLOW}Edytuj tablicę MANAGED_SITES i ustawienia NAS na początku tego skryptu.${NC}"
        exit 1
    fi
    
    echo -e "   ${GREEN}✅ Konfiguracja zwalidowana pomyślnie${NC}"
}

validate_config

# ==================== FAZA 1: INFRASTRUKTURA ====================
echo -e "\n${BLUE}📂 Faza 1: Inicjalizacja katalogów...${NC}"

# Główne katalogi
DIRS=(
    "$HOME/scripts"
    "$HOME/backups-lite"
    "$HOME/backups-full"
    "$HOME/backups-manual"
    "$HOME/backups-rollback"
    "$HOME/mysql-backups"
)

# Zorganizowane katalogi logów
LOG_DIRS=(
    "$HOME/logs/wsms/backups"
    "$HOME/logs/wsms/maintenance"
    "$HOME/logs/wsms/security"
    "$HOME/logs/wsms/sync"
    "$HOME/logs/wsms/retention"
    "$HOME/logs/wsms/rollback"
    "$HOME/logs/wsms/system"
)

for dir in "${DIRS[@]}" "${LOG_DIRS[@]}"; do
    mkdir -p "$dir" && echo -e "   ✅ $dir"
done

# Katalogi systemowe (wymagają sudo)
sudo mkdir -p /var/quarantine /var/log/clamav 2>/dev/null || true
sudo chown "$USER":"$USER" /var/log/clamav 2>/dev/null || true
sudo chmod 755 /var/quarantine 2>/dev/null || true

echo -e "${GREEN}✅ Infrastruktura gotowa${NC}"

# ==================== FAZA 2: ZALEŻNOŚCI ====================
echo -e "\n${BLUE}📦 Faza 2: Instalacja zależności...${NC}"
sudo apt-get update -qq

PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
echo -e "   Instalacja: $PACKAGES"
sudo apt-get install -y $PACKAGES 2>/dev/null || true

# Instalacja WP-CLI jeśli brak
if ! command -v wp &> /dev/null; then
    echo -e "   📦 Instalacja WP-CLI..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
    echo -e "   ✅ WP-CLI zainstalowane"
fi

# Weryfikacja instalacji
echo -e "   ✅ Zależności zweryfikowane:"
echo -e "      - WP-CLI: $(wp --version 2>/dev/null | head -1 || echo 'zainstalowane')"
echo -e "      - ClamAV: $(clamscan --version 2>/dev/null | head -1 || echo 'zainstalowane')"
echo -e "${GREEN}✅ Zależności gotowe${NC}"

# ==================== FAZA 3: KONFIGURACJA CENTRALNA ====================
echo -e "\n${BLUE}📝 Faza 3: Generowanie konfiguracji centralnej...${NC}"

HOME_EXPANDED="$HOME"

cat > "$HOME/scripts/wsms-config.sh" << 'EOF'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - KONFIGURACJA CENTRALNA
# Wygenerowane przez instalator - NIE EDYTUJ RĘCZNIE
# =================================================================

# ==================== STRONY WORDPRESS ====================
SITES=(
    "ZMIEN_MNIE"
)

# ==================== USTAWIENIA NAS/SFTP ====================
NAS_HOST="ZMIEN_MNIE"
NAS_PORT="22"
NAS_USER="ZMIEN_MNIE"
NAS_PATH="ZMIEN_MNIE"
NAS_SSH_KEY="ZMIEN_MNIE"

# ==================== POLITYKI RETENCJI ====================
RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
RETENTION_ROLLBACK=7

# ==================== RETENCJA NAS ====================
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2

# ==================== PROGI SYSTEMOWE ====================
DISK_ALERT_THRESHOLD=80
ROLLBACK_MAX_SIZE_MB=500

# ==================== POWIADOMIENIA ====================
SLACK_WEBHOOK_URL=""
EMAIL_ALERT=""

# ==================== ŚCIEŻKI KATALOGÓW ====================
SCRIPT_DIR="$HOME/scripts"

# Katalogi backupów
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MANUAL_DIR="$HOME/backups-manual"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="$HOME/backups-rollback"

# Katalogi logów - ZORGANIZOWANA STRUKTURA
LOG_BASE_DIR="$HOME/logs/wsms"
LOG_BACKUPS_DIR="$LOG_BASE_DIR/backups"
LOG_MAINTENANCE_DIR="$LOG_BASE_DIR/maintenance"
LOG_SECURITY_DIR="$LOG_BASE_DIR/security"
LOG_SYNC_DIR="$LOG_BASE_DIR/sync"
LOG_RETENTION_DIR="$LOG_BASE_DIR/retention"
LOG_ROLLBACK_DIR="$LOG_BASE_DIR/rollback"
LOG_SYSTEM_DIR="$LOG_BASE_DIR/system"

# Konkretne pliki logów
LOG_LITE_BACKUP="$LOG_BACKUPS_DIR/lite.log"
LOG_FULL_BACKUP="$LOG_BACKUPS_DIR/full.log"
LOG_MYSQL_BACKUP="$LOG_BACKUPS_DIR/mysql.log"
LOG_UPDATES="$LOG_MAINTENANCE_DIR/updates.log"
LOG_PERMISSIONS="$LOG_MAINTENANCE_DIR/permissions.log"
LOG_CLAMAV_SCAN="$LOG_SECURITY_DIR/clamav-scan.log"
LOG_CLAMAV_FULL="$LOG_SECURITY_DIR/clamav-full.log"
LOG_CLAMAV_UPDATE="$LOG_SECURITY_DIR/clamav-update.log"
LOG_NAS_SYNC="$LOG_SYNC_DIR/nas-sync.log"
LOG_NAS_ERRORS="$LOG_SYNC_DIR/nas-errors.log"
LOG_RETENTION="$LOG_RETENTION_DIR/retention.log"
LOG_ROLLBACK_SNAPSHOT="$LOG_ROLLBACK_DIR/snapshots.log"
LOG_ROLLBACK_CLEAN="$LOG_ROLLBACK_DIR/rollback-clean.log"
LOG_SYSTEM_HEALTH="$LOG_SYSTEM_DIR/health.log"

# Ścieżki zewnętrzne
QUARANTINE_DIR="/var/quarantine"
CLAMAV_LOG_DIR="/var/log/clamav"

# Utwórz katalogi logów
mkdir -p "$LOG_BACKUPS_DIR" "$LOG_MAINTENANCE_DIR" "$LOG_SECURITY_DIR" \
         "$LOG_SYNC_DIR" "$LOG_RETENTION_DIR" "$LOG_ROLLBACK_DIR" "$LOG_SYSTEM_DIR"

# ==================== EKSPORTUJ WSZYSTKIE ZMIENNE ====================
export SITES NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL RETENTION_ROLLBACK
export NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES
export DISK_ALERT_THRESHOLD ROLLBACK_MAX_SIZE_MB
export SLACK_WEBHOOK_URL EMAIL_ALERT
export SCRIPT_DIR
export BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR BACKUP_ROLLBACK_DIR
export LOG_BASE_DIR LOG_BACKUPS_DIR LOG_MAINTENANCE_DIR LOG_SECURITY_DIR
export LOG_SYNC_DIR LOG_RETENTION_DIR LOG_ROLLBACK_DIR LOG_SYSTEM_DIR
export LOG_LITE_BACKUP LOG_FULL_BACKUP LOG_MYSQL_BACKUP LOG_UPDATES LOG_PERMISSIONS
export LOG_CLAMAV_SCAN LOG_CLAMAV_FULL LOG_CLAMAV_UPDATE
export LOG_NAS_SYNC LOG_NAS_ERRORS LOG_RETENTION LOG_ROLLBACK_SNAPSHOT LOG_ROLLBACK_CLEAN LOG_SYSTEM_HEALTH
export QUARANTINE_DIR CLAMAV_LOG_DIR
EOF

# Zamień placeholdery na rzeczywiste wartości
sed -i "s|SITES=.*|SITES=(\n$(for site in "${MANAGED_SITES[@]}"; do echo "    \"$site\""; done)\n)|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_HOST=\"ZMIEN_MNIE\"|NAS_HOST=\"$NAS_HOST\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_PORT=\"22\"|NAS_PORT=\"$NAS_PORT\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_USER=\"ZMIEN_MNIE\"|NAS_USER=\"$NAS_USER\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_PATH=\"ZMIEN_MNIE\"|NAS_PATH=\"$NAS_PATH\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_SSH_KEY=\"ZMIEN_MNIE\"|NAS_SSH_KEY=\"$NAS_SSH_KEY\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|\$HOME|$HOME|g" "$HOME/scripts/wsms-config.sh"

chmod +x "$HOME/scripts/wsms-config.sh"
source "$HOME/scripts/wsms-config.sh"
echo -e "${GREEN}✅ Konfiguracja wygenerowana${NC}"

# ==================== FAZA 4: WDROŻENIE SKRYPTÓW ====================
echo -e "\n${BLUE}📝 Faza 4: Wdrażanie 18 modułów operacyjnych...${NC}"

deploy() { 
    echo -e "   📦 ${CYAN}$1${NC}"
    cat > "$HOME/scripts/$1"
    chmod +x "$HOME/scripts/$1"
}

# -----------------------------------------------------------------
# SKRYPT 1: server-health-audit.sh
# -----------------------------------------------------------------
deploy "server-health-audit.sh" << 'EOFAUDIT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ROZSZERZONA DIAGNOSTYKA SYSTEMU
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS DIAGNOSTYKA SYSTEMU v4.2${NC}"
echo "=========================================================="
echo -e "⏰ Czas: $(date)"
echo -e "💻 Host: $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"

# ============================================
# OBCIĄŻENIE SYSTEMU
# ============================================
echo -e "\n${CYAN}📈 OBCIĄŻENIE SYSTEMU:${NC}"
echo "   Rdzenie CPU: $(nproc)"
echo "   Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Pamięć: " && free -h | awk '/^Mem:/ {print $3 "/" $2 " użyte (" $7 " dostępne)"}'

# ============================================
# PAMIĘĆ MASOWA
# ============================================
echo -e "\n${CYAN}💾 PAMIĘĆ MASOWA:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'

# ============================================
# SIECIÓWKA
# ============================================
echo -e "\n${CYAN}🌐 SIECIÓWKA:${NC}"
echo "   Główne IP: $(hostname -I | awk '{print $1}')"
echo "   Nasłuchujące usługi:"
ss -tulpn 2>/dev/null | grep -E ":(80|443|22|3306)" | head -5 | sed 's/^/   /'

# ============================================
# STATUS USŁUG
# ============================================
echo -e "\n${CYAN}🛠️  STATUS USŁUG:${NC}"

# Sprawdź Nginx
if systemctl is-active --quiet nginx; then
    echo -e "   ${GREEN}✅ Nginx: Aktywny${NC}"
elif systemctl list-unit-files | grep -q nginx; then
    echo -e "   ${RED}❌ Nginx: Zainstalowany ale ZATRZYMANY${NC}"
else
    echo -e "   ${YELLOW}⚠️ Nginx: Niezainstalowany${NC}"
fi

# Sprawdź Apache
if systemctl is-active --quiet apache2; then
    echo -e "   ${GREEN}✅ Apache2: Aktywny${NC}"
elif systemctl list-unit-files | grep -q apache2; then
    echo -e "   ${RED}❌ Apache2: Zainstalowany ale ZATRZYMANY${NC}"
else
    echo -e "   ${YELLOW}⚠️ Apache2: Niezainstalowany${NC}"
fi

# Sprawdź MySQL/MariaDB
if systemctl is-active --quiet mysql; then
    echo -e "   ${GREEN}✅ MySQL: Aktywny${NC}"
elif systemctl is-active --quiet mariadb; then
    echo -e "   ${GREEN}✅ MariaDB: Aktywny${NC}"
elif systemctl list-unit-files | grep -qE "mysql|mariadb"; then
    echo -e "   ${RED}❌ Baza danych: Zainstalowana ale ZATRZYMANA${NC}"
else
    echo -e "   ${YELLOW}⚠️ Baza danych: Niezainstalowana${NC}"
fi

# Sprawdź SSH
if systemctl is-active --quiet ssh; then
    echo -e "   ${GREEN}✅ SSH: Aktywny${NC}"
else
    echo -e "   ${RED}❌ SSH: Zatrzymany${NC}"
fi

# ============================================
# STATUS PHP-FPM
# ============================================
echo -e "\n${CYAN}🔌 STATUS PHP-FPM:${NC}"
PHP_VERSIONS=$(systemctl list-units --type=service --state=active --no-legend 2>/dev/null | grep -E 'php[0-9.]+-fpm.service' | awk '{print $1}' | sed 's/.service//')

if [ -n "$PHP_VERSIONS" ]; then
    echo -e "   ${GREEN}✅ Aktywne pule PHP-FPM:${NC}"
    for php in $PHP_VERSIONS; do
        echo "      📦 $php"
    done
    echo "   🔌 Aktywne sockety:"
    sudo ls -la /run/php/ 2>/dev/null | grep -E "\.sock$" | head -5 | sed 's/^/      /'
else
    echo -e "   ${RED}❌ Brak aktywnych pul PHP-FPM${NC}"
fi

# ============================================
# UŻYTKOWNICY PHP-FPM
# ============================================
echo -e "\n${CYAN}👥 UŻYTKOWNICY PHP-FPM:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if id "$user" &>/dev/null; then
        echo -e "   ${GREEN}✅${NC} $name: $user"
    else
        echo -e "   ${RED}❌${NC} $name: $user (brak)"
    fi
done

# ============================================
# DOSTĘPNOŚĆ DOMEN
# ============================================
echo -e "\n${CYAN}🔗 DOSTĘPNOŚĆ DOMEN:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "   ${GREEN}✅${NC} $name (HTTP $http_code)"
    else
        echo -e "   ${RED}❌${NC} $name (HTTP $http_code - nieosiągalna)"
    fi
done

# ============================================
# ZARZĄDZANE STRONY WORDPRESS
# ============================================
echo -e "\n${CYAN}🌐 ZARZĄDZANE STRONY WORDPRESS:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "nieznana")
        site_php=$(sudo -u "$user" wp --path="$path" eval "echo PHP_VERSION;" 2>/dev/null || echo "nieznane")
        db_name=$(sudo -u "$user" wp --path="$path" db query "SELECT DATABASE()" --skip-column-names 2>/dev/null || echo "nieznana")
        plugins_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        themes_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        
        echo "      Core: v$wp_ver | PHP: $site_php"
        echo "      Baza: $db_name"
        
        total_updates=$((plugins_updates + themes_updates))
        if [ "$total_updates" -gt 0 ]; then
            echo -e "      Aktualizacje: ${YELLOW}$total_updates oczekujących${NC} (Wtyczki: $plugins_updates, Motywy: $themes_updates)"
        else
            echo -e "      Aktualizacje: ${GREEN}Wszystko aktualne${NC}"
        fi
    else 
        echo -e "      ${RED}KRYTYCZNY: Brak konfiguracji${NC}"
    fi
done

# ============================================
# STATUS REPOZYTORIUM BACKUPÓW
# ============================================
echo -e "\n${CYAN}💾 STATUS REPOZYTORIUM BACKUPÓW:${NC}"
total_archives=0

for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count plików ($size)"
        total_archives=$((total_archives + count))
    fi
done

# ============================================
# DOSTĘPNE MIGAWKI ROLLBACK
# ============================================
echo -e "\n${CYAN}📸 DOSTĘPNE MIGAWKI ROLLBACK:${NC}"
snapshot_total=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count migawek (Ostatnia: $latest)"
        snapshot_total=$((snapshot_total + snapshot_count))
    fi
done
if [ "$snapshot_total" -eq 0 ]; then
    echo "   Brak migawek rollback"
fi

# ============================================
# REKOMENDACJE
# ============================================
echo -e "\n${YELLOW}🔔 REKOMENDACJE OPERACYJNE:${NC}"
echo "----------------------------------------------------------"

# Sprawdź Nginx/Apache
if ! systemctl is-active --quiet nginx && ! systemctl is-active --quiet apache2; then
    echo -e "   ${RED}⚠️ KRYTYCZNY: Żaden serwer WWW nie działa! Uruchom: sudo systemctl start nginx${NC}"
fi

# Sprawdź miejsce na dysku
disk_usage=$(df /home 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$disk_usage" ] && [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
    echo -e "   ⚠️  ${RED}KRYTYCZNY: Zajętość dysku ${disk_usage}% - uruchom backup-emergency!${NC}"
fi

# Sprawdź backupy
if [ "$total_archives" -eq 0 ]; then
    echo -e "   ⚠️  ${RED}ALARM: Brak backupów! Uruchom wp-backup-full${NC}"
fi

# Sprawdź migawki rollback
if [ "$snapshot_total" -eq 0 ]; then
    echo -e "   ℹ️  RADA: Brak migawek rollback. Uruchom 'wp-snapshot all' przed aktualizacjami${NC}"
fi

echo -e "\n${GREEN}✅ AUDYT INFRASTRUKTURY ZAKOŃCZONY${NC}"
EOFAUDIT

# -----------------------------------------------------------------
# SKRYPT 2: wp-fleet-status-monitor.sh
# -----------------------------------------------------------------
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MONITOR STATUSU FLOTY WORDPRESS
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 STATUS FLOTY WORDPRESS v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "nieznana")
        updates_plugins=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        updates_themes=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        total_updates=$((updates_plugins + updates_themes))
        
        # Sprawdzanie HTTP/HTTPS z ignorowaniem SSL i podążaniem za przekierowaniami
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
            status_icon="${GREEN}✅${NC}"
        else
            status_icon="${RED}❌ (HTTP $http_code)${NC}"
        fi
        
        echo -e "   $status_icon $name: Core v$ver | ${YELLOW}Aktualizacje: $total_updates${NC} (Wtyczki: $updates_plugins, Motywy: $updates_themes)"
    else
        echo -e "   ${RED}❌ $name: Błąd środowiska w $path${NC}"
    fi
done

echo ""
echo -e "${CYAN}📸 DOSTĘPNE MIGAWKI ROLLBACK:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count migawek (Ostatnia: $latest)"
    fi
done
EOFFLEET

# -----------------------------------------------------------------
# SKRYPT 3: wp-multi-instance-audit.sh
# -----------------------------------------------------------------
deploy "wp-multi-instance-audit.sh" << 'EOFAUDIT2'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - GŁĘBOKI AUDYT WIELU INSTANCJI
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 ROZPOCZĘCIE GŁĘBOKIEGO AUDYTU v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- Audyt dla: $name ---${NC}"
    
    if [ -f "$path/wp-config.php" ]; then
        echo -e "\n${CYAN}📊 Status bazy danych:${NC}"
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Baza OK" || echo "   ⚠️ Sprawdzenie bazy nie powiodło się"
        
        echo -e "\n${CYAN}📦 Wtyczki z aktualizacjami:${NC}"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=table 2>/dev/null)
        if [ -n "$updates" ]; then
            echo "$updates"
        else
            echo "   ${GREEN}✅ Wszystkie wtyczki aktualne${NC}"
        fi
        
        echo -e "\n${CYAN}🎨 Motywy z aktualizacjami:${NC}"
        theme_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=table 2>/dev/null)
        if [ -n "$theme_updates" ]; then
            echo "$theme_updates"
        else
            echo "   ${GREEN}✅ Wszystkie motywy aktualne${NC}"
        fi
        
        echo -e "\n${CYAN}🔒 Szybkie sprawdzenie bezpieczeństwa:${NC}"
        wp_config_perms=$(stat -c "%a" "$path/wp-config.php" 2>/dev/null)
        if [ "$wp_config_perms" = "640" ] || [ "$wp_config_perms" = "600" ]; then
            echo "   ${GREEN}✅ Uprawnienia wp-config.php: $wp_config_perms${NC}"
        else
            echo "   ${RED}⚠️ Uprawnienia wp-config.php: $wp_config_perms (powinno być 640)${NC}"
        fi
        
        if grep -q "WP_DEBUG.*true" "$path/wp-config.php" 2>/dev/null; then
            echo "   ${RED}⚠️ WP_DEBUG jest włączone (ryzyko bezpieczeństwa)${NC}"
        else
            echo "   ${GREEN}✅ WP_DEBUG wyłączone${NC}"
        fi
        
    else
        echo -e "   ${RED}❌ Brak konfiguracji w $path${NC}"
    fi
done

echo -e "\n${GREEN}✅ GŁĘBOKI AUDYT ZAKOŃCZONY${NC}"
EOFAUDIT2

# -----------------------------------------------------------------
# SKRYPT 4: wp-automated-maintenance-engine.sh
# -----------------------------------------------------------------
deploy "wp-automated-maintenance-engine.sh" << 'EOFMAINT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SILNIK UTRZYMANIA CAŁEJ FLOTY
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔄 SILNIK UTRZYMANIA v4.2 - $(date)"
echo "=========================================================="

success_count=0
fail_count=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Przetwarzanie: $name"
    
    if [ -f "$path/wp-config.php" ]; then
        echo "   📸 Tworzenie migawki przed aktualizacją..."
        bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null
        
        echo "   ⚙️ Aktualizacja rdzenia..."
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        
        echo "   ⚙️ Aktualizacja wtyczek..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Aktualizacja motywów..."
        sudo -u "$user" wp --path="$path" theme update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Aktualizacja bazy danych..."
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        
        echo "   ⚙️ Czyszczenie cache..."
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$name" 2>/dev/null || echo "000")
        if [ "$http_code" = "000" ]; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
        fi
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            echo -e "   ${GREEN}✅ $name zaktualizowana pomyślnie (HTTP $http_code)${NC}"
            ((success_count++))
        else
            echo -e "   ${RED}❌ $name może mieć problemy (HTTP $http_code) - przywracanie...${NC}"
            bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name" 2>/dev/null
            ((fail_count++))
        fi
    else
        echo -e "   ${RED}❌ Niepowodzenie: Brak konfiguracji w $path${NC}"
        ((fail_count++))
    fi
done

echo -e "\n${CYAN}📊 PODSUMOWANIE UTRZYMANIA:${NC}"
echo "   ✅ Sukces: $success_count stron(y)"
echo "   ❌ Niepowodzenie: $fail_count stron(y)"
echo "   ⏰ Zakończono: $(date)"
echo -e "${GREEN}✅ CYKL UTRZYMANIA ZAKOŃCZONY${NC}"
EOFMAINT

# -----------------------------------------------------------------
# SKRYPT 5: infrastructure-permission-orchestrator.sh
# -----------------------------------------------------------------
deploy "infrastructure-permission-orchestrator.sh" << 'EOFPERM'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ORKIESTRATOR UPRAWNIEŃ INFRASTRUKTURY
# =================================================================

source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

LOG_FILE="$LOG_PERMISSIONS"

# Funkcja do logowania i wyświetlania
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log "=========================================================="
log "🔐 NAPRAWA UPRAWNIEŃ - $(date)"
log "=========================================================="

# Zatrzymaj serwer WWW tymczasowo
WEB_SERVER=""
if systemctl is-active --quiet nginx; then
    WEB_SERVER="nginx"
elif systemctl is-active --quiet apache2; then
    WEB_SERVER="apache2"
fi

if [ -n "$WEB_SERVER" ]; then
    log "⏸️  Zatrzymywanie $WEB_SERVER..."
    sudo systemctl stop "$WEB_SERVER" 2>/dev/null || true
fi

naprawione=0
bledy=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    log ""
    log "${YELLOW}Naprawa uprawnień dla $name (Użytkownik: $user)${NC}"
    
    if [ -d "$path" ]; then
        # Właściciel
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        
        # Uprawnienia katalogów
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        
        # Uprawnienia plików
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        
        # Zabezpiecz wp-config.php
        if [ -f "$path/wp-config.php" ]; then
            sudo chmod 640 "$path/wp-config.php" 2>/dev/null
            log "   ✅ wp-config.php zabezpieczony (640)"
        fi
        
        # Zabezpiecz .htaccess
        if [ -f "$path/.htaccess" ]; then
            sudo chmod 644 "$path/.htaccess" 2>/dev/null
        fi
        
        # Ustaw ACL dla dostępu backupów jeśli dostępne
        if command -v setfacl &>/dev/null; then
            sudo setfacl -R -m "u:$USER:r-x" "$path" 2>/dev/null || true
            log "   ✅ ACL ustawione dla użytkownika $USER"
        fi
        
        log "   ${GREEN}✅ Uprawnienia $name naprawione${NC}"
        ((naprawione++))
    else
        log "   ${RED}❌ Katalog $path nie znaleziony${NC}"
        ((bledy++))
    fi
done

# Uruchom ponownie serwer WWW
if [ -n "$WEB_SERVER" ]; then
    log ""
    log "▶️  Uruchamianie $WEB_SERVER..."
    sudo systemctl start "$WEB_SERVER" 2>/dev/null || true
fi

log ""
log "${GREEN}==========================================================${NC}"
log "${GREEN}✅ NAPRAWIONO UPRAWNIEŃ: $naprawione stron(y)${NC}"
if [ $bledy -gt 0 ]; then
    log "${RED}❌ BŁĘDY: $bledy stron(y)${NC}"
fi
log "${GREEN}==========================================================${NC}"
EOFPERM

# -----------------------------------------------------------------
# SKRYPT 6: wp-full-recovery-backup.sh
# -----------------------------------------------------------------
deploy "wp-full-recovery-backup.sh" << 'EOFFULL'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - PEŁNY BACKUP ODTWORZENIOWY
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_FULL_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "💾 PEŁNY BACKUP v4.2 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📦 Tworzenie migawki $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    
    if [ -f "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Pełny backup utworzony: $size${NC}"
    else
        echo "   ❌ Nie udało się utworzyć pełnego backupu"
    fi
done

echo -e "\n🧹 Czyszczenie starych backupów (starsze niż $RETENTION_FULL dni)..."
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime "+$RETENTION_FULL" -delete 2>/dev/null

echo -e "\n⏰ Zakończono: $(date)"
echo -e "${GREEN}✅ CYKL PEŁNEGO BACKUPU ZAKOŃCZONY${NC}"
EOFFULL

# -----------------------------------------------------------------
# SKRYPT 7: wp-essential-assets-backup.sh
# -----------------------------------------------------------------
deploy "wp-essential-assets-backup.sh" << 'EOFLITE'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - BACKUP NIEZBĘDNYCH ZASOBÓW (LITE)
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_LITE_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "⚡ SZYBKI BACKUP v4.2 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📁 Archiwizacja zasobów $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php .htaccess 2>/dev/null
    
    if [ -f "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Szybki backup utworzony: $size${NC}"
    fi
done

echo -e "\n🧹 Czyszczenie starych szybkich backupów (starsze niż $RETENTION_LITE dni)..."
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime "+$RETENTION_LITE" -delete 2>/dev/null

echo -e "\n⏰ Zakończono: $(date)"
echo -e "${GREEN}✅ CYKL SZYBKIEGO BACKUPU ZAKOŃCZONY${NC}"
EOFLITE

# -----------------------------------------------------------------
# SKRYPT 8: mysql-backup-manager.sh
# -----------------------------------------------------------------
deploy "mysql-backup-manager.sh" << 'EOFMYSQL'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MENEDŻER BACKUPÓW MYSQL
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_MYSQL_BACKUP"
exec >> "$LOG_FILE" 2>&1

if [ "$target" = "list" ]; then
    echo -e "${YELLOW}📋 Dostępne backupy MySQL:${NC}"
    echo "=========================================================="
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        count=$(find "$BACKUP_MYSQL_DIR" -name "db-$name-*.sql.gz" 2>/dev/null | wc -l)
        latest=$(ls -t "$BACKUP_MYSQL_DIR"/db-$name-*.sql.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null)
        echo "   📂 $name: $count backupów (Ostatni: ${latest:-brak})"
    done
    exit 0
fi

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [[ "$target" == "all" || "$target" == "$name" ]]; then
        if [ -f "$path/wp-config.php" ]; then
            DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=${DB_HOST:-localhost}
            
            if mysqldump --single-transaction --quick -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz"; then
                size=$(du -h "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz" | cut -f1)
                echo "   ${GREEN}✅ Backup bazy dla $name: $size${NC}"
            else
                echo "   ${RED}❌ Nie udało się zbackupować bazy dla $name${NC}"
            fi
        else
            echo "   ${YELLOW}⚠️ Nie znaleziono wp-config.php dla $name${NC}"
        fi
    fi
done

find "$BACKUP_MYSQL_DIR" -name "*.sql.gz" -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
EOFMYSQL

# -----------------------------------------------------------------
# SKRYPT 9: nas-sftp-sync.sh
# -----------------------------------------------------------------
deploy "nas-sftp-sync.sh" << 'EOFNAS'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SYNCHRONIZACJA NAS SFTP
# =================================================================

source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_NAS_SYNC"
ERROR_LOG="$LOG_NAS_ERRORS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "☁️ SYNCHRONIZACJA NAS - $(date)"
echo "=========================================================="

if [ ! -f "$NAS_SSH_KEY" ]; then
    echo "❌ BŁĄD: Nie znaleziono klucza SSH w $NAS_SSH_KEY"
    echo "$(date): Brak klucza SSH" >> "$ERROR_LOG"
    exit 1
fi

if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
    echo "⚠️ OSTRZEŻENIE: NAS_HOST nie skonfigurowany - synchronizacja pominięta"
    exit 0
fi

sync_success=0
sync_fail=0

for module in backups-lite backups-full mysql-backups; do
    echo -e "\n📤 Przetwarzanie $module..."
    
    if [ ! -d "$HOME/$module" ] || [ -z "$(ls -A "$HOME/$module" 2>/dev/null)" ]; then
        echo "   ⚠️ Brak plików w $module - pomijanie"
        continue
    fi
    
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
mkdir -p $NAS_PATH/$module
put $HOME/$module/* $NAS_PATH/$module/
bye
SFTP_EOF
    then
        echo "   ✅ $module zsynchronizowany pomyślnie"
        ((sync_success++))
    else
        echo "   ❌ Synchronizacja $module NIEUDANA"
        echo "$(date): Nie udało się zsynchronizować $module" >> "$ERROR_LOG"
        ((sync_fail++))
    fi
done

echo -e "\n📊 PODSUMOWANIE SYNCHRONIZACJI:"
echo "   ✅ Sukces: $sync_success modułów"
echo "   ❌ Niepowodzenie: $sync_fail modułów"

echo "=========================================================="
echo "--- Synchronizacja NAS zakończona: $(date) ---"
echo "=========================================================="
EOFNAS

# -----------------------------------------------------------------
# SKRYPT 10: wp-smart-retention-manager.sh
# -----------------------------------------------------------------
deploy "wp-smart-retention-manager.sh" << 'EOFRET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - INTELIGENTNY MENEDŻER RETENCJI
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
exec >> "$LOG_FILE" 2>&1

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 WSZYSTKIE BACKUPY ZE SZCZEGÓŁAMI v4.2${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n${YELLOW}📂 $(basename "$dir"):${NC}"
            find "$dir" -type f 2>/dev/null | while read -r file; do
                size=$(du -h "$file" 2>/dev/null | cut -f1)
                date_str=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1)
                echo "   📁 $(basename "$file") ($size, $date_str)"
            done
        fi
    done
}

show_size() {
    echo -e "${CYAN}💽 WYKORZYSTANIE MIEJSCA NA BACKUPY v4.2${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        if [ -d "$dir" ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "   📂 $(basename "$dir"): $size ($count plików)"
        fi
    done
    
    disk_usage=$(get_disk_usage)
    echo -e "\n   💿 Całkowite wykorzystanie dysku: ${disk_usage}%"
    
    if [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "   ${RED}⚠️ OSTRZEŻENIE: Wykorzystanie dysku powyżej progu ($DISK_ALERT_THRESHOLD%)!${NC}"
        echo -e "   ${YELLOW}💡 Uruchom 'backup-emergency' aby pilnie zwolnić miejsce${NC}"
    fi
}

show_dirs() {
    echo -e "${CYAN}📁 STRUKTURA KATALOGÓW BACKUPÓW${NC}"
    echo "=========================================================="
    ls -la "$HOME"/backups-* "$HOME"/mysql-backups 2>/dev/null
}

emergency_cleanup() {
    echo -e "${RED}🚨 TRYB AWARYJNY: Zachowywanie tylko 2 najnowszych kopii na stronę!${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n📂 Przetwarzanie $(basename "$dir")..."
            
            for site in "${SITES[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                
                files=$(find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r)
                count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
                
                if [ "$count" -gt 2 ]; then
                    echo "$files" | tail -n +3 | xargs rm -f 2>/dev/null
                    deleted=$((count - 2))
                    echo "   🗑️ $name: Zachowano 2 najnowsze, usunięto $deleted"
                fi
            done
        fi
    done
    
    echo -e "\n${GREEN}✅ AWARYJNE CZYSZCZENIE ZAKOŃCZONE${NC}"
}

force_clean() {
    usage=$(get_disk_usage)
    
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "${YELLOW}⚠️ Wykorzystanie dysku ${usage}% - aktywacja trybu awaryjnego${NC}"
        emergency_cleanup
    else
        echo -e "${GREEN}✅ Standardowe czyszczenie: Usuwanie plików starszych niż okres retencji${NC}"
        echo "=========================================================="
        
        find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null
        echo "   🗑️ Szybkie backupy: Usunięto pliki starsze niż $RETENTION_LITE dni"
        
        find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null
        echo "   🗑️ Pełne backupy: Usunięto pliki starsze niż $RETENTION_FULL dni"
        
        find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
        echo "   🗑️ Backupy MySQL: Usunięto pliki starsze niż $RETENTION_MYSQL dni"
        
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null
        echo "   🗑️ Migawki rollback: Usunięto starsze niż $RETENTION_ROLLBACK dni"
    fi
}

interactive_clean() {
    echo -e "${CYAN}🧹 TRYB INTERAKTYWNEGO CZYSZCZENIA${NC}"
    echo "=========================================================="
    show_size
    echo ""
    echo -e "${YELLOW}Co chcesz wyczyścić?${NC}"
    echo "   1) Szybkie backupy (starsze niż $RETENTION_LITE dni)"
    echo "   2) Pełne backupy (starsze niż $RETENTION_FULL dni)"
    echo "   3) Backupy MySQL (starsze niż $RETENTION_MYSQL dni)"
    echo "   4) Migawki rollback (starsze niż $RETENTION_ROLLBACK dni)"
    echo "   5) WSZYSTKO (standardowa retencja)"
    echo "   6) AWARYJNE (zachowaj tylko 2 najnowsze)"
    echo "   0) Anuluj"
    echo ""
    read -p "Wprowadź wybór [0-6]: " choice
    
    case $choice in
        1) find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null && echo "✅ Szybkie backupy wyczyszczone" ;;
        2) find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null && echo "✅ Pełne backupy wyczyszczone" ;;
        3) find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null && echo "✅ Backupy MySQL wyczyszczone" ;;
        4) find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null && echo "✅ Migawki rollback wyczyszczone" ;;
        5) force_clean ;;
        6) emergency_cleanup ;;
        0) echo "Anulowano." ;;
        *) echo "Nieprawidłowy wybór." ;;
    esac
}

case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    dirs|d) show_dirs ;;
    clean|c) interactive_clean ;;
    force-clean|force|f) force_clean ;;
    emergency|e) emergency_cleanup ;;
    *) 
        echo "Użycie: $0 {list|size|dirs|clean|force-clean|emergency}"
        echo ""
        echo "Komendy:"
        echo "  list, l        - Lista wszystkich backupów ze szczegółami"
        echo "  size, s        - Pokaż wykorzystanie miejsca na katalog"
        echo "  dirs, d        - Pokaż strukturę katalogów"
        echo "  clean, c       - Interaktywne czyszczenie"
        echo "  force-clean, f - Automatyczne czyszczenie wg retencji"
        echo "  emergency, e   - Zachowaj tylko 2 najnowsze kopie na stronę"
        ;;
esac
EOFRET

# -----------------------------------------------------------------
# SKRYPT 11: wp-help.sh
# -----------------------------------------------------------------
deploy "wp-help.sh" << 'EOFHELP'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - PEŁNY SPIS KOMEND
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

echo -e "${CYAN}▶ SZYBKI START - Najważniejsze komendy${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Pełny przegląd: sprzęt + WordPress + backupy"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "Wersje WordPress i dostępne aktualizacje"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Bezpieczna aktualizacja (Backup → Migawka → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Utwórz migawki rollback dla wszystkich stron"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [strona]" "Przywróć stronę do ostatniej migawki"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "Ten dokument"
echo ""

echo -e "${CYAN}▶ 🔄 SYSTEM ROLLBACK - NOWOŚĆ w v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot all" "Utwórz migawki dla WSZYSTKICH stron"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot [strona]" "Utwórz migawkę dla konkretnej strony"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots" "Lista wszystkich dostępnych migawek"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [strona]" "Przywróć do NAJNOWSZEJ migawki"
echo ""

echo -e "${CYAN}▶ 💾 ZARZĄDZANIE BACKUPAMI${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-lite" "Szybki backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-full" "Pełny backup całej strony"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-list" "Lista wszystkich backupów ze szczegółami"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-size" "Wykorzystanie miejsca na backupy"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-emergency" "AWARYJNE: zachowaj tylko 2 najnowsze kopie"
echo ""

echo -e "${CYAN}▶ 🔧 UTRZYMANIE I BEZPIECZEŃSTWO${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update-all" "Aktualizuj wszystkie strony"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-perms" "Napraw uprawnienia plików i ACL"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-all" "Backup wszystkich baz WordPress"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync" "Synchronizuj backupy na zdalny NAS"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-scan" "Codzienne skanowanie malware"
echo ""

echo -e "${CYAN}▶ 📝 PLIKI LOGÓW (~/logs/wsms/)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "backups/lite.log" "Szybkie backupy"
printf "  ${GREEN}%-26s${NC} %s\n" "backups/full.log" "Pełne backupy"
printf "  ${GREEN}%-26s${NC} %s\n" "maintenance/updates.log" "Aktualizacje WordPress"
printf "  ${GREEN}%-26s${NC} %s\n" "sync/nas-sync.log" "Synchronizacja NAS"
echo ""

echo -e "${CYAN}▶ 🚨 PROCEDURY AWARYJNE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${RED}%-32s${NC} %s\n" "Strona nie działa po aktualizacji:" "wp-rollback [nazwa-strony]"
printf "  ${RED}%-32s${NC} %s\n" "Mało miejsca na dysku:" "backup-emergency"
printf "  ${RED}%-32s${NC} %s\n" "Błędy uprawnień:" "wp-fix-perms"
printf "  ${RED}%-32s${NC} %s\n" "Podejrzenie malware:" "clamav-deep-scan"
echo ""

echo -e "${GREEN}✅ WSMS PRO v4.2 - GOTOWY DO PRACY${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}👤 Autor:${NC} Lukasz Malec"
EOFHELP

# -----------------------------------------------------------------
# SKRYPT 12: wp-interactive-backup-tool.sh
# -----------------------------------------------------------------
deploy "wp-interactive-backup-tool.sh" << 'EOFINTER'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🎯 INTERAKTYWNY BACKUP"
echo "0) Wszystkie strony"
i=1; declare -A site_map
for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; echo "$i) $name"; site_map[$i]="$site"; ((i++)); done
read -p "Wybór: " choice
[[ "$choice" == "0" ]] && bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" && exit
IFS=':' read -r name path user <<< "${site_map[$choice]}"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"
echo "✅ Backup zakończony"
EOFINTER

# -----------------------------------------------------------------
# SKRYPT 13: standalone-mysql-backup-engine.sh
# -----------------------------------------------------------------
deploy "standalone-mysql-backup-engine.sh" << 'EOFSTAND'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOFSTAND

# -----------------------------------------------------------------
# SKRYPT 14: red-robin-system-backup.sh
# -----------------------------------------------------------------
deploy "red-robin-system-backup.sh" << 'EOFROBIN'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="$HOME/backups-"* /etc /var/log /home 2>/dev/null
echo "✅ Backup systemu: $OUT"
EOFROBIN

# -----------------------------------------------------------------
# SKRYPT 15: clamav-auto-scan.sh
# -----------------------------------------------------------------
deploy "clamav-auto-scan.sh" << 'EOFCLAM'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_CLAMAV_SCAN"
echo "--- Skanowanie: $(date) ---" | sudo tee -a "$LOG_FILE"
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a "$LOG_FILE"
EOFCLAM

# -----------------------------------------------------------------
# SKRYPT 16: clamav-full-scan.sh
# -----------------------------------------------------------------
deploy "clamav-full-scan.sh" << 'EOFFULLCLAM'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_CLAMAV_FULL"
sudo clamscan -r --infected --move="$QUARANTINE_DIR" --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee "$LOG_FILE"
echo "✅ Pełne skanowanie zakończone"
EOFFULLCLAM

# -----------------------------------------------------------------
# SKRYPT 17: wp-cli-infrastructure-validator.sh
# -----------------------------------------------------------------
deploy "wp-cli-infrastructure-validator.sh" << 'EOFCLI'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🧪 WALIDACJA WP-CLI"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    sudo -u "$user" wp --path="$path" core version &>/dev/null && echo "✅ $name" || echo "❌ $name"
done
EOFCLI

# -----------------------------------------------------------------
# SKRYPT 18: wp-rollback.sh
# -----------------------------------------------------------------
deploy "wp-rollback.sh" << 'EOFROLLBACK'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SILNIK ROLLBACK
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

ROLLBACK_DIR="$BACKUP_ROLLBACK_DIR"
mkdir -p "$ROLLBACK_DIR"

get_site_config() {
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        [ "$name" = "$1" ] && echo "$site" && return 0
    done
    return 1
}

create_snapshot() {
    local site_config=$(get_site_config "$1")
    [ -z "$site_config" ] && { echo "Strona nie znaleziona"; return 1; }
    IFS=':' read -r name path user <<< "$site_config"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_path="$ROLLBACK_DIR/$name/$timestamp"
    mkdir -p "$snapshot_path"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    cp "$BACKUP_MYSQL_DIR/db-$name-"*.sql.gz "$snapshot_path/" 2>/dev/null
    tar -czf "$snapshot_path/files.tar.gz" -C "$path" wp-content/plugins wp-content/themes wp-includes wp-admin 2>/dev/null
    echo -e "${GREEN}✅ Migawka: $snapshot_path${NC}"
}

list_snapshots() {
    echo -e "${CYAN}📸 Migawki dla $1:${NC}"
    [ -d "$ROLLBACK_DIR/$1" ] && ls -td "$ROLLBACK_DIR/$1"/*/ 2>/dev/null | while read s; do echo "  📁 $(basename "$s")"; done
}

perform_rollback() {
    local site_config=$(get_site_config "$1")
    IFS=':' read -r name path user <<< "$site_config"
    local snapshot_path=$(ls -td "$ROLLBACK_DIR/$name"/*/ 2>/dev/null | head -1)
    [ ! -d "$snapshot_path" ] && { echo "Brak migawki"; return 1; }
    echo -e "${YELLOW}🔄 Przywracanie $name...${NC}"
    sudo -u "$user" wp --path="$path" maintenance-mode activate 2>/dev/null
    tar -xzf "$snapshot_path/files.tar.gz" -C "$path" 2>/dev/null
    local db_backup=$(ls "$snapshot_path"/db-*.sql.gz 2>/dev/null | head -1)
    if [ -f "$db_backup" ]; then
        DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_HOST=${DB_HOST:-localhost}
        gunzip < "$db_backup" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null
    fi
    sudo -u "$user" wp --path="$path" maintenance-mode deactivate 2>/dev/null
    echo -e "${GREEN}✅ Przywracanie zakończone${NC}"
}

case "${1:-}" in
    snapshot) [ "$2" = "all" ] && for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; create_snapshot "$name"; done || create_snapshot "$2" ;;
    rollback) perform_rollback "$2" ;;
    list) list_snapshots "$2" ;;
    clean) find "$ROLLBACK_DIR" -type d -mtime +$RETENTION_ROLLBACK -exec rm -rf {} \; 2>/dev/null; echo "✅ Wyczyszczono" ;;
    *) echo "Użycie: wp-rollback {snapshot|rollback|list|clean} [strona]" ;;
esac
EOFROLLBACK

echo -e "${GREEN}✅ Wszystkie 18 modułów wdrożonych${NC}"

# ==================== FAZA 5: ALIASY ====================
echo -e "\n${BLUE}🔧 Faza 5: Instalacja aliasów powłoki...${NC}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.bashrc" 2>/dev/null
    cat >> "$HOME/.bashrc" << 'EOFALIAS'

# ============================================
# WSMS PRO v4.2 - ALIASY
# ============================================
export SCRIPTS_DIR="$HOME/scripts"
alias wp-status='bash $SCRIPTS_DIR/server-health-audit.sh'
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-update='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
EOFALIAS
    echo -e "   ✅ Aliasy Bash zainstalowane"
fi

if command -v fish &>/dev/null; then
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.config/fish/config.fish" 2>/dev/null
    cat >> "$HOME/.config/fish/config.fish" << 'EOFFISH'

# ============================================
# WSMS PRO v4.2 - ALIASY FISH
# ============================================
set -gx SCRIPTS_DIR "$HOME/scripts"
alias wp-status='bash $SCRIPTS_DIR/server-health-audit.sh'
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-update='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
function wp-update-safe
    echo "📦 Tworzę backup..."
    wp-backup-lite
    and wp-snapshot all
    and wp-update-all
    and echo "✅ Aktualizacja zakończona!"
end
echo "✅ WSMS PRO v4.2 - Aliasy Fish załadowane!"
EOFFISH
    echo -e "   🐟 Aliasy Fish zainstalowane"
fi

# ==================== FAZA 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Faza 6: Konfiguracja crontab...${NC}"
crontab -l > "/tmp/crontab_backup.txt" 2>/dev/null || true

cat > /tmp/wsms_crontab.txt << CRON
# WSMS PRO v4.2 - CRONTAB
0 1 * * * sudo freshclam >> $HOME_EXPANDED/logs/wsms/security/clamav-update.log 2>&1
0 3 * * * $HOME_EXPANDED/scripts/clamav-auto-scan.sh >> $HOME_EXPANDED/logs/wsms/security/clamav-scan.log 2>&1
0 4 * * 0 $HOME_EXPANDED/scripts/clamav-full-scan.sh >> $HOME_EXPANDED/logs/wsms/security/clamav-full.log 2>&1
0 2 * * 0,3 $HOME_EXPANDED/scripts/wp-essential-assets-backup.sh >> $HOME_EXPANDED/logs/wsms/backups/lite.log 2>&1
0 3 1 * * $HOME_EXPANDED/scripts/wp-full-recovery-backup.sh >> $HOME_EXPANDED/logs/wsms/backups/full.log 2>&1
0 4 * * * $HOME_EXPANDED/scripts/wp-smart-retention-manager.sh force-clean >> $HOME_EXPANDED/logs/wsms/retention/retention.log 2>&1
0 6 * * 0 $HOME_EXPANDED/scripts/wp-automated-maintenance-engine.sh >> $HOME_EXPANDED/logs/wsms/maintenance/updates.log 2>&1
0 2 * * * $HOME_EXPANDED/scripts/nas-sftp-sync.sh >> $HOME_EXPANDED/logs/wsms/sync/nas-sync.log 2>&1
0 5 * * 1 $HOME_EXPANDED/scripts/wp-rollback.sh clean >> $HOME_EXPANDED/logs/wsms/rollback/rollback-clean.log 2>&1
CRON

crontab /tmp/wsms_crontab.txt && rm -f /tmp/wsms_crontab.txt
echo -e "${GREEN}✅ Crontab skonfigurowany (9 zadań)${NC}"

# ==================== PODSUMOWANIE ====================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.2 ZAINSTALOWANY POMYŚLNIE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Podsumowanie:${NC}"
echo "   📂 Skrypty: ~/scripts/"
echo "   💾 Backupy: ~/backups-lite, ~/backups-full"
echo "   📸 Rollback: ~/backups-rollback"
echo "   📝 Logi: ~/logs/wsms/"
echo "   🐚 Powłoka: $CURRENT_SHELL"
echo ""
echo -e "${YELLOW}🚀 Następne kroki:${NC}"
if [ "$CURRENT_SHELL" = "fish" ]; then
    echo "   source ~/.config/fish/config.fish"
else
    echo "   source ~/.bashrc"
fi
echo "   wp-status"
echo "   wp-help"
echo ""
echo -e "${GREEN}✅ Gotowe!${NC}"