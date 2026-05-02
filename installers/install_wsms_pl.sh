#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.3 - UNIWERSALNY INSTALATOR
# Wersja: 4.3 | Działa w każdej powłoce (Bash, Fish, Zsh, Sh)
# Autor: Lukasz Malec / GitHub: maleclukas-prog
# Licencja: MIT
# Opis: Kompletny instalator WordPress Server Management System
# =================================================================

set -eE -o pipefail

# Kolory
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

# Wyjście na żywo + trwały log instalatora
INSTALL_LOG_DIR="$HOME/logs/wsms/system"
INSTALL_LOG_FILE="$INSTALL_LOG_DIR/install_wsms_pl_$(date +%Y%m%d_%H%M%S).log"
CURRENT_STEP="Inicjalizacja"

mkdir -p "$INSTALL_LOG_DIR"
touch "$INSTALL_LOG_FILE"
exec > >(tee -a "$INSTALL_LOG_FILE") 2>&1

log_step() {
    CURRENT_STEP="$1"
    echo -e "\n${BLUE}▶️  $CURRENT_STEP${NC}"
}

log_success() {
    echo -e "   ${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "   ${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "   ${RED}❌ $1${NC}"
}

on_install_error() {
    local line_no="$1"
    local failed_cmd="$2"
    local exit_code="$3"

    log_error "Instalacja nie powiodła się"
    echo -e "   ${RED}Krok:${NC} $CURRENT_STEP"
    echo -e "   ${RED}Linia:${NC} $line_no"
    echo -e "   ${RED}Komenda:${NC} $failed_cmd"
    echo -e "   ${RED}Kod wyjścia:${NC} $exit_code"
    echo -e "   ${YELLOW}Pełny log:${NC} $INSTALL_LOG_FILE"
    exit "$exit_code"
}

on_install_exit() {
    local exit_code="$1"
    if [ "$exit_code" -eq 0 ]; then
        echo -e "\n${GREEN}✅ Instalacja zakończona pomyślnie${NC}"
        echo -e "${CYAN}📄 Log instalatora: $INSTALL_LOG_FILE${NC}"
    fi
}

trap 'on_install_error "$LINENO" "$BASH_COMMAND" "$?"' ERR
trap 'on_install_exit "$?"' EXIT

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.3 - UNIWERSALNY INSTALATOR               ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Działa w Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}📄 Plik logu instalatora: $INSTALL_LOG_FILE${NC}"

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
log_step "Faza 1: Inicjalizacja katalogów"

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
    mkdir -p "$dir" && log_success "$dir"
done

# Katalogi systemowe (wymagają sudo)
if sudo mkdir -p /var/quarantine /var/log/clamav; then
    log_success "Utworzono katalogi systemowe (/var/quarantine, /var/log/clamav)"
else
    log_warning "Nie udało się utworzyć części katalogów systemowych"
fi

if sudo chown "$USER":"$USER" /var/log/clamav; then
    log_success "Ustawiono właściciela dla /var/log/clamav"
else
    log_warning "Nie udało się ustawić właściciela /var/log/clamav"
fi

if sudo chmod 755 /var/quarantine; then
    log_success "Ustawiono uprawnienia dla /var/quarantine"
else
    log_warning "Nie udało się ustawić uprawnień /var/quarantine"
fi

echo -e "${GREEN}✅ Infrastruktura gotowa${NC}"

# ==================== FAZA 2: ZALEŻNOŚCI ====================
log_step "Faza 2: Instalacja zależności"
sudo apt-get update -qq

PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
echo -e "   Instalacja: $PACKAGES"
if sudo apt-get install -y $PACKAGES; then
    log_success "Instalacja pakietów zakończona"
else
    log_warning "Część pakietów nie została zainstalowana. Sprawdź komunikaty powyżej."
fi

# Instalacja WP-CLI jeśli brak
if ! command -v wp &> /dev/null; then
    echo -e "   📦 Instalacja WP-CLI..."
    if curl -fsS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        && chmod +x wp-cli.phar \
        && sudo mv wp-cli.phar /usr/local/bin/wp; then
        log_success "WP-CLI zainstalowane"
    else
        log_error "Instalacja WP-CLI nie powiodła się"
        exit 1
    fi
else
    log_success "WP-CLI jest już zainstalowane"
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
# WSMS PRO v4.3 - KONFIGURACJA CENTRALNA
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

wsms_default_log_for_script() {
    local script_path="${1:-${BASH_SOURCE[1]:-$0}}"
    local script_name
    script_name="$(basename "$script_path")"

    case "$script_name" in
        wp-automated-maintenance-engine.sh) echo "$LOG_UPDATES" ;;
        wp-full-recovery-backup.sh) echo "$LOG_FULL_BACKUP" ;;
        wp-essential-assets-backup.sh) echo "$LOG_LITE_BACKUP" ;;
        mysql-backup-manager.sh) echo "$LOG_MYSQL_BACKUP" ;;
        nas-sftp-sync.sh|nas-openssh-client-sync.sh) echo "$LOG_NAS_SYNC" ;;
        wp-smart-retention-manager.sh) echo "$LOG_RETENTION" ;;
        wp-rollback.sh) echo "$LOG_ROLLBACK_SNAPSHOT" ;;
        server-health-audit.sh) echo "$LOG_SYSTEM_HEALTH" ;;
        wp-fleet-status-monitor.sh) echo "$LOG_SYSTEM_DIR/fleet-status.log" ;;
        wp-multi-instance-audit.sh) echo "$LOG_SYSTEM_DIR/multi-instance-audit.log" ;;
        *) echo "$LOG_SYSTEM_DIR/${script_name%.sh}.log" ;;
    esac
}

wsms_init_live_logging() {
    [ -n "$WSMS_LOGGING_ACTIVE" ] && return 0

    local caller_script="${BASH_SOURCE[1]:-$0}"

    # Pomiń skrypty, które mają już własne logowanie dualne.
    if [ -f "$caller_script" ] && \
       (grep -q 'tee -a "\\$LOG_FILE"' "$caller_script" || grep -q '^log_info() {' "$caller_script"); then
        return 0
    fi

    local target_log="${1:-${LOG_FILE:-$(wsms_default_log_for_script "$caller_script")}}"
    mkdir -p "$(dirname "$target_log")"
    touch "$target_log"

    LOG_FILE="$target_log"
    export LOG_FILE
    exec > >(tee -a "$target_log") 2>&1

    WSMS_LOGGING_ACTIVE=1
    export WSMS_LOGGING_ACTIVE
    echo -e "📄 Włączono logowanie na żywo: $target_log"
}

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
# Budowanie bloku SITES przez plik tymczasowy (sed nie obsługuje wieloliniowych podstawień)
_SITES_TMP="$(mktemp)"
echo "SITES=(" > "$_SITES_TMP"
for site in "${MANAGED_SITES[@]}"; do
    printf '    "%s"\n' "$site" >> "$_SITES_TMP"
