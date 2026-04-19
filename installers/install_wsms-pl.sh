#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.2 - UNIWERSALNY INSTALATOR
# Wersja: 4.2 | Działa w każdej powłoce (Bash, Fish, Zsh, Sh)
# Autor: Lukasz Malec / GitHub: maleclukas-prog
# Licencja: MIT
# =================================================================

set -eE
trap 'echo -e "${RED}❌ Instalacja nie powiodła się w linii $LINENO${NC}"; exit 1' ERR

# Kolory
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.2 - UNIWERSALNY INSTALATOR               ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Działa w Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

CURRENT_SHELL=$(basename "$SHELL")
echo -e "${BLUE}📍 Wykryta powłoka: $CURRENT_SHELL${NC}"

# =================================================================
# ⚙️ KONFIGURACJA - EDYTUJ TYLKO TUTAJ!
# =================================================================
MANAGED_SITES=(
    "site1:/var/www/site1/public_html:wordpress_site1"
    "site2:/var/www/site2/public_html:wordpress_site2"
)

NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"
# =================================================================

validate_config() {
    local errors=0
    echo -e "\n${CYAN}🔍 Faza 0: Walidacja konfiguracji...${NC}"
    
    if [ ${#MANAGED_SITES[@]} -eq 0 ]; then
        echo -e "   ${RED}❌ BŁĄD: Brak skonfigurowanych stron${NC}"
        ((errors++))
    fi
    
    for site in "${MANAGED_SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ -z "$name" ] || [ -z "$path" ] || [ -z "$user" ]; then
            echo -e "   ${RED}❌ BŁĄD: Nieprawidłowy format: '$site'${NC}"
            ((errors++))
        fi
    done
    
    if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
        echo -e "   ${YELLOW}⚠️  Ostrzeżenie: NAS_HOST nie skonfigurowany${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}❌ Walidacja nie powiodła się${NC}"
        exit 1
    fi
    
    echo -e "   ${GREEN}✅ Konfiguracja zwalidowana${NC}"
}

validate_config

# ==================== FAZA 1: INFRASTRUKTURA ====================
echo -e "\n${BLUE}📂 Faza 1: Inicjalizacja katalogów...${NC}"
DIRS=(
    "$HOME/scripts"
    "$HOME/backups-lite"
    "$HOME/backups-full"
    "$HOME/backups-manual"
    "$HOME/backups-rollback"
    "$HOME/mysql-backups"
)

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

sudo mkdir -p /var/quarantine /var/log/clamav 2>/dev/null || true
sudo chown "$USER":"$USER" /var/log/clamav 2>/dev/null || true
sudo chmod 755 /var/quarantine 2>/dev/null || true
echo -e "${GREEN}✅ Infrastruktura gotowa${NC}"

# ==================== FAZA 2: ZALEŻNOŚCI ====================
echo -e "\n${BLUE}📦 Faza 2: Instalacja zależności...${NC}"
sudo apt-get update -qq
PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
sudo apt-get install -y $PACKAGES 2>/dev/null || true

if ! command -v wp &> /dev/null; then
    echo -e "   📦 Instalacja WP-CLI..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
fi

echo -e "${GREEN}✅ Zależności gotowe${NC}"

# ==================== FAZA 3: KONFIGURACJA ====================
echo -e "\n${BLUE}📝 Faza 3: Generowanie konfiguracji...${NC}"
HOME_EXPANDED="$HOME"

cat > "$HOME/scripts/wsms-config.sh" << EOF
#!/bin/bash
# WSMS GLOBAL CONFIGURATION - Wygenerowano: $(date)

SITES=(
$(for site in "${MANAGED_SITES[@]}"; do echo "    \"$site\""; done)
)

NAS_HOST="$NAS_HOST"
NAS_PORT="$NAS_PORT"
NAS_USER="$NAS_USER"
NAS_PATH="$NAS_PATH"
NAS_SSH_KEY="$NAS_SSH_KEY"

RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
RETENTION_ROLLBACK=7
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2
DISK_ALERT_THRESHOLD=80

SCRIPT_DIR="\$HOME/scripts"
BACKUP_LITE_DIR="\$HOME/backups-lite"
BACKUP_FULL_DIR="\$HOME/backups-full"
BACKUP_MANUAL_DIR="\$HOME/backups-manual"
BACKUP_MYSQL_DIR="\$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="\$HOME/backups-rollback"

LOG_BASE_DIR="\$HOME/logs/wsms"
LOG_BACKUPS_DIR="\$LOG_BASE_DIR/backups"
LOG_MAINTENANCE_DIR="\$LOG_BASE_DIR/maintenance"
LOG_SECURITY_DIR="\$LOG_BASE_DIR/security"
LOG_SYNC_DIR="\$LOG_BASE_DIR/sync"
LOG_RETENTION_DIR="\$LOG_BASE_DIR/retention"
LOG_ROLLBACK_DIR="\$LOG_BASE_DIR/rollback"
LOG_SYSTEM_DIR="\$LOG_BASE_DIR/system"

LOG_LITE_BACKUP="\$LOG_BACKUPS_DIR/lite.log"
LOG_FULL_BACKUP="\$LOG_BACKUPS_DIR/full.log"
LOG_MYSQL_BACKUP="\$LOG_BACKUPS_DIR/mysql.log"
LOG_UPDATES="\$LOG_MAINTENANCE_DIR/updates.log"
LOG_PERMISSIONS="\$LOG_MAINTENANCE_DIR/permissions.log"
LOG_CLAMAV_SCAN="\$LOG_SECURITY_DIR/clamav-scan.log"
LOG_CLAMAV_FULL="\$LOG_SECURITY_DIR/clamav-full.log"
LOG_CLAMAV_UPDATE="\$LOG_SECURITY_DIR/clamav-update.log"
LOG_NAS_SYNC="\$LOG_SYNC_DIR/nas-sync.log"
LOG_NAS_ERRORS="\$LOG_SYNC_DIR/nas-errors.log"
LOG_RETENTION="\$LOG_RETENTION_DIR/retention.log"
LOG_ROLLBACK_SNAPSHOT="\$LOG_ROLLBACK_DIR/snapshots.log"
LOG_ROLLBACK_CLEAN="\$LOG_ROLLBACK_DIR/rollback-clean.log"
LOG_SYSTEM_HEALTH="\$LOG_SYSTEM_DIR/health.log"

QUARANTINE_DIR="/var/quarantine"
CLAMAV_LOG_DIR="/var/log/clamav"

mkdir -p "\$LOG_BACKUPS_DIR" "\$LOG_MAINTENANCE_DIR" "\$LOG_SECURITY_DIR" \
         "\$LOG_SYNC_DIR" "\$LOG_RETENTION_DIR" "\$LOG_ROLLBACK_DIR" "\$LOG_SYSTEM_DIR"

export SITES NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL RETENTION_ROLLBACK
export NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR BACKUP_ROLLBACK_DIR
export LOG_BASE_DIR LOG_BACKUPS_DIR LOG_MAINTENANCE_DIR LOG_SECURITY_DIR
export LOG_SYNC_DIR LOG_RETENTION_DIR LOG_ROLLBACK_DIR LOG_SYSTEM_DIR
export LOG_LITE_BACKUP LOG_FULL_BACKUP LOG_MYSQL_BACKUP LOG_UPDATES LOG_PERMISSIONS
export LOG_CLAMAV_SCAN LOG_CLAMAV_FULL LOG_CLAMAV_UPDATE
export LOG_NAS_SYNC LOG_NAS_ERRORS LOG_RETENTION LOG_ROLLBACK_SNAPSHOT LOG_ROLLBACK_CLEAN LOG_SYSTEM_HEALTH
export QUARANTINE_DIR CLAMAV_LOG_DIR
EOF

chmod +x "$HOME/scripts/wsms-config.sh"
source "$HOME/scripts/wsms-config.sh"
echo -e "${GREEN}✅ Konfiguracja wygenerowana${NC}"

# ==================== FAZA 4: WDROŻENIE SKRYPTÓW ====================
echo -e "\n${BLUE}📝 Faza 4: Wdrażanie 18 modułów...${NC}"

deploy() { 
    echo -e "   📦 $1"
    cat > "$HOME/scripts/$1"
    chmod +x "$HOME/scripts/$1"
}

# SCRIPT 1: server-health-audit.sh
deploy "server-health-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS DIAGNOSTYKA SYSTEMU v4.2${NC}"
echo "=========================================================="
echo -e "⏰ Czas: $(date)"
echo -e "💻 Host: $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"

echo -e "\n${CYAN}📈 OBCIĄŻENIE SYSTEMU:${NC}"
echo "   Rdzenie CPU: $(nproc)"
echo "   Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Pamięć: " && free -h | awk '/^Mem:/ {print $3 "/" $2 " użyte"}'

echo -e "\n${CYAN}💾 PAMIĘĆ MASOWA:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'

echo -e "\n${CYAN}🌐 ZARZĄDZANE STRONY:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "nieznana")
        echo "      Core: v$ver"
    else 
        echo -e "      ${RED}Brak konfiguracji${NC}"
    fi
done

echo -e "\n${CYAN}💾 BACKUPY:${NC}"
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count plików ($size)"
    fi
done

echo -e "\n${GREEN}✅ AUDYT ZAKOŃCZONY${NC}"
EOF

# SCRIPT 2: wp-fleet-status-monitor.sh
deploy "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 STATUS FLOTY WORDPRESS v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "nieznana")
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        echo -e "   ${GREEN}✅${NC} $name: v$ver | Aktualizacje: $updates"
    else
        echo -e "   ${RED}❌${NC} $name: Nie znaleziono"
    fi
done

echo ""
echo -e "${CYAN}📸 MIGAWKI ROLLBACK:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    [ "$count" -gt 0 ] && echo "   📁 $name: $count migawek"
done
EOF

# SCRIPT 3: wp-multi-instance-audit.sh
deploy "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 GŁĘBOKI AUDYT v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- $name ---${NC}"
    if [ -f "$path/wp-config.php" ]; then
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Baza OK"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
        echo "   📦 Aktualizacje: $updates"
    else
        echo -e "   ${RED}❌ Brak konfiguracji${NC}"
    fi
done
EOF

# SCRIPT 4: wp-automated-maintenance-engine.sh
deploy "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔄 SILNIK UTRZYMANIA v4.2 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Przetwarzanie: $name"
    if [ -f "$path/wp-config.php" ]; then
        echo "   📸 Tworzenie migawki..."
        bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null
        echo "   ⚙️ Aktualizacja core..."
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        echo "   ⚙️ Aktualizacja wtyczek..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        echo "   ⚙️ Aktualizacja motywów..."
        sudo -u "$user" wp --path="$path" theme update --all --quiet 2>/dev/null
        echo "   ⚙️ Aktualizacja bazy..."
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        echo -e "   ${GREEN}✅ Zaktualizowano${NC}"
    else
        echo -e "   ${RED}❌ Niepowodzenie${NC}"
    fi
done

echo -e "\n✅ UTRZYMANIE ZAKOŃCZONE - $(date)"
EOF

# SCRIPT 5: infrastructure-permission-orchestrator.sh
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_PERMISSIONS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔐 NAPRAWA UPRAWNIEŃ - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}Naprawa: $name${NC}"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php" 2>/dev/null
        echo "   ${GREEN}✅ Naprawiono${NC}"
    fi
done
echo -e "\n✅ UPRAWNIENIA NAPRAWIONE - $(date)"
EOF

# SCRIPT 6: wp-full-recovery-backup.sh
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_FULL_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "💾 PEŁNY BACKUP - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "📦 Przetwarzanie: $name"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    echo "   ✅ $name"
done

find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime +$RETENTION_FULL -delete 2>/dev/null
echo -e "\n✅ PEŁNY BACKUP ZAKOŃCZONY - $(date)"
EOF

# SCRIPT 7: wp-essential-assets-backup.sh
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_LITE_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "⚡ SZYBKI BACKUP - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "📁 Przetwarzanie: $name"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" \
        wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    echo "   ✅ $name"
done

find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime +$RETENTION_LITE -delete 2>/dev/null
echo -e "\n✅ SZYBKI BACKUP ZAKOŃCZONY - $(date)"
EOF

# SCRIPT 8: mysql-backup-manager.sh
deploy "mysql-backup-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
LOG_FILE="$LOG_MYSQL_BACKUP"
exec >> "$LOG_FILE" 2>&1

if [ "$target" = "list" ]; then
    echo "📋 Dostępne backupy MySQL:"
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        count=$(find "$BACKUP_MYSQL_DIR" -name "db-$name-*.sql.gz" 2>/dev/null | wc -l)
        echo "   $name: $count backupów"
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
            mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz"
            echo "✅ Baza: $name"
        fi
    fi
done

find "$BACKUP_MYSQL_DIR" -name "*.sql.gz" -mtime +$RETENTION_MYSQL -delete 2>/dev/null
EOF

# SCRIPT 9: nas-sftp-sync.sh
deploy "nas-sftp-sync.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_NAS_SYNC"
ERROR_LOG="$LOG_NAS_ERRORS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "☁️ SYNCHRONIZACJA NAS - $(date)"
echo "=========================================================="

[ ! -f "$NAS_SSH_KEY" ] && { echo "❌ Brak klucza SSH"; echo "$(date): Brak klucza SSH" >> "$ERROR_LOG"; exit 1; }
[ "$NAS_HOST" = "your-nas.synology.me" ] && { echo "⚠️ NAS nie skonfigurowany"; exit 0; }

for module in backups-lite backups-full mysql-backups; do
    echo "📤 Przetwarzanie: $module"
    [ ! -d "$HOME/$module" ] && continue
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
mkdir -p $NAS_PATH/$module
put $HOME/$module/* $NAS_PATH/$module/
bye
SFTP_EOF
    then
        echo "   ✅ $module zsynchronizowany"
    else
        echo "   ❌ $module NIEUDANE"
        echo "$(date): Nieudana synchronizacja $module" >> "$ERROR_LOG"
    fi
done

echo "✅ SYNCHRONIZACJA ZAKOŃCZONA - $(date)"
EOF

# SCRIPT 10: wp-smart-retention-manager.sh
deploy "wp-smart-retention-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
exec >> "$LOG_FILE" 2>&1

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 WSZYSTKIE BACKUPY${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        [ -d "$dir" ] && echo -e "\n📂 $(basename "$dir"):" && find "$dir" -type f 2>/dev/null | head -10 | while read f; do echo "   $(basename "$f")"; done
    done
}

show_size() {
    echo -e "${CYAN}💽 WYKORZYSTANIE MIEJSCA${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        [ -d "$dir" ] && echo "   📂 $(basename "$dir"): $(du -sh "$dir" 2>/dev/null | cut -f1)"
    done
    echo "   💿 Zajętość dysku: $(get_disk_usage)%"
}

emergency_cleanup() {
    echo -e "${RED}🚨 TRYB AWARYJNY: Zachowuję 2 najnowsze${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        [ -d "$dir" ] && for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r | tail -n +3 | xargs rm -f 2>/dev/null
        done
    done
    echo "✅ Awaryjne czyszczenie zakończone"
}

force_clean() {
    echo "🧹 Czyszczenie retencyjne - $(date)"
    if [ "$(get_disk_usage)" -ge "$DISK_ALERT_THRESHOLD" ]; then
        emergency_cleanup
    else
        find "$BACKUP_LITE_DIR" -type f -mtime +$RETENTION_LITE -delete 2>/dev/null
        find "$BACKUP_FULL_DIR" -type f -mtime +$RETENTION_FULL -delete 2>/dev/null
        find "$BACKUP_MYSQL_DIR" -type f -mtime +$RETENTION_MYSQL -delete 2>/dev/null
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime +$RETENTION_ROLLBACK -exec rm -rf {} \; 2>/dev/null
        echo "✅ Standardowe czyszczenie zakończone"
    fi
}

case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    dirs|d) ls -la "$HOME"/backups-* 2>/dev/null ;;
    force-clean|f) force_clean ;;
    emergency|e) emergency_cleanup ;;
    *) echo "Użycie: $0 {list|size|dirs|force-clean|emergency}" ;;
esac
EOF

# SCRIPT 11: wp-help.sh
deploy "wp-help.sh" << 'EOF'
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

# SCRIPTS 12-18 (same as English version)
deploy "wp-interactive-backup-tool.sh" << 'EOF'
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
EOF

deploy "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOF

deploy "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="$HOME/backups-"* /etc /var/log /home 2>/dev/null
echo "✅ Backup systemu: $OUT"
EOF

deploy "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_CLAMAV_SCAN"
echo "--- Skanowanie: $(date) ---" | sudo tee -a "$LOG_FILE"
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a "$LOG_FILE"
EOF

deploy "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_CLAMAV_FULL"
sudo clamscan -r --infected --move="$QUARANTINE_DIR" --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee "$LOG_FILE"
echo "✅ Pełne skanowanie zakończone"
EOF

deploy "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🧪 WALIDACJA WP-CLI"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    sudo -u "$user" wp --path="$path" core version &>/dev/null && echo "✅ $name" || echo "❌ $name"
done
EOF

deploy "wp-rollback.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ROLLBACK_DIR="$BACKUP_ROLLBACK_DIR"
mkdir -p "$ROLLBACK_DIR"

get_site_config() { for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; [ "$name" = "$1" ] && echo "$site" && return 0; done; return 1; }

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
    [ -f "$db_backup" ] && gunzip < "$db_backup" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null
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
EOF

echo -e "${GREEN}✅ Wszystkie 18 modułów wdrożonych${NC}"

# ==================== FAZA 5: ALIASY ====================
echo -e "\n${BLUE}🔧 Faza 5: Instalacja aliasów...${NC}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.bashrc" 2>/dev/null
    cat >> "$HOME/.bashrc" << 'EOF'

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
EOF
    echo -e "   ✅ Aliasy Bash zainstalowane"
fi

if command -v fish &>/dev/null; then
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.config/fish/config.fish" 2>/dev/null
    cat >> "$HOME/.config/fish/config.fish" << 'EOF'

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
EOF
    echo -e "   🐟 Aliasy Fish zainstalowane"
fi

# ==================== FAZA 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Faza 6: Konfiguracja crontab...${NC}"
crontab -l > "/tmp/crontab_backup.txt" 2>/dev/null || true

cat > /tmp/wsms_crontab.txt << CRON_EOF
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
CRON_EOF

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