done
echo ")" >> "$_SITES_TMP"
awk '
    /^SITES=\(/ { system("cat \"'"$_SITES_TMP"'\""); in_sites=1; next }
    in_sites && /^\)/ { in_sites=0; next }
    in_sites { next }
    { print }
' "$HOME/scripts/wsms-config.sh" > "$HOME/scripts/wsms-config.sh.tmp" \
    && mv "$HOME/scripts/wsms-config.sh.tmp" "$HOME/scripts/wsms-config.sh"
rm -f "$_SITES_TMP"
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
echo -e "\n${BLUE}📝 Faza 4: Wdrażanie 20 modułów operacyjnych...${NC}"

deploy() { 
    echo -e "   📦 ${CYAN}$1${NC}"
    local target_script="$HOME/scripts/$1"
    cat > "$target_script"

    # Wstrzyknij standardowy bootstrap logowania do skryptów WSMS.
    if grep -q 'source "\$HOME/scripts/wsms-config.sh"' "$target_script"; then
        sed -i '/source "\$HOME\/scripts\/wsms-config.sh"/a\
wsms_init_live_logging
' "$target_script"
    fi

    chmod +x "$target_script"
}

# -----------------------------------------------------------------
# SKRYPT 1: server-health-audit.sh
# -----------------------------------------------------------------
deploy "server-health-audit.sh" << 'EOFAUDIT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - ROZSZERZONA DIAGNOSTYKA SYSTEMU
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS DIAGNOSTYKA SYSTEMU v4.3${NC}"
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
deploy "wp-fleet-status-monitor.sh" << 'EOFFLEET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - MONITOR STATUSU FLOTY WORDPRESS
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 STATUS FLOTY WORDPRESS v4.3${NC}"
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
# WSMS PRO v4.3 - GŁĘBOKI AUDYT WIELU INSTANCJI
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 ROZPOCZĘCIE GŁĘBOKIEGO AUDYTU v4.3${NC}"
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
# WSMS PRO v4.3 - SILNIK UTRZYMANIA CAŁEJ FLOTY
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "🔄 SILNIK UTRZYMANIA v4.3 - $(date)"
echo "=========================================================="

success_count=0
fail_count=0

znajdz_konfiguracje_strony() {
    local target_name="$1"
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ "$name" = "$target_name" ]; then
            echo "$site"
            return 0
        fi
    done
    return 1
}

sprawdz_http_code() {
    local name="$1"
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$name" 2>/dev/null || echo "000")
    if [ "$http_code" = "000" ]; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
    fi
    echo "$http_code"
}

uruchom_aktualizacje_strony() {
    local name="$1"
    local path="$2"
    local user="$3"
    local mode="$4"
    local target="${5:-}"

    echo -e "\n🔄 Przetwarzanie: $name"

    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ${RED}❌ Niepowodzenie: Brak konfiguracji w $path${NC}"
        ((fail_count++))
        return 1
    fi

    echo "   📸 Tworzenie migawki przed aktualizacją..."
    bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null

    case "$mode" in
        all|site)
            echo "   ⚙️ Aktualizacja rdzenia..."
            sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null || true

            echo "   ⚙️ Aktualizacja wtyczek..."
            sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null || true

            echo "   ⚙️ Aktualizacja motywów..."
            sudo -u "$user" wp --path="$path" theme update --all --quiet 2>/dev/null || true

            echo "   ⚙️ Aktualizacja bazy danych..."
            sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null || true
            ;;
        plugin)
            echo "   ⚙️ Aktualizacja wtyczki: $target"
            sudo -u "$user" wp --path="$path" plugin update "$target" --quiet 2>/dev/null || true
            ;;
        theme)
            echo "   ⚙️ Aktualizacja motywu: $target"
            sudo -u "$user" wp --path="$path" theme update "$target" --quiet 2>/dev/null || true
            ;;
    esac

    echo "   ⚙️ Czyszczenie cache..."
    sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null || true

    http_code=$(sprawdz_http_code "$name")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        echo -e "   ${GREEN}✅ $name zaktualizowana pomyślnie (HTTP $http_code)${NC}"
        ((success_count++))
        return 0
    fi

    echo -e "   ${RED}❌ $name może mieć problemy (HTTP $http_code) - przywracanie...${NC}"
    bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name" 2>/dev/null
    ((fail_count++))
    return 1
}

aktualizuj_wszystkie_strony() {
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        uruchom_aktualizacje_strony "$name" "$path" "$user" "all"
    done
}

aktualizuj_pojedyncza_strone() {
    local site_name="$1"
    local site_config
    site_config=$(znajdz_konfiguracje_strony "$site_name") || {
        echo -e "${RED}❌ Nie znaleziono strony: $site_name${NC}"
        return 1
    }

    IFS=':' read -r name path user <<< "$site_config"
    uruchom_aktualizacje_strony "$name" "$path" "$user" "site"
}

aktualizuj_pojedynczy_komponent() {
    local mode="$1"
    local site_name="$2"
    local slug="$3"
    local site_config
    site_config=$(znajdz_konfiguracje_strony "$site_name") || {
        echo -e "${RED}❌ Nie znaleziono strony: $site_name${NC}"
        return 1
    }

    IFS=':' read -r name path user <<< "$site_config"
    uruchom_aktualizacje_strony "$name" "$path" "$user" "$mode" "$slug"
}

wypisz_uzycie() {
    echo "Użycie: $0 [all|site|plugin|theme] [strona] [slug]"
    echo ""
    echo "Tryby:"
    echo "  all                      - aktualizuj wszystkie strony (domyślnie)"
    echo "  site <strona>            - aktualizuj pełny stack jednej strony"
    echo "  plugin <strona> <plugin> - aktualizuj jedną wtyczkę na jednej stronie"
    echo "  theme <strona> <motyw>   - aktualizuj jeden motyw na jednej stronie"
}

case "${1:-all}" in
    all)
        aktualizuj_wszystkie_strony
        ;;
    site)
        [ -z "${2:-}" ] && wypisz_uzycie && exit 1
        aktualizuj_pojedyncza_strone "$2"
        ;;
    plugin)
        [ -z "${2:-}" ] || [ -z "${3:-}" ] && wypisz_uzycie && exit 1
        aktualizuj_pojedynczy_komponent "plugin" "$2" "$3"
        ;;
    theme)
        [ -z "${2:-}" ] || [ -z "${3:-}" ] && wypisz_uzycie && exit 1
        aktualizuj_pojedynczy_komponent "theme" "$2" "$3"
        ;;
    *)
        wypisz_uzycie
        exit 1
        ;;
esac

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
# WSMS PRO v4.3 - ORKIESTRATOR UPRAWNIEŃ INFRASTRUKTURY
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
            # wp-config.php nie może mieć bitu execute — nadpisz ACL na r-- żeby stat pokazywał 640, nie 650
            if [ -f "$path/wp-config.php" ]; then
                sudo setfacl -m "u:$USER:r--" "$path/wp-config.php" 2>/dev/null || true
            fi
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
# WSMS PRO v4.3 - PEŁNY BACKUP ODTWORZENIOWY
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_FULL_BACKUP"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "💾 PEŁNY BACKUP v4.3 - $(date)"
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
# WSMS PRO v4.3 - BACKUP NIEZBĘDNYCH ZASOBÓW (LITE)
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_LITE_BACKUP"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "⚡ SZYBKI BACKUP v4.3 - $(date)"
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
# WSMS PRO v4.3 - MENEDŻER BACKUPÓW MYSQL
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_MYSQL_BACKUP"
wsms_init_live_logging "$LOG_FILE"

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
# WSMS PRO - SYNCHRONIZACJA NAS (SFTP)
# =================================================================

source "$HOME/scripts/wsms-config.sh"

LOG_DIR="${LOG_SYNC_DIR:-$HOME/logs/wsms/sync}"
LOG_FILE="${LOG_NAS_SYNC:-$LOG_DIR/nas-sync.log}"
mkdir -p "$LOG_DIR"

REMOTE_SERVER="${NAS_HOST:-}"
REMOTE_PORT="${NAS_PORT:-22}"
REMOTE_USER="${NAS_USER:-}"
REMOTE_BASE_DIR="${NAS_PATH:-}"
SSH_KEY="${NAS_SSH_KEY:-}"

if [ -z "$REMOTE_SERVER" ] || [ -z "$REMOTE_USER" ] || [ ! -f "$SSH_KEY" ]; then
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "❌ BŁĄD: Brak konfiguracji NAS"
    echo "[$ts] BŁĄD: Brak konfiguracji NAS" >> "$LOG_FILE"
    exit 1
fi

LOCAL_BASE_DIR="$HOME"
BACKUP_DIRS=("backups-full" "backups-lite" "backups-manual" "mysql-backups")
DAYS_TO_KEEP="${NAS_RETENTION_DAYS:-120}"
MIN_KEEP_COPIES="${NAS_MIN_KEEP_COPIES:-2}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

TOTAL_UPLOADED=0; TOTAL_EXISTING=0; TOTAL_FAILED=0; TOTAL_DELETED=0

log_info() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${CYAN}[$ts]${NC} $1"; echo "[$ts] INFO: $1" >> "$LOG_FILE"; }
log_success() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${GREEN}[$ts] ✅ $1${NC}"; echo "[$ts] SUKCES: $1" >> "$LOG_FILE"; }
log_warning() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${YELLOW}[$ts] ⚠️ $1${NC}"; echo "[$ts] OSTRZEŻENIE: $1" >> "$LOG_FILE"; }
log_error() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${RED}[$ts] ❌ $1${NC}"; echo "[$ts] BŁĄD: $1" >> "$LOG_FILE"; }

pobierz_wiek_pliku() {
    local nazwa_pliku="$1"
    if [[ "$nazwa_pliku" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        local data_pliku="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        local timestamp_pliku=$(date -d "$data_pliku" +%s 2>/dev/null || echo 0)
        echo $(( ( $(date +%s) - timestamp_pliku ) / 86400 ))
    else
        echo 0
    fi
}

# Funkcja do tworzenia folderu na NAS
utworz_folder_zdalny() {
    local zdalny_folder="$1"
    
    # Sprawdź czy folder istnieje
    if echo "ls \"$zdalny_folder\"" 2>/dev/null | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -q "remote_dir"; then
        return 0
    fi
    
    # Tworzymy foldery po kolei
    local aktualna_sciezka=""
    IFS='/' read -ra czesci <<< "$zdalny_folder"
    
    for czesc in "${czesci[@]}"; do
        [ -z "$czesc" ] && continue
        aktualna_sciezka="$aktualna_sciezka/$czesc"
        echo "mkdir \"$aktualna_sciezka\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null
    done
    
    return 0
}

synchronizuj_katalog() {
    local nazwa_katalogu="$1"
    local katalog_lokalny="$LOCAL_BASE_DIR/$nazwa_katalogu"
    local katalog_zdalny="$REMOTE_BASE_DIR/$nazwa_katalogu"
    
    log_info "📂 Przetwarzanie: $nazwa_katalogu"
    
    if [ ! -d "$katalog_lokalny" ]; then
        mkdir -p "$katalog_lokalny"
        log_warning "Utworzono katalog lokalny: $katalog_lokalny"
    fi
    
    local liczba_plikow=$(ls -1 "$katalog_lokalny" 2>/dev/null | wc -l)
    if [ "$liczba_plikow" -eq 0 ]; then
        log_warning "Brak plików w $nazwa_katalogu - pomijanie"
        return 0
    fi
    
    log_info "Znaleziono $liczba_plikow plik(ów) lokalnie"
    
    # Upewnij się że folder na NAS istnieje
    utworz_folder_zdalny "$katalog_zdalny"
    
    # Pobierz listę plików z NAS
    local pliki_zdalne=$(echo "ls -1 \"$katalog_zdalny\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local wyslane=0; local istniejace=0; local nieudane=0
    
    for plik in $(ls -1 "$katalog_lokalny"); do
        if echo "$pliki_zdalne" | grep -q "^$plik$"; then
            echo -e "   ${YELLOW}⏭️ Już istnieje: $plik${NC}"
            ((istniejace++))
        else
            echo -e "   ${CYAN}📤 Wysyłanie: $plik${NC}"
            if echo "put \"$katalog_lokalny/$plik\" \"$katalog_zdalny/$plik\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${GREEN}✅ Wysłano: $plik${NC}"
                ((wyslane++))
            else
                echo -e "   ${RED}❌ Nie udało się: $plik${NC}"
                ((nieudane++))
            fi
        fi
    done
    
    TOTAL_UPLOADED=$((TOTAL_UPLOADED + wyslane))
    TOTAL_EXISTING=$((TOTAL_EXISTING + istniejace))
    TOTAL_FAILED=$((TOTAL_FAILED + nieudane))
    
    # Analiza wieku plików na NAS
    local pliki_zdalne_lista=$(echo "ls -1 \"$katalog_zdalny\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local nowe=0; local srednie=0; local stare=0; local archiwalne=0
    
    for plik in $pliki_zdalne_lista; do
        [ -z "$plik" ] && continue
        local wiek=$(pobierz_wiek_pliku "$plik")
        if [ "$wiek" -le 14 ]; then ((nowe++))
        elif [ "$wiek" -le 30 ]; then ((srednie++))
        elif [ "$wiek" -le $DAYS_TO_KEEP ]; then ((stare++))
        else ((archiwalne++)); fi
    done
    
    # Czyszczenie starych plików
    local zachowane=0; local usuniete=0
    
    for plik in $(echo "$pliki_zdalne_lista" | sort -r); do
        [ -z "$plik" ] && continue
        local wiek=$(pobierz_wiek_pliku "$plik")
        
        if [ $zachowane -lt $MIN_KEEP_COPIES ]; then
            ((zachowane++))
        elif [ $wiek -gt $DAYS_TO_KEEP ]; then
            if echo "rm \"$katalog_zdalny/$plik\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${RED}🗑️ Usunięto stary: $plik (wiek: ${wiek}d)${NC}"
                ((usuniete++))
            fi
        else
            ((zachowane++))
        fi
    done
    
    TOTAL_DELETED=$((TOTAL_DELETED + usuniete))
    
    echo ""
    echo -e "   📊 ${CYAN}Podsumowanie dla $nazwa_katalogu:${NC}"
    echo -e "      Wysłane: ${GREEN}$wyslane${NC} | Istniejące: ${YELLOW}$istniejace${NC} | Nieudane: ${RED}$nieudane${NC}"
    echo -e "      Usunięte: ${RED}$usuniete${NC}"
    echo -e "      Wiek: 0-14d:${GREEN}$nowe${NC} | 15-30d:${YELLOW}$srednie${NC} | 31-${DAYS_TO_KEEP}d:${CYAN}$stare${NC} | >${DAYS_TO_KEEP}d:${RED}$archiwalne${NC}"
    echo "----------------------------------------------------"
}

main() {
    echo "=========================================================="
    echo -e "${CYAN}☁️ SYNCHRONIZACJA NAS - $TIMESTAMP${NC}"
    echo "=========================================================="
    echo ""
    
    log_info "Testowanie połączenia SFTP..."
    if echo "ls" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_SERVER" >/dev/null 2>&1; then
        log_success "Połączenie SFTP nawiązane"
    else
        log_error "Nie można połączyć z $REMOTE_SERVER:$REMOTE_PORT"
        exit 1
    fi
    
    log_info "Sprawdzanie katalogu głównego: $REMOTE_BASE_DIR"
    utworz_folder_zdalny "$REMOTE_BASE_DIR"
    
    echo ""
    
    for dir in "${BACKUP_DIRS[@]}"; do
        synchronizuj_katalog "$dir"
    done
    
    echo "=========================================================="
    echo -e "${CYAN}📊 PODSUMOWANIE KOŃCOWE${NC}"
    echo "=========================================================="
    echo -e "   Wysłane:    ${GREEN}$TOTAL_UPLOADED${NC} plików"
    echo -e "   Już na NAS: ${YELLOW}$TOTAL_EXISTING${NC} plików"
    echo -e "   Nieudane:   ${RED}$TOTAL_FAILED${NC} plików"
    echo -e "   Usunięte:   ${RED}$TOTAL_DELETED${NC} plików"
    echo "=========================================================="
    echo -e "${GREEN}✅ Synchronizacja NAS zakończona${NC}"
    echo "=========================================================="
    
    echo "[$TIMESTAMP] KONIEC: W=$TOTAL_UPLOADED, I=$TOTAL_EXISTING, N=$TOTAL_FAILED, U=$TOTAL_DELETED" >> "$LOG_FILE"
}

main "$@"

EOFNAS

# -----------------------------------------------------------------
# SKRYPT 10: wp-smart-retention-manager.sh
# -----------------------------------------------------------------
deploy "wp-smart-retention-manager.sh" << 'EOFRET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - INTELIGENTNY MENEDŻER RETENCJI
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
wsms_init_live_logging "$LOG_FILE"

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 WSZYSTKIE BACKUPY ZE SZCZEGÓŁAMI v4.3${NC}"
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
    echo -e "${CYAN}💽 WYKORZYSTANIE MIEJSCA NA BACKUPY v4.3${NC}"
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
    lacznie_usuniete=0
    
    normalizuj_klucz_backupu() {
        local nazwa_pliku="$1"
        local klucz="$nazwa_pliku"
        klucz="${klucz%.tar.gz}"
        klucz="${klucz%.sql.gz}"
        klucz="${klucz%.gz}"
        klucz="${klucz%.zip}"
        klucz=$(echo "$klucz" | sed -E 's/[-_][0-9]{8}[-_][0-9]{6}$//; s/[-_][0-9]{8}$//')
        echo "$klucz"
    }

    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo -e "\n📂 Przetwarzanie $(basename "$dir")..."

        mapfile -t wszystkie_pliki < <(find "$dir" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | sort -r)
        if [ "${#wszystkie_pliki[@]}" -eq 0 ]; then
            echo "   ℹ️ Brak plików"
            continue
        fi

        declare -A grupy_plikow=()
        for plik in "${wszystkie_pliki[@]}"; do
            [ -z "$plik" ] && continue
            klucz=$(normalizuj_klucz_backupu "$plik")
            grupy_plikow["$klucz"]+=$'\n'"$plik"
        done

        usuniete_w_katalogu=0
        grupy_ponad_limit=0
        while IFS= read -r klucz; do
            [ -z "$klucz" ] && continue
            pliki_grupy=$(echo "${grupy_plikow[$klucz]}" | sed '/^$/d' | sort -r)
            count=$(echo "$pliki_grupy" | grep -c . 2>/dev/null || echo 0)

            if [ "$count" -gt 2 ]; then
                ((grupy_ponad_limit++))
                usuniete=0
                while IFS= read -r stary_plik; do
                    [ -z "$stary_plik" ] && continue
                    if rm -f "$dir/$stary_plik" 2>/dev/null; then
                        ((usuniete++))
                    fi
                done < <(echo "$pliki_grupy" | tail -n +3)

                usuniete_w_katalogu=$((usuniete_w_katalogu + usuniete))
                echo "   🗑️ $klucz: Zachowano 2 najnowsze, usunięto $usuniete"
            fi
        done < <(printf "%s\n" "${!grupy_plikow[@]}" | sort)

        lacznie_usuniete=$((lacznie_usuniete + usuniete_w_katalogu))
        echo "   📉 $(basename "$dir"): łącznie usunięto $usuniete_w_katalogu"
        if [ "$grupy_ponad_limit" -eq 0 ]; then
            echo "   ℹ️ Brak plików do usunięcia: każda grupa backupów ma już 2 lub mniej plików"
        fi
    done

    if [ -d "$BACKUP_ROLLBACK_DIR" ]; then
        echo -e "\n📂 Przetwarzanie migawek $(basename "$BACKUP_ROLLBACK_DIR")..."
        rollback_usuniete=0

        mapfile -t rollback_strony < <(find "$BACKUP_ROLLBACK_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
        if [ "${#rollback_strony[@]}" -eq 0 ]; then
            echo "   ℹ️ Brak katalogów stron rollback"
        fi

        for site_dir in "${rollback_strony[@]}"; do
            [ -d "$site_dir" ] || continue
            nazwa_strony=$(basename "$site_dir")
            mapfile -t migawki < <(ls -1dt "$site_dir"/*/ 2>/dev/null)
            count=${#migawki[@]}

            if [ "$count" -le 2 ]; then
                echo "   ℹ️ $nazwa_strony: tylko $count migawka(i) — nic do usunięcia"
                continue
            fi

            usuniete=0
            for stara_migawka in "${migawki[@]:2}"; do
                [ -z "$stara_migawka" ] && continue
                if rm -rf "$stara_migawka" 2>/dev/null; then
                    ((usuniete++))
                fi
            done

            rollback_usuniete=$((rollback_usuniete + usuniete))
            echo "   🗑️ $nazwa_strony: zachowano 2 najnowsze migawki, usunięto $usuniete"
        done

        lacznie_usuniete=$((lacznie_usuniete + rollback_usuniete))
        echo "   📉 $(basename "$BACKUP_ROLLBACK_DIR"): łącznie usunięto migawek $rollback_usuniete"
    fi
    
    if [ "$lacznie_usuniete" -eq 0 ]; then
        echo -e "${YELLOW}ℹ️ Tryb awaryjny usunął 0 plików, ponieważ żadna grupa nie przekraczała 2 kopii.${NC}"
        echo -e "${YELLOW}💡 Jeśli chcesz agresywniejsze czyszczenie, użyj opcji 5 (standardowa retencja) lub backup-force-clean.${NC}"
    fi

    echo -e "\n${GREEN}✅ AWARYJNE CZYSZCZENIE ZAKOŃCZONE — łącznie usunięto: $lacznie_usuniete${NC}"
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

emergency_global_cleanup() {
    echo -e "${RED}🚨 TRYB AWARYJNY GLOBALNY: Zachowuję tylko 2 najnowsze pliki łącznie w każdym katalogu!${NC}"
    echo "=========================================================="
    total_deleted_all=0

    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo -e "\n📂 Przetwarzam $(basename "$dir")..."

        mapfile -t all_files < <(find "$dir" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -rn | awk '{print $2}')
        total=${#all_files[@]}

        if [ "$total" -eq 0 ]; then
            echo "   ℹ️ Brak plików"
            continue
        fi

        if [ "$total" -le 2 ]; then
            echo "   ℹ️ Tylko $total plik(i) — nic do usunięcia"
            continue
        fi

        to_delete=("${all_files[@]:2}")
        deleted=0
        for old_file in "${to_delete[@]}"; do
            [ -z "$old_file" ] && continue
            if rm -f "$dir/$old_file" 2>/dev/null; then
                ((deleted++))
                echo "   🗑️ Usunięto: $old_file"
            fi
        done

        total_deleted_all=$((total_deleted_all + deleted))
        echo "   📉 $(basename "$dir"): zachowano 2 najnowsze, usunięto $deleted"
    done

    echo -e "\n${GREEN}✅ AWARYJNE CZYSZCZENIE GLOBALNE ZAKOŃCZONE — łącznie usunięto: $total_deleted_all${NC}"
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
    echo "   6) AWARYJNE (zachowaj tylko 2 najnowsze na stronę)"
    echo "   7) AWARYJNE GLOBALNE (zachowaj tylko 2 najnowsze łącznie w katalogu)"
    echo "   0) Anuluj"
    echo ""
    read -p "Wprowadź wybór [0-7]: " choice
    
    case $choice in
        1) find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null && echo "✅ Szybkie backupy wyczyszczone" ;;
        2) find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null && echo "✅ Pełne backupy wyczyszczone" ;;
        3) find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null && echo "✅ Backupy MySQL wyczyszczone" ;;
        4) find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null && echo "✅ Migawki rollback wyczyszczone" ;;
        5) force_clean ;;
        6) emergency_cleanup ;;
        7) emergency_global_cleanup ;;
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
    emergency-global|eg) emergency_global_cleanup ;;
    *) 
        echo "Użycie: $0 {list|size|dirs|clean|force-clean|emergency|emergency-global}"
        echo ""
        echo "Komendy:"
        echo "  list, l              - Lista wszystkich backupów ze szczegółami"
        echo "  size, s              - Pokaż wykorzystanie miejsca na katalog"
        echo "  dirs, d              - Pokaż strukturę katalogów"
        echo "  clean, c             - Interaktywne czyszczenie"
        echo "  force-clean, f       - Automatyczne czyszczenie wg retencji"
        echo "  emergency, e         - Zachowaj tylko 2 najnowsze kopie na stronę"
        echo "  emergency-global, eg - Zachowaj tylko 2 najnowsze pliki łącznie w katalogu"
        ;;
esac
EOFRET

# -----------------------------------------------------------------
# SKRYPT 11: wp-help.sh
# -----------------------------------------------------------------
deploy "wp-help.sh" << 'EOFHELP'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - KOMPLETNY SPIS KOMEND
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║          🆘 WSMS PRO v4.3 — SPIS KOMEND                    ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}⏰ $(date) │ 📦 v4.3 │ 🖥️  $(hostname)${NC}"
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
printf "    ${GREEN}%-20s${NC} %s\n" "red-robin" "Awaryjne uchwycenie stanu systemu"
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
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency" "AWARYJNE: zachowaj tylko 2 najnowsze na stronę"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency-global" "AWARYJNE GLOBALNE: tylko 2 najnowsze łącznie w katalogu"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean" "Wyczyść stare logi i pliki tymczasowe"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean-force" "Wymuś czyszczenie + puste logi"
echo ""

# ============================================
# SEKCJA 4: SYNCHRONIZACJA ZDALNA (NAS)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ☁️  SYNCHRONIZACJA ZDALNA (NAS)                             │${NC}"
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
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-site [strona]" "Aktualizuj jedną stronę (rdzeń + wszystkie wtyczki/motywy)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-plugin [strona] [wtyczka]" "Aktualizuj jedną wtyczkę na jednej stronie"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-theme [strona] [motyw]" "Aktualizuj jeden motyw na jednej stronie"
echo ""

# ============================================
# SEKCJA 6: SYSTEM ROLLBACK
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 SYSTEM ROLLBACK — NOWOŚĆ w v4.3                         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}  Natychmiastowe odzyskiwanie po nieudanych aktualizacjach!${NC}"
echo ""
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshot all" "Utwórz migawki dla WSZYSTKICH stron"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshot [strona]" "Utwórz migawkę dla jednej strony"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshots" "Lista wszystkich migawek"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-rollback [strona]" "Przywróć do NAJNOWSZEJ migawki"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-rollback-clean [d]" "Wyczyść stare migawki (domyślnie: 30 dni)"
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
echo -e "${BLUE}│  🛡️  BEZPIECZEŃSTWO                                          │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-scan" "Codzienny szybki skan (/var/www, /home)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-deep-scan" "Pełny skan systemu"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-status" "Status usługi ClamAV"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-update" "Aktualizacja definicji wirusów (freshclam)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-logs" "Podgląd logów skanowania (na żywo)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-quarantine" "Lista plików w kwarantannie"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-clean-quarantine" "Wyczyść kwarantannę"
echo ""

# ============================================
# SEKCJA 8: SKRÓTY DO LOGÓW
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📝 SKRÓTY DO LOGÓW (~/logs/wsms/)                          │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "logs-backup" "Na żywo: logi backupów"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-update" "Na żywo: logi aktualizacji"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-sync" "Na żywo: logi synchronizacji NAS"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-scan" "Na żywo: logi skanowania malware"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-all" "Lista wszystkich katalogów logów"
echo ""

# ============================================
# SEKCJA 9: ROZWIĄZYWANIE PROBLEMÓW
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🚨 ROZWIĄZYWANIE PROBLEMÓW                                 │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${RED}%-30s${NC} %s\n" "Strona padła po aktualizacji:" "wp-rollback [strona]"
printf "  ${RED}%-30s${NC} %s\n" "Mało miejsca na dysku:" "backup-emergency (na stronę) / backup-emergency-global (najbardziej agresywne)"
printf "  ${RED}%-30s${NC} %s\n" "Błędy uprawnień:" "wp-fix-perms"
printf "  ${RED}%-30s${NC} %s\n" "Podejrzenie malware:" "clamav-deep-scan"
printf "  ${RED}%-30s${NC} %s\n" "Awaria synchronizacji NAS:" "nas-sync-status; nas-sync-errors"
printf "  ${RED}%-30s${NC} %s\n" "WP-CLI nie działa:" "wp-cli-validator"
printf "  ${RED}%-30s${NC} %s\n" "Sprawdź wszystkie usługi:" "wp-health"
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
# SEKCJA 11: INNE KOMENDY
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📦 INNE KOMENDY                                            │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "red-robin" "Awaryjny backup systemu"
printf "  ${GREEN}%-22s${NC} %s\n" "wsms-clean" "Wyczyść stare logi i pliki tymczasowe"
printf "  ${GREEN}%-22s${NC} %s\n" "scripts-dir" "Lista katalogu skryptów"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-hosts-sync" "Synchronizuj wszystkie domeny do /etc/hosts"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "Ten spis"
echo ""

# ============================================
# STOPKA
# ============================================
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.3 — GOTOWY DO PRACY${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}📚 Dokumentacja: ~/scripts/ │ 🐛 Zgłoś problem: github.com/maleclukas-prog${NC}"
echo -e "${WHITE}👤 Autor: Lukasz Malec${NC}"
echo ""
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
# WSMS PRO v4.3 - SILNIK ROLLBACK
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

# -----------------------------------------------------------------
# SKRYPT 19: wp-hosts-sync.sh
# -----------------------------------------------------------------
deploy "wp-hosts-sync.sh" << 'EOFHOSTS'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - SYNCHRONIZACJA /etc/hosts
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

HOSTS_FILE="/etc/hosts"
MARKER_START="# >>> WSMS LOCAL HOSTS >>>"
MARKER_END="# <<< WSMS LOCAL HOSTS <<<"

if [ "${#SITES[@]}" -eq 0 ]; then
    echo -e "${RED}❌ Brak stron w konfiguracji SITES${NC}"
    exit 1
fi

declare -A seen_domains
domains=()

for site in "${SITES[@]}"; do
    IFS=':' read -r name _path _user <<< "$site"
    [ -z "$name" ] && continue

    if [[ "$name" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then
        if [ -z "${seen_domains[$name]}" ]; then
            domains+=("$name")
            seen_domains["$name"]=1
        fi
    else
        echo -e "${YELLOW}⚠️ Pomijam nieprawidłową domenę z SITES: $name${NC}"
    fi
done

if [ "${#domains[@]}" -eq 0 ]; then
    echo -e "${RED}❌ Brak poprawnych domen do dodania do hosts${NC}"
    exit 1
fi

echo -e "${CYAN}🌐 Podsumowanie synchronizacji hosts:${NC}"
echo "   Skonfigurowane strony: ${#SITES[@]}"
echo "   Domeny do mapowania:  ${#domains[@]}"

TMP_BLOCK="$(mktemp)"
TMP_HOSTS="$(mktemp)"

{
    echo "$MARKER_START"
    echo "# Lokalne przekierowania dla stron WordPress (omija zewnętrzny DNS)"
    for domain in "${domains[@]}"; do
        echo "127.0.0.1 $domain"
    done
    echo "$MARKER_END"
} > "$TMP_BLOCK"

awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
' "$HOSTS_FILE" > "$TMP_HOSTS"

{
    cat "$TMP_HOSTS"
    echo ""
    cat "$TMP_BLOCK"
} > "${TMP_HOSTS}.new"

BACKUP_FILE="/tmp/hosts.wsms.backup.$(date +%Y%m%d_%H%M%S)"
if sudo cp "$HOSTS_FILE" "$BACKUP_FILE" && sudo cp "${TMP_HOSTS}.new" "$HOSTS_FILE"; then
    echo -e "${GREEN}✅ Hosts zaktualizowany poprawnie${NC}"
    echo "   Kopia: $BACKUP_FILE"
else
    echo -e "${RED}❌ Nie udało się zaktualizować $HOSTS_FILE${NC}"
    rm -f "$TMP_BLOCK" "$TMP_HOSTS" "${TMP_HOSTS}.new"
    exit 1
fi

rm -f "$TMP_BLOCK" "$TMP_HOSTS" "${TMP_HOSTS}.new"
EOFHOSTS

# -----------------------------------------------------------------
# SKRYPT 20: wsms-clean.sh
# -----------------------------------------------------------------
deploy "wsms-clean.sh" << 'EOFCLEANPL'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - SKRYPT CZYSZCZĄCY SYSTEM
# Opis: Czyści stare logi, backupy i pliki tymczasowe
# Użycie: ./wsms-clean.sh [--force]
# =================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.3 - CZYSZCZENIE SYSTEMU                  ${NC}"
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
    "install_wsms_pl.sh"
    "wsms-uninstall.sh"
    "uninstall.sh"
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

EOFCLEANPL

echo -e "${GREEN}✅ Wszystkie 20 modułów wdrożonych${NC}"

# ==================== FAZA 5: ALIASY ====================
echo -e "\n${BLUE}🔧 Faza 5: Instalacja aliasów powłoki...${NC}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# >>> WSMS PRO v4.3 BASH >>>/,/# <<< WSMS PRO v4.3 BASH <<</d' "$HOME/.bashrc" 2>/dev/null
    cat >> "$HOME/.bashrc" << 'EOFALIAS'

# >>> WSMS PRO v4.3 BASH >>>
# ============================================
# WSMS PRO v4.3 - BASH SHELL ALIASES
# ============================================

export SCRIPTS_DIR="$HOME/scripts"

alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'

alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-list='wp-fleet'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-diagnoza='wp-audit'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-test-cli='wp-cli-validator'
alias scripts-dir='ls -la $SCRIPTS_DIR/'

alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update='wp-update-all'
alias wp-update-site='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh site'
alias wp-update-plugin='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh plugin'
alias wp-update-theme='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh theme'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias wp-fix-permissions='wp-fix-perms'
alias wp-hosts-sync='bash $SCRIPTS_DIR/wp-hosts-sync.sh'

alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias wp-backup-site='wp-backup-ui'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias wp-rollback-clean='bash $SCRIPTS_DIR/wp-rollback.sh clean'

alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-emergency-global='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency-global'
alias backup-clean-emergency='backup-emergency'
alias backup-dirs='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh dirs'
alias backup-smart-clean='backup-clean'
alias wsms-clean='bash $HOME/scripts/wsms-clean.sh'
alias wsms-clean-force='bash $HOME/scripts/wsms-clean.sh --force'

alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'

alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias nas-sync-status='echo "📊 Last NAS sync:"; tail -10 $HOME/logs/wsms/sync/nas-sync.log 2>/dev/null || echo "No logs yet"'
alias nas-sync-errors='tail -f $HOME/logs/wsms/sync/nas-errors.log 2>/dev/null || echo "No errors logged"'

alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'
alias clamav-quarantine='sudo ls -la /var/quarantine/'
alias clamav-clean-quarantine='sudo rm -rf /var/quarantine/* && echo "✅ Quarantine cleaned"'

alias logs-backup='tail -f $HOME/logs/wsms/backups/lite.log'
alias logs-update='tail -f $HOME/logs/wsms/maintenance/updates.log'
alias logs-sync='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias logs-scan='tail -f $HOME/logs/wsms/security/clamav-scan.log'
alias logs-all='ls -la $HOME/logs/wsms/*/'

wp-status() {
    echo "🌐 WSMS PRO v4.3 - Quick Status:"
    echo "=========================================================="
    wp-list
    echo ""
    backup-size
    echo ""
    echo "📸 Rollback Snapshots:"
    wp-snapshots
}

wp-update-safe() {
    echo "📦 Creating backup first..."
    if wp-backup-lite; then
        echo "⏳ Waiting 10 seconds..."
        sleep 10
        echo "📸 Creating rollback snapshot..."
        wp-snapshot all
        echo "🔄 Running updates..."
        wp-update-all
        echo "✅ Update completed successfully!"
    else
        echo "❌ Backup failed - aborting update!"
        return 1
    fi
}

wp-health() {
    echo "🏥 WSMS Health Check..."
    echo "=========================================================="

    disk_usage=$(df $HOME | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        echo -e "   \033[0;31m⚠️ Disk usage: $disk_usage% (CRITICAL)\033[0m"
    elif [ "$disk_usage" -gt 60 ]; then
        echo -e "   \033[1;33m⚠️ Disk usage: $disk_usage% (WARNING)\033[0m"
    else
        echo -e "   \033[0;32m✅ Disk usage: $disk_usage%\033[0m"
    fi

    if systemctl is-active --quiet nginx || systemctl is-active --quiet apache2; then
        echo -e "   \033[0;32m✅ Web server: Running\033[0m"
    else
        echo -e "   \033[0;31m❌ Web server: Stopped\033[0m"
    fi

    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        echo -e "   \033[0;32m✅ Database: Running\033[0m"
    else
        echo -e "   \033[0;31m❌ Database: Stopped\033[0m"
    fi

    if command -v wp >/dev/null; then
        echo -e "   \033[0;32m✅ WP-CLI: Installed\033[0m"
    else
        echo -e "   \033[0;31m❌ WP-CLI: Missing\033[0m"
    fi
}

echo "✅ WSMS PRO v4.3 - Bash aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"
# <<< WSMS PRO v4.3 BASH <<<
EOFALIAS
    echo -e "   ✅ Aliasy Bash zainstalowane"
fi

if command -v fish &>/dev/null; then
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    sed -i '/# >>> WSMS PRO v4.3 FISH >>>/,/# <<< WSMS PRO v4.3 FISH <<</d' "$HOME/.config/fish/config.fish" 2>/dev/null
    cat >> "$HOME/.config/fish/config.fish" << 'EOFFISH'

# >>> WSMS PRO v4.3 FISH >>>
# ============================================
# WSMS PRO v4.3 - FISH ALIASES
# ============================================
set -gx SCRIPTS_DIR "$HOME/scripts"

alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
alias help-wp='wp-help'
alias wp-status='system-diag; and echo ""; and wp-fleet; and echo ""; and backup-size'

alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-list='wp-fleet'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-diagnoza='wp-audit'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-test-cli='wp-cli-validator'
alias scripts-dir='ls -la $SCRIPTS_DIR/'

alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update='wp-update-all'
alias wp-update-site='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh site'
alias wp-update-plugin='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh plugin'
alias wp-update-theme='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh theme'
alias wp-update-safe='wp-backup-lite; and sleep 5; and wp-update-all'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias wp-fix-permissions='wp-fix-perms'
alias wp-hosts-sync='bash $SCRIPTS_DIR/wp-hosts-sync.sh'

alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias wp-backup-site='wp-backup-ui'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias wp-rollback-clean='bash $SCRIPTS_DIR/wp-rollback.sh clean'

alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-emergency-global='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency-global'
alias backup-clean-emergency='backup-emergency'
alias backup-dirs='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh dirs'
alias backup-smart-clean='backup-clean'
alias wsms-clean='bash $HOME/scripts/wsms-clean.sh'
alias wsms-clean-force='bash $HOME/scripts/wsms-clean.sh --force'

alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'

alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias nas-sync-status='echo "📊 Last NAS sync:"; tail -10 $HOME/logs/wsms/sync/nas-sync.log 2>/dev/null; or echo "No logs yet"'
alias nas-sync-errors='tail -f $HOME/logs/wsms/sync/nas-errors.log 2>/dev/null; or echo "No errors logged"'

alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'
alias clamav-quarantine='sudo ls -la /var/quarantine/'
alias clamav-clean-quarantine='sudo rm -rf /var/quarantine/*; and echo "✅ Quarantine cleaned"'

alias logs-backup='tail -f $HOME/logs/wsms/backups/lite.log'
alias logs-update='tail -f $HOME/logs/wsms/maintenance/updates.log'
alias logs-sync='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias logs-scan='tail -f $HOME/logs/wsms/security/clamav-scan.log'
alias logs-all='ls -la $HOME/logs/wsms/*/'

function wp-update-safe
    echo "📦 Creating backup first..."
    wp-backup-lite
    and echo "⏳ Waiting 10 seconds..."
    sleep 10
    and echo "📸 Creating rollback snapshot..."
    wp-snapshot all
    and echo "🔄 Running updates..."
    wp-update-all
    and echo "✅ Update completed successfully!"
end

function wp-health
    echo "🏥 WSMS Health Check..."
    echo "=========================================================="

    set disk_usage (df $HOME | awk 'NR==2 {print $5}' | sed 's/%//')
    if test $disk_usage -gt 80
        echo "   ⚠️ Disk usage: $disk_usage% (CRITICAL)"
    else if test $disk_usage -gt 60
        echo "   ⚠️ Disk usage: $disk_usage% (WARNING)"
    else
        echo "   ✅ Disk usage: $disk_usage%"
    end

    if systemctl is-active --quiet nginx; or systemctl is-active --quiet apache2
        echo "   ✅ Web server: Running"
    else
        echo "   ❌ Web server: Stopped"
    end

    if systemctl is-active --quiet mysql; or systemctl is-active --quiet mariadb
        echo "   ✅ Database: Running"
    else
        echo "   ❌ Database: Stopped"
    end

    if command -v wp >/dev/null
        echo "   ✅ WP-CLI: Installed"
    else
        echo "   ❌ WP-CLI: Missing"
    end
end

echo "✅ WSMS PRO v4.3 - Fish aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"
# <<< WSMS PRO v4.3 FISH <<<
EOFFISH
    echo -e "   🐟 Aliasy Fish zainstalowane"
else
    log_warning "Nie wykryto powłoki fish - pomijam aliasy fish"
    echo -e "   ${CYAN}Wskazówka:${NC} Zainstaluj: sudo apt-get install -y fish"
fi

# ==================== FAZA 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Faza 6: Konfiguracja crontab...${NC}"
crontab -l > "/tmp/crontab_backup.txt" 2>/dev/null || true

cat > /tmp/wsms_crontab.txt << CRON
# WSMS PRO v4.3 - CRONTAB
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

# ==================== FAZA 7: UPRAWNIENIA ====================
log_step "Faza 7: Nadawanie uprawnień skryptom"
chmod +x "$HOME/scripts/"*.sh 2>/dev/null && log_success "Wszystkie skrypty w ~/scripts/ ustawione jako wykonywalne"
echo -e "${GREEN}✅ Uprawnienia nadane${NC}"

# ==================== PODSUMOWANIE ====================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.3 ZAINSTALOWANY POMYŚLNIE!${NC}"
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