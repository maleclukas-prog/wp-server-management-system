#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.3 - UNIVERSAL INSTALLER
# Version: 4.3 | Works in any shell (Bash, Fish, Zsh, Sh)
# Author: Lukasz Malec / GitHub: maleclukas-prog
# License: MIT
# Description: Complete WordPress Server Management System installer
# =================================================================

set -eE -o pipefail

# Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

# Live output + persistent installer log
INSTALL_LOG_DIR="$HOME/logs/wsms/system"
INSTALL_LOG_FILE="$INSTALL_LOG_DIR/install_wsms_$(date +%Y%m%d_%H%M%S).log"
CURRENT_STEP="Initialization"

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

    log_error "Installation failed"
    echo -e "   ${RED}Step:${NC} $CURRENT_STEP"
    echo -e "   ${RED}Line:${NC} $line_no"
    echo -e "   ${RED}Command:${NC} $failed_cmd"
    echo -e "   ${RED}Exit code:${NC} $exit_code"
    echo -e "   ${YELLOW}Full log:${NC} $INSTALL_LOG_FILE"
    exit "$exit_code"
}

on_install_exit() {
    local exit_code="$1"
    if [ "$exit_code" -eq 0 ]; then
        echo -e "\n${GREEN}✅ Installation completed successfully${NC}"
        echo -e "${CYAN}📄 Installer log: $INSTALL_LOG_FILE${NC}"
    fi
}

trap 'on_install_error "$LINENO" "$BASH_COMMAND" "$?"' ERR
trap 'on_install_exit "$?"' EXIT

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.3 - UNIVERSAL INSTALLER                  ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Works in Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}📄 Installer log file: $INSTALL_LOG_FILE${NC}"

# Detect current shell
CURRENT_SHELL=$(basename "$SHELL")
echo -e "${BLUE}📍 Detected shell: $CURRENT_SHELL${NC}"

# =================================================================
# ⚙️ CONFIGURATION - EDIT ONLY HERE!
# =================================================================
# Format: "site_nickname:/full/path/to/public_html:system_user"
MANAGED_SITES=(
    "site1:/var/www/site1/public_html:wordpress_site1"
    "site2:/var/www/site2/public_html:wordpress_site2"
)

# Synology NAS Settings (Remote Backup Vault)
NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"
# =================================================================

# Validation function
validate_config() {
    local errors=0
    
    echo -e "\n${CYAN}🔍 Phase 0: Validating configuration...${NC}"
    
    if [ ${#MANAGED_SITES[@]} -eq 0 ]; then
        echo -e "   ${RED}❌ ERROR: No sites configured in MANAGED_SITES array${NC}"
        ((errors++))
    fi
    
    for site in "${MANAGED_SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ -z "$name" ] || [ -z "$path" ] || [ -z "$user" ]; then
            echo -e "   ${RED}❌ ERROR: Invalid site format: '$site'${NC}"
            echo -e "      Expected: 'nickname:/path/to/site:username'"
            ((errors++))
        fi
        if ! id "$user" &>/dev/null; then
            echo -e "   ${YELLOW}⚠️  Warning: User '$user' does not exist (will be created if needed)${NC}"
        fi
    done
    
    if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
        echo -e "   ${YELLOW}⚠️  Warning: NAS_HOST not configured (NAS sync will be skipped)${NC}"
    fi
    
    if [ -n "$NAS_SSH_KEY" ] && [ ! -f "$NAS_SSH_KEY" ]; then
        echo -e "   ${YELLOW}⚠️  Warning: SSH key '$NAS_SSH_KEY' not found${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}❌ Configuration validation failed with $errors error(s)${NC}"
        echo -e "${YELLOW}Please edit the MANAGED_SITES array and NAS settings at the top of this script.${NC}"
        exit 1
    fi
    
    echo -e "   ${GREEN}✅ Configuration validated successfully${NC}"
}

validate_config

# ==================== PHASE 1: INFRASTRUCTURE ====================
log_step "Phase 1: Initializing directory infrastructure"

# Main directories
DIRS=(
    "$HOME/scripts"
    "$HOME/backups-lite"
    "$HOME/backups-full"
    "$HOME/backups-manual"
    "$HOME/backups-rollback"
    "$HOME/mysql-backups"
)

# Organized log directories
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

# System directories (require sudo)
if sudo mkdir -p /var/quarantine /var/log/clamav; then
    log_success "Created system directories (/var/quarantine, /var/log/clamav)"
else
    log_warning "Could not create some system directories"
fi

if sudo chown "$USER":"$USER" /var/log/clamav; then
    log_success "Ownership set for /var/log/clamav"
else
    log_warning "Could not set ownership for /var/log/clamav"
fi

if sudo chmod 755 /var/quarantine; then
    log_success "Permissions set for /var/quarantine"
else
    log_warning "Could not set permissions for /var/quarantine"
fi

echo -e "${GREEN}✅ Infrastructure ready${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
log_step "Phase 2: Installing dependencies"
sudo apt-get update -qq

PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
echo -e "   Installing: $PACKAGES"
if sudo apt-get install -y $PACKAGES; then
    log_success "Package installation finished"
else
    log_warning "Some packages could not be installed. Check output above for details."
fi

# Install WP-CLI if missing
if ! command -v wp &> /dev/null; then
    echo -e "   📦 Installing WP-CLI..."
    if curl -fsS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        && chmod +x wp-cli.phar \
        && sudo mv wp-cli.phar /usr/local/bin/wp; then
        log_success "WP-CLI installed"
    else
        log_error "WP-CLI installation failed"
        exit 1
    fi
else
    log_success "WP-CLI already installed"
fi

# Verify installations
echo -e "   ✅ Dependencies verified:"
echo -e "      - WP-CLI: $(wp --version 2>/dev/null | head -1 || echo 'installed')"
echo -e "      - ClamAV: $(clamscan --version 2>/dev/null | head -1 || echo 'installed')"
echo -e "${GREEN}✅ Dependencies ready${NC}"

# ==================== PHASE 3: CENTRAL CONFIGURATION ====================
echo -e "\n${BLUE}📝 Phase 3: Generating central configuration...${NC}"

HOME_EXPANDED="$HOME"

cat > "$HOME/scripts/wsms-config.sh" << 'EOF'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - CENTRAL CONFIGURATION
# Generated by installer - DO NOT EDIT MANUALLY
# =================================================================

# ==================== WORDPRESS SITES ====================
SITES=(
    "CHANGE_ME"
)

# ==================== NAS/SFTP SETTINGS ====================
NAS_HOST="CHANGE_ME"
NAS_PORT="22"
NAS_USER="CHANGE_ME"
NAS_PATH="CHANGE_ME"
NAS_SSH_KEY="CHANGE_ME"

# ==================== RETENTION POLICIES ====================
RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
RETENTION_ROLLBACK=30

# ==================== NAS RETENTION ====================
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2

# ==================== SYSTEM THRESHOLDS ====================
DISK_ALERT_THRESHOLD=80
ROLLBACK_MAX_SIZE_MB=500

# ==================== NOTIFICATIONS ====================
SLACK_WEBHOOK_URL=""
EMAIL_ALERT=""

# ==================== DIRECTORY PATHS ====================
SCRIPT_DIR="$HOME/scripts"

# Backup directories
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MANUAL_DIR="$HOME/backups-manual"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="$HOME/backups-rollback"

# Log directories - ORGANIZED STRUCTURE
LOG_BASE_DIR="$HOME/logs/wsms"
LOG_BACKUPS_DIR="$LOG_BASE_DIR/backups"
LOG_MAINTENANCE_DIR="$LOG_BASE_DIR/maintenance"
LOG_SECURITY_DIR="$LOG_BASE_DIR/security"
LOG_SYNC_DIR="$LOG_BASE_DIR/sync"
LOG_RETENTION_DIR="$LOG_BASE_DIR/retention"
LOG_ROLLBACK_DIR="$LOG_BASE_DIR/rollback"
LOG_SYSTEM_DIR="$LOG_BASE_DIR/system"

# Specific log files
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

# External paths
QUARANTINE_DIR="/var/quarantine"
CLAMAV_LOG_DIR="/var/log/clamav"

# Create log directories
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

    # Skip scripts that already implement custom dual logging.
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
    echo -e "📄 Live log enabled: $target_log"
}

# ==================== EXPORT ALL VARIABLES ====================
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

# Replace placeholders with actual values
# Build SITES block via temp file (sed cannot handle multiline replacements)
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
sed -i "s|NAS_HOST=\"CHANGE_ME\"|NAS_HOST=\"$NAS_HOST\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_PORT=\"22\"|NAS_PORT=\"$NAS_PORT\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_USER=\"CHANGE_ME\"|NAS_USER=\"$NAS_USER\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_PATH=\"CHANGE_ME\"|NAS_PATH=\"$NAS_PATH\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|NAS_SSH_KEY=\"CHANGE_ME\"|NAS_SSH_KEY=\"$NAS_SSH_KEY\"|" "$HOME/scripts/wsms-config.sh"
sed -i "s|\$HOME|$HOME|g" "$HOME/scripts/wsms-config.sh"

chmod +x "$HOME/scripts/wsms-config.sh"
source "$HOME/scripts/wsms-config.sh"
echo -e "${GREEN}✅ Configuration generated${NC}"

# ==================== PHASE 4: DEPLOY SCRIPTS ====================
echo -e "\n${BLUE}📝 Phase 4: Deploying 20 operational modules...${NC}"

deploy() { 
    echo -e "   📦 ${CYAN}$1${NC}"
    local target_script="$HOME/scripts/$1"
    cat > "$target_script"

    # Inject standard live logging bootstrap into WSMS scripts.
    if grep -q 'source "\$HOME/scripts/wsms-config.sh"' "$target_script"; then
        sed -i '/source "\$HOME\/scripts\/wsms-config.sh"/a\
wsms_init_live_logging
' "$target_script"
    fi

    chmod +x "$target_script"
}

# -----------------------------------------------------------------
# SCRIPT 1: server-health-audit.sh
# -----------------------------------------------------------------
deploy "server-health-audit.sh" << 'EOFAUDIT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - ENHANCED EXECUTIVE DIAGNOSTICS
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS v4.3${NC}"
echo "=========================================================="
echo -e "⏰ Timestamp: $(date)"
echo -e "💻 Host: $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"

# ============================================
# SYSTEM LOAD
# ============================================
echo -e "\n${CYAN}📈 SYSTEM LOAD & RESOURCES:${NC}"
echo "   CPU Cores:    $(nproc)"
echo "   Uptime:       $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory:       " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used (" $7 " available)"}'

# ============================================
# STORAGE
# ============================================
echo -e "\n${CYAN}💾 STORAGE AUDIT:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'

# ============================================
# NETWORK
# ============================================
echo -e "\n${CYAN}🌐 NETWORK EXPOSURE:${NC}"
echo "   Primary IP: $(hostname -I | awk '{print $1}')"
echo "   Listening Services:"
ss -tulpn 2>/dev/null | grep -E ":(80|443|22|3306)" | head -5 | sed 's/^/   /'

# ============================================
# CORE SERVICES STATUS
# ============================================
echo -e "\n${CYAN}🛠️  CORE SERVICES STATUS:${NC}"

# Check Nginx
if systemctl is-active --quiet nginx; then
    echo -e "   ${GREEN}✅ Nginx: Active${NC}"
elif systemctl list-unit-files | grep -q nginx; then
    echo -e "   ${RED}❌ Nginx: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Nginx: Not installed${NC}"
fi

# Check Apache
if systemctl is-active --quiet apache2; then
    echo -e "   ${GREEN}✅ Apache2: Active${NC}"
elif systemctl list-unit-files | grep -q apache2; then
    echo -e "   ${RED}❌ Apache2: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Apache2: Not installed${NC}"
fi

# Check MySQL/MariaDB
if systemctl is-active --quiet mysql; then
    echo -e "   ${GREEN}✅ MySQL: Active${NC}"
elif systemctl is-active --quiet mariadb; then
    echo -e "   ${GREEN}✅ MariaDB: Active${NC}"
elif systemctl list-unit-files | grep -qE "mysql|mariadb"; then
    echo -e "   ${RED}❌ Database: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Database: Not installed${NC}"
fi

# Check SSH
if systemctl is-active --quiet ssh; then
    echo -e "   ${GREEN}✅ SSH: Active${NC}"
else
    echo -e "   ${RED}❌ SSH: Stopped${NC}"
fi

# ============================================
# PHP-FPM STATUS
# ============================================
echo -e "\n${CYAN}🔌 PHP-FPM STATUS:${NC}"
PHP_VERSIONS=$(systemctl list-units --type=service --state=active --no-legend 2>/dev/null | grep -E 'php[0-9.]+-fpm.service' | awk '{print $1}' | sed 's/.service//')

if [ -n "$PHP_VERSIONS" ]; then
    echo -e "   ${GREEN}✅ Active PHP-FPM pools:${NC}"
    for php in $PHP_VERSIONS; do
        echo "      📦 $php"
    done
    echo "   🔌 Active Sockets:"
    sudo ls -la /run/php/ 2>/dev/null | grep -E "\.sock$" | head -5 | sed 's/^/      /'
else
    echo -e "   ${RED}❌ No active PHP-FPM pools detected${NC}"
fi

# ============================================
# PHP-FPM USERS
# ============================================
echo -e "\n${CYAN}👥 PHP-FPM USERS:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if id "$user" &>/dev/null; then
        echo -e "   ${GREEN}✅${NC} $name: $user"
    else
        echo -e "   ${RED}❌${NC} $name: $user (missing)"
    fi
done

# ============================================
# DOMAIN REACHABILITY
# ============================================
echo -e "\n${CYAN}🔗 DOMAIN REACHABILITY:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "   ${GREEN}✅${NC} $name (HTTP $http_code)"
    else
        echo -e "   ${RED}❌${NC} $name (HTTP $http_code - unreachable)"
    fi
done

# ============================================
# MANAGED WORDPRESS SITES
# ============================================
echo -e "\n${CYAN}🌐 MANAGED WORDPRESS SITES:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        site_php=$(sudo -u "$user" wp --path="$path" eval "echo PHP_VERSION;" 2>/dev/null || echo "unknown")
        db_name=$(sudo -u "$user" wp --path="$path" db query "SELECT DATABASE()" --skip-column-names 2>/dev/null || echo "unknown")
        plugins_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        themes_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        
        echo "      Core: v$wp_ver | PHP: $site_php"
        echo "      DB: $db_name"
        
        total_updates=$((plugins_updates + themes_updates))
        if [ "$total_updates" -gt 0 ]; then
            echo -e "      Updates: ${YELLOW}$total_updates pending${NC} (Plugins: $plugins_updates, Themes: $themes_updates)"
        else
            echo -e "      Updates: ${GREEN}All patched${NC}"
        fi
    else 
        echo -e "      ${RED}CRITICAL: Config missing${NC}"
    fi
done

# ============================================
# BACKUP REPOSITORY STATUS
# ============================================
echo -e "\n${CYAN}💾 BACKUP REPOSITORY STATUS:${NC}"
total_archives=0

for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
        total_archives=$((total_archives + count))
    fi
done

# ============================================
# ROLLBACK SNAPSHOTS
# ============================================
echo -e "\n${CYAN}📸 ROLLBACK SNAPSHOTS AVAILABLE:${NC}"
snapshot_total=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count snapshots (Latest: $latest)"
        snapshot_total=$((snapshot_total + snapshot_count))
    fi
done
if [ "$snapshot_total" -eq 0 ]; then
    echo "   No rollback snapshots found"
fi

# ============================================
# RECOMMENDATIONS
# ============================================
echo -e "\n${YELLOW}🔔 OPERATIONAL RECOMMENDATIONS:${NC}"
echo "----------------------------------------------------------"

# Check Nginx/Apache
if ! systemctl is-active --quiet nginx && ! systemctl is-active --quiet apache2; then
    echo -e "   ${RED}⚠️ CRITICAL: No web server running! Run: sudo systemctl start nginx${NC}"
fi

# Check disk space
disk_usage=$(df /home 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$disk_usage" ] && [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
    echo -e "   ⚠️  ${RED}CRITICAL: Disk usage at ${disk_usage}% - run backup-emergency!${NC}"
fi

# Check backups
if [ "$total_archives" -eq 0 ]; then
    echo -e "   ⚠️  ${RED}ALERT: No backups found! Run wp-backup-full${NC}"
fi

# Check rollback snapshots
if [ "$snapshot_total" -eq 0 ]; then
    echo -e "   ℹ️  ADVICE: No rollback snapshots. Run 'wp-snapshot all' before updates${NC}"
fi

echo -e "\n${GREEN}✅ INFRASTRUCTURE AUDIT COMPLETE${NC}"
EOFAUDIT

# -----------------------------------------------------------------
# SCRIPT 2: wp-fleet-status-monitor.sh
# -----------------------------------------------------------------
deploy "wp-fleet-status-monitor.sh" << 'EOFFLEET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - WORDPRESS FLEET STATUS MONITOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 WORDPRESS FLEET STATUS v4.3${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        updates_plugins=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        updates_themes=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        total_updates=$((updates_plugins + updates_themes))
        
        # Sprawdzanie HTTP/HTTPS z ignorowaniem SSL i follow redirects
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
            status_icon="${GREEN}✅${NC}"
        else
            status_icon="${RED}❌ (HTTP $http_code)${NC}"
        fi
        
        echo -e "   $status_icon $name: Core v$ver | ${YELLOW}Updates: $total_updates${NC} (Plugins: $updates_plugins, Themes: $updates_themes)"
    else
        echo -e "   ${RED}❌ $name: Environment Error at $path${NC}"
    fi
done

echo ""
echo -e "${CYAN}📸 ROLLBACK SNAPSHOTS AVAILABLE:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count snapshots (Latest: $latest)"
    fi
done
EOFFLEET

# -----------------------------------------------------------------
# SCRIPT 3: wp-multi-instance-audit.sh
# -----------------------------------------------------------------
deploy "wp-multi-instance-audit.sh" << 'EOFAUDIT2'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - MULTI-INSTANCE DEEP AUDIT
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 INITIATING MULTI-SITE DEEP AUDIT v4.3${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- Audit for: $name ---${NC}"
    
    if [ -f "$path/wp-config.php" ]; then
        echo -e "\n${CYAN}📊 Database Status:${NC}"
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Database OK" || echo "   ⚠️ Database check failed"
        
        echo -e "\n${CYAN}📦 Plugins with Updates:${NC}"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=table 2>/dev/null)
        if [ -n "$updates" ]; then
            echo "$updates"
        else
            echo "   ${GREEN}✅ All plugins up to date${NC}"
        fi
        
        echo -e "\n${CYAN}🎨 Themes with Updates:${NC}"
        theme_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=table 2>/dev/null)
        if [ -n "$theme_updates" ]; then
            echo "$theme_updates"
        else
            echo "   ${GREEN}✅ All themes up to date${NC}"
        fi
        
        echo -e "\n${CYAN}🔒 Security Quick Check:${NC}"
        wp_config_perms=$(stat -c "%a" "$path/wp-config.php" 2>/dev/null)
        if [ "$wp_config_perms" = "640" ] || [ "$wp_config_perms" = "600" ]; then
            echo "   ${GREEN}✅ wp-config.php permissions: $wp_config_perms${NC}"
        else
            echo "   ${RED}⚠️ wp-config.php permissions: $wp_config_perms (should be 640)${NC}"
        fi
        
        if grep -q "WP_DEBUG.*true" "$path/wp-config.php" 2>/dev/null; then
            echo "   ${RED}⚠️ WP_DEBUG is enabled (security risk)${NC}"
        else
            echo "   ${GREEN}✅ WP_DEBUG is disabled${NC}"
        fi
        
    else
        echo -e "   ${RED}❌ Configuration missing at $path${NC}"
    fi
done

echo -e "\n${GREEN}✅ DEEP AUDIT COMPLETE${NC}"
EOFAUDIT2

# -----------------------------------------------------------------
# SCRIPT 4: wp-automated-maintenance-engine.sh
# -----------------------------------------------------------------
deploy "wp-automated-maintenance-engine.sh" << 'EOFMAINT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - FLEET-WIDE MAINTENANCE ENGINE
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "🔄 MAINTENANCE ENGINE v4.3 - $(date)"
echo "=========================================================="

success_count=0
fail_count=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Processing: $name"
    
    if [ -f "$path/wp-config.php" ]; then
        echo "   📸 Creating pre-update snapshot..."
        bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null
        
        echo "   ⚙️ Updating core..."
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        
        echo "   ⚙️ Updating plugins..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Updating themes..."
        sudo -u "$user" wp --path="$path" theme update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Updating database..."
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        
        echo "   ⚙️ Flushing cache..."
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$name" 2>/dev/null || echo "000")
        if [ "$http_code" = "000" ]; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
        fi
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            echo -e "   ${GREEN}✅ $name updated successfully (HTTP $http_code)${NC}"
            ((success_count++))
        else
            echo -e "   ${RED}❌ $name may have issues (HTTP $http_code) - rolling back...${NC}"
            bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name" 2>/dev/null
            ((fail_count++))
        fi
    else
        echo -e "   ${RED}❌ Failed: Config missing at $path${NC}"
        ((fail_count++))
    fi
done

echo -e "\n${CYAN}📊 MAINTENANCE SUMMARY:${NC}"
echo "   ✅ Successful: $success_count site(s)"
echo "   ❌ Failed: $fail_count site(s)"
echo "   ⏰ Completed: $(date)"
echo -e "${GREEN}✅ MAINTENANCE CYCLE COMPLETE${NC}"
EOFMAINT

# -----------------------------------------------------------------
# SCRIPT 5: infrastructure-permission-orchestrator.sh
# -----------------------------------------------------------------
deploy "infrastructure-permission-orchestrator.sh" << 'EOFPERM'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - INFRASTRUCTURE PERMISSION ORCHESTRATOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

LOG_FILE="$LOG_PERMISSIONS"

# Function to log AND display
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log "=========================================================="
log "🔐 PERMISSION FIX - $(date)"
log "=========================================================="

# Stop web server temporarily
WEB_SERVER=""
if systemctl is-active --quiet nginx; then
    WEB_SERVER="nginx"
elif systemctl is-active --quiet apache2; then
    WEB_SERVER="apache2"
fi

if [ -n "$WEB_SERVER" ]; then
    log "⏸️  Stopping $WEB_SERVER..."
    sudo systemctl stop "$WEB_SERVER" 2>/dev/null || true
fi

fixed_count=0
error_count=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    log ""
    log "${YELLOW}Fixing permissions for $name (User: $user)${NC}"
    
    if [ -d "$path" ]; then
        # Ownership
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        
        # Directory permissions
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        
        # File permissions
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        
        # Secure wp-config.php
        if [ -f "$path/wp-config.php" ]; then
            sudo chmod 640 "$path/wp-config.php" 2>/dev/null
            log "   ✅ wp-config.php secured (640)"
        fi
        
        # Secure .htaccess
        if [ -f "$path/.htaccess" ]; then
            sudo chmod 644 "$path/.htaccess" 2>/dev/null
        fi
        
        # Set ACL for backup access if available
        if command -v setfacl &>/dev/null; then
            sudo setfacl -R -m "u:$USER:r-x" "$path" 2>/dev/null || true
            # wp-config.php must not have execute bit — override ACL to r-- so stat reports 640 not 650
            if [ -f "$path/wp-config.php" ]; then
                sudo setfacl -m "u:$USER:r--" "$path/wp-config.php" 2>/dev/null || true
            fi
            log "   ✅ ACL set for user $USER"
        fi
        
        log "   ${GREEN}✅ $name permissions fixed${NC}"
        ((fixed_count++))
    else
        log "   ${RED}❌ Directory $path not found${NC}"
        ((error_count++))
    fi
done

# Restart web server
if [ -n "$WEB_SERVER" ]; then
    log ""
    log "▶️  Starting $WEB_SERVER..."
    sudo systemctl start "$WEB_SERVER" 2>/dev/null || true
fi

log ""
log "${GREEN}==========================================================${NC}"
log "${GREEN}✅ PERMISSIONS FIXED: $fixed_count site(s)${NC}"
if [ $error_count -gt 0 ]; then
    log "${RED}❌ ERRORS: $error_count site(s)${NC}"
fi
log "${GREEN}==========================================================${NC}"
EOFPERM

# -----------------------------------------------------------------
# SCRIPT 6: wp-full-recovery-backup.sh
# -----------------------------------------------------------------
deploy "wp-full-recovery-backup.sh" << 'EOFFULL'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - FULL RECOVERY BACKUP
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_FULL_BACKUP"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "💾 FULL BACKUP v4.3 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📦 Snapshotting $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    
    if [ -f "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Full backup created: $size${NC}"
    else
        echo "   ❌ Failed to create full backup"
    fi
done

echo -e "\n🧹 Cleaning old backups (older than $RETENTION_FULL days)..."
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime "+$RETENTION_FULL" -delete 2>/dev/null

echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ FULL BACKUP CYCLE COMPLETED${NC}"
EOFFULL

# -----------------------------------------------------------------
# SCRIPT 7: wp-essential-assets-backup.sh
# -----------------------------------------------------------------
deploy "wp-essential-assets-backup.sh" << 'EOFLITE'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - ESSENTIAL ASSETS BACKUP (LITE)
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_LITE_BACKUP"
wsms_init_live_logging "$LOG_FILE"

echo "=========================================================="
echo "⚡ LITE BACKUP v4.3 - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📁 Archiving $name assets..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php .htaccess 2>/dev/null
    
    if [ -f "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" | cut -f1)
        echo "   ${GREEN}✅ Lite backup created: $size${NC}"
    fi
done

echo -e "\n🧹 Cleaning old lite backups (older than $RETENTION_LITE days)..."
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime "+$RETENTION_LITE" -delete 2>/dev/null

echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ LITE BACKUP CYCLE COMPLETED${NC}"
EOFLITE

# -----------------------------------------------------------------
# SCRIPT 8: mysql-backup-manager.sh
# -----------------------------------------------------------------
deploy "mysql-backup-manager.sh" << 'EOFMYSQL'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - MYSQL BACKUP MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_MYSQL_BACKUP"
wsms_init_live_logging "$LOG_FILE"

if [ "$target" = "list" ]; then
    echo -e "${YELLOW}📋 Available MySQL Backups:${NC}"
    echo "=========================================================="
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        count=$(find "$BACKUP_MYSQL_DIR" -name "db-$name-*.sql.gz" 2>/dev/null | wc -l)
        latest=$(ls -t "$BACKUP_MYSQL_DIR"/db-$name-*.sql.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null)
        echo "   📂 $name: $count backups (Latest: ${latest:-none})"
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
                echo "   ${GREEN}✅ Database backup for $name: $size${NC}"
            else
                echo "   ${RED}❌ Failed to backup database for $name${NC}"
            fi
        else
            echo "   ${YELLOW}⚠️ wp-config.php not found for $name${NC}"
        fi
    fi
done

find "$BACKUP_MYSQL_DIR" -name "*.sql.gz" -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
EOFMYSQL

# -----------------------------------------------------------------
# SCRIPT 9: nas-sftp-sync.sh
# -----------------------------------------------------------------
deploy "nas-sftp-sync.sh" << 'EOFNAS'
#!/bin/bash
# =================================================================
# WSMS PRO - NAS SFTP SYNC (Production)
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
    echo "❌ ERROR: Missing NAS configuration"
    echo "[$ts] ERROR: Missing NAS configuration" >> "$LOG_FILE"
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
log_success() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${GREEN}[$ts] ✅ $1${NC}"; echo "[$ts] SUCCESS: $1" >> "$LOG_FILE"; }
log_warning() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${YELLOW}[$ts] ⚠️ $1${NC}"; echo "[$ts] WARNING: $1" >> "$LOG_FILE"; }
log_error() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${RED}[$ts] ❌ $1${NC}"; echo "[$ts] ERROR: $1" >> "$LOG_FILE"; }

get_file_age_days() {
    local filename="$1"
    if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        local file_date="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        local file_timestamp=$(date -d "$file_date" +%s 2>/dev/null || echo 0)
        echo $(( ( $(date +%s) - file_timestamp ) / 86400 ))
    else
        echo 0
    fi
}

# Funkcja do tworzenia folderu na NAS
ensure_remote_dir() {
    local remote_dir="$1"
    
    # Sprawdź czy folder istnieje
    if echo "ls \"$remote_dir\"" 2>/dev/null | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -q "remote_dir"; then
        return 0
    fi
    
    # Tworzymy foldery po kolei
    local current_path=""
    IFS='/' read -ra parts <<< "$remote_dir"
    
    for part in "${parts[@]}"; do
        [ -z "$part" ] && continue
        current_path="$current_path/$part"
        echo "mkdir \"$current_path\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null
    done
    
    return 0
}

sync_directory() {
    local dir_name="$1"
    local local_dir="$LOCAL_BASE_DIR/$dir_name"
    local remote_dir="$REMOTE_BASE_DIR/$dir_name"
    
    log_info "📂 Processing: $dir_name"
    
    if [ ! -d "$local_dir" ]; then
        mkdir -p "$local_dir"
        log_warning "Created local directory: $local_dir"
    fi
    
    local file_count=$(ls -1 "$local_dir" 2>/dev/null | wc -l)
    if [ "$file_count" -eq 0 ]; then
        log_warning "No files in $dir_name - skipping"
        return 0
    fi
    
    log_info "Found $file_count file(s) locally"
    
    # Upewnij się że folder na NAS istnieje
    ensure_remote_dir "$remote_dir"
    
    # Pobierz listę plików z NAS
    local remote_files=$(echo "ls -1 \"$remote_dir\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local uploaded=0; local existing=0; local failed=0
    
    for file in $(ls -1 "$local_dir"); do
        if echo "$remote_files" | grep -q "^$file$"; then
            echo -e "   ${YELLOW}⏭️ Already exists: $file${NC}"
            ((existing++))
        else
            echo -e "   ${CYAN}📤 Uploading: $file${NC}"
            if echo "put \"$local_dir/$file\" \"$remote_dir/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${GREEN}✅ Uploaded: $file${NC}"
                ((uploaded++))
            else
                echo -e "   ${RED}❌ Failed: $file${NC}"
                ((failed++))
            fi
        fi
    done
    
    TOTAL_UPLOADED=$((TOTAL_UPLOADED + uploaded))
    TOTAL_EXISTING=$((TOTAL_EXISTING + existing))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    # Analiza wieku plików na NAS
    local remote_files_list=$(echo "ls -1 \"$remote_dir\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local age_new=0; local age_medium=0; local age_old=0; local age_archive=0
    
    for file in $remote_files_list; do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        if [ "$age" -le 14 ]; then ((age_new++))
        elif [ "$age" -le 30 ]; then ((age_medium++))
        elif [ "$age" -le $DAYS_TO_KEEP ]; then ((age_old++))
        else ((age_archive++)); fi
    done
    
    # Czyszczenie starych plików
    local keep_count=0; local deleted=0
    
    for file in $(echo "$remote_files_list" | sort -r); do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        
        if [ $keep_count -lt $MIN_KEEP_COPIES ]; then
            ((keep_count++))
        elif [ $age -gt $DAYS_TO_KEEP ]; then
            if echo "rm \"$remote_dir/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${RED}🗑️ Deleted old: $file (age: ${age}d)${NC}"
                ((deleted++))
            fi
        else
            ((keep_count++))
        fi
    done
    
    TOTAL_DELETED=$((TOTAL_DELETED + deleted))
    
    echo ""
    echo -e "   📊 ${CYAN}Summary for $dir_name:${NC}"
    echo -e "      Uploaded: ${GREEN}$uploaded${NC} | Existing: ${YELLOW}$existing${NC} | Failed: ${RED}$failed${NC}"
    echo -e "      Deleted: ${RED}$deleted${NC}"
    echo -e "      Age: 0-14d:${GREEN}$age_new${NC} | 15-30d:${YELLOW}$age_medium${NC} | 31-${DAYS_TO_KEEP}d:${CYAN}$age_old${NC} | >${DAYS_TO_KEEP}d:${RED}$age_archive${NC}"
    echo "----------------------------------------------------"
}

main() {
    echo "=========================================================="
    echo -e "${CYAN}☁️ NAS SYNCHRONIZATION - $TIMESTAMP${NC}"
    echo "=========================================================="
    echo ""
    
    log_info "Testing SFTP connection..."
    if echo "ls" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_SERVER" >/dev/null 2>&1; then
        log_success "SFTP connection established"
    else
        log_error "Cannot connect to $REMOTE_SERVER:$REMOTE_PORT"
        exit 1
    fi
    
    log_info "Ensuring base directory: $REMOTE_BASE_DIR"
    ensure_remote_dir "$REMOTE_BASE_DIR"
    
    echo ""
    
    for dir in "${BACKUP_DIRS[@]}"; do
        sync_directory "$dir"
    done
    
    echo "=========================================================="
    echo -e "${CYAN}📊 FINAL SUMMARY${NC}"
    echo "=========================================================="
    echo -e "   Uploaded:   ${GREEN}$TOTAL_UPLOADED${NC} files"
    echo -e "   Already on NAS: ${YELLOW}$TOTAL_EXISTING${NC} files"
    echo -e "   Failed:     ${RED}$TOTAL_FAILED${NC} files"
    echo -e "   Deleted:    ${RED}$TOTAL_DELETED${NC} files"
    echo "=========================================================="
    echo -e "${GREEN}✅ NAS Sync Completed${NC}"
    echo "=========================================================="
    
    echo "[$TIMESTAMP] FINAL: U=$TOTAL_UPLOADED, E=$TOTAL_EXISTING, F=$TOTAL_FAILED, D=$TOTAL_DELETED" >> "$LOG_FILE"
}

main "$@"
EOFNAS

# -----------------------------------------------------------------
# SCRIPT 10: wp-smart-retention-manager.sh
# -----------------------------------------------------------------
deploy "wp-smart-retention-manager.sh" << 'EOFRET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - SMART RETENTION MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
wsms_init_live_logging "$LOG_FILE"

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS v4.3${NC}"
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
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE v4.3${NC}"
    echo "=========================================================="
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        if [ -d "$dir" ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "   📂 $(basename "$dir"): $size ($count files)"
        fi
    done
    
    disk_usage=$(get_disk_usage)
    echo -e "\n   💿 Total disk usage: ${disk_usage}%"
    
    if [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "   ${RED}⚠️ WARNING: Disk usage above threshold ($DISK_ALERT_THRESHOLD%)!${NC}"
        echo -e "   ${YELLOW}💡 Run 'backup-emergency' to free space urgently${NC}"
    fi
}

show_dirs() {
    echo -e "${CYAN}📁 BACKUP DIRECTORY STRUCTURE${NC}"
    echo "=========================================================="
    ls -la "$HOME"/backups-* "$HOME"/mysql-backups 2>/dev/null
}

emergency_cleanup() {
    echo -e "${RED}🚨 EMERGENCY MODE: Keeping only 2 latest copies per site!${NC}"
    echo "=========================================================="
    total_deleted_all=0
    
    normalize_backup_key() {
        local file_name="$1"
        local key="$file_name"
        key="${key%.tar.gz}"
        key="${key%.sql.gz}"
        key="${key%.gz}"
        key="${key%.zip}"
        key=$(echo "$key" | sed -E 's/[-_][0-9]{8}[-_][0-9]{6}$//; s/[-_][0-9]{8}$//')
        echo "$key"
    }

    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo -e "\n📂 Processing $(basename "$dir")..."

        mapfile -t all_files < <(find "$dir" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | sort -r)
        if [ "${#all_files[@]}" -eq 0 ]; then
            echo "   ℹ️ No files found"
            continue
        fi

        declare -A grouped_files=()
        for file in "${all_files[@]}"; do
            [ -z "$file" ] && continue
            key=$(normalize_backup_key "$file")
            grouped_files["$key"]+=$'\n'"$file"
        done

        deleted_in_dir=0
        groups_over_limit=0
        while IFS= read -r key; do
            [ -z "$key" ] && continue
            group_files=$(echo "${grouped_files[$key]}" | sed '/^$/d' | sort -r)
            count=$(echo "$group_files" | grep -c . 2>/dev/null || echo 0)

            if [ "$count" -gt 2 ]; then
                ((groups_over_limit++))
                removed=0
                while IFS= read -r old_file; do
                    [ -z "$old_file" ] && continue
                    if rm -f "$dir/$old_file" 2>/dev/null; then
                        ((removed++))
                    fi
                done < <(echo "$group_files" | tail -n +3)

                deleted_in_dir=$((deleted_in_dir + removed))
                echo "   🗑️ $key: Kept 2 latest, deleted $removed"
            fi
        done < <(printf "%s\n" "${!grouped_files[@]}" | sort)

        total_deleted_all=$((total_deleted_all + deleted_in_dir))
        echo "   📉 $(basename "$dir"): total deleted $deleted_in_dir"
        if [ "$groups_over_limit" -eq 0 ]; then
            echo "   ℹ️ Nothing to delete: every backup group already has 2 or fewer files"
        fi
    done
    
    if [ "$total_deleted_all" -eq 0 ]; then
        echo -e "${YELLOW}ℹ️ Emergency mode removed 0 files because there were no groups above 2 copies.${NC}"
        echo -e "${YELLOW}💡 If you need additional cleanup, run option 5 (standard retention) or backup-force-clean.${NC}"
    fi

    echo -e "\n${GREEN}✅ EMERGENCY CLEANUP COMPLETE${NC}"
}

force_clean() {
    usage=$(get_disk_usage)
    
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "${YELLOW}⚠️ Disk usage at ${usage}% - triggering emergency mode${NC}"
        emergency_cleanup
    else
        echo -e "${GREEN}✅ Standard cleanup: Deleting files older than retention period${NC}"
        echo "=========================================================="
        
        find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null
        echo "   🗑️ Lite backups: Deleted files older than $RETENTION_LITE days"
        
        find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null
        echo "   🗑️ Full backups: Deleted files older than $RETENTION_FULL days"
        
        find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
        echo "   🗑️ MySQL backups: Deleted files older than $RETENTION_MYSQL days"
        
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null
        echo "   🗑️ Rollback snapshots: Deleted older than $RETENTION_ROLLBACK days"
    fi
}

emergency_global_cleanup() {
    echo -e "${RED}🚨 EMERGENCY GLOBAL MODE: Keeping only 2 newest files total per directory!${NC}"
    echo "=========================================================="
    total_deleted_all=0

    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo -e "\n📂 Processing $(basename "$dir")..."

        mapfile -t all_files < <(find "$dir" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -rn | awk '{print $2}')
        total=${#all_files[@]}

        if [ "$total" -eq 0 ]; then
            echo "   ℹ️ No files found"
            continue
        fi

        if [ "$total" -le 2 ]; then
            echo "   ℹ️ Only $total file(s) present — nothing to remove"
            continue
        fi

        to_delete=("${all_files[@]:2}")
        deleted=0
        for old_file in "${to_delete[@]}"; do
            [ -z "$old_file" ] && continue
            if rm -f "$dir/$old_file" 2>/dev/null; then
                ((deleted++))
                echo "   🗑️ Removed: $old_file"
            fi
        done

        total_deleted_all=$((total_deleted_all + deleted))
        echo "   📉 $(basename "$dir"): kept 2 newest, deleted $deleted"
    done

    echo -e "\n${GREEN}✅ EMERGENCY GLOBAL CLEANUP COMPLETE — total deleted: $total_deleted_all${NC}"
}

interactive_clean() {
    echo -e "${CYAN}🧹 INTERACTIVE CLEANUP MODE${NC}"
    echo "=========================================================="
    show_size
    echo ""
    echo -e "${YELLOW}What would you like to clean?${NC}"
    echo "   1) Lite backups (older than $RETENTION_LITE days)"
    echo "   2) Full backups (older than $RETENTION_FULL days)"
    echo "   3) MySQL backups (older than $RETENTION_MYSQL days)"
    echo "   4) Rollback snapshots (older than $RETENTION_ROLLBACK days)"
    echo "   5) ALL (standard retention)"
    echo "   6) EMERGENCY (keep only 2 latest per site)"
    echo "   7) EMERGENCY GLOBAL (keep only 2 newest total per dir)"
    echo "   0) Cancel"
    echo ""
    read -p "Enter choice [0-7]: " choice
    
    case $choice in
        1) find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null && echo "✅ Lite backups cleaned" ;;
        2) find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null && echo "✅ Full backups cleaned" ;;
        3) find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null && echo "✅ MySQL backups cleaned" ;;
        4) find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null && echo "✅ Rollback snapshots cleaned" ;;
        5) force_clean ;;
        6) emergency_cleanup ;;
        7) emergency_global_cleanup ;;
        0) echo "Cancelled." ;;
        *) echo "Invalid choice." ;;
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
        echo "Usage: $0 {list|size|dirs|clean|force-clean|emergency|emergency-global}"
        echo ""
        echo "Commands:"
        echo "  list, l              - List all backups with details"
        echo "  size, s              - Show storage usage per directory"
        echo "  dirs, d              - Show directory structure"
        echo "  clean, c             - Interactive cleanup"
        echo "  force-clean, f       - Automatic cleanup based on retention"
        echo "  emergency, e         - Keep only 2 latest copies per site"
        echo "  emergency-global, eg - Keep only 2 newest files total per directory"
        ;;
esac
EOFRET

# -----------------------------------------------------------------
# SCRIPT 11: wp-help.sh
# -----------------------------------------------------------------
deploy "wp-help.sh" << 'EOFHELP'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - COMPLETE SERVER MANAGEMENT REFERENCE
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║          🆘 WSMS PRO v4.3 — COMMAND REFERENCE              ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}⏰ $(date) │ 📦 v4.3 │ 🖥️  $(hostname)${NC}"
echo ""

# ============================================
# SECTION 1: SYSTEM DIAGNOSTICS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔍 SYSTEM DIAGNOSTICS                                      │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Full overview (CPU, RAM, services, backups)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Quick health check (disk, services, WP-CLI)"
printf "  ${GREEN}%-22s${NC} %s\n" "system-diag" "Operating system diagnostics"
echo ""

# ============================================
# SECTION 2: WORDPRESS FLEET
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🌐 WORDPRESS FLEET MANAGEMENT                              │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "All sites: versions + pending updates"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-audit" "Deep audit: DB, plugins, themes, security"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-cli-validator" "Test WP-CLI connectivity for all sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fix-perms" "Fix file permissions and ACLs"
echo ""

# ============================================
# SECTION 3: BACKUP MANAGEMENT
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  💾 BACKUP MANAGEMENT                                       │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${YELLOW}  Create Backups:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-lite" "Fast: themes, plugins, uploads, config"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-full" "Complete: all files + database"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-all" "All WordPress databases"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-ui" "Interactive backup menu"
printf "    ${GREEN}%-20s${NC} %s\n" "red-robin" "Emergency full system state capture"
echo ""
echo -e "${YELLOW}  View Backups:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-list" "List all backups with size and date"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-size" "Storage usage per directory"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-dirs" "Show directory structure"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-list" "List database backups"
echo ""
echo -e "${YELLOW}  Cleanup:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-clean" "Interactive (with confirmation)"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-force-clean" "Automatic by retention policy"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency" "EMERGENCY: keep only 2 latest per site"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency-global" "EMERGENCY GLOBAL: keep only 2 newest total per dir"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean" "Clean old logs and temp files"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean-force" "Force-clean with empty log removal"
echo ""

# ============================================
# SECTION 4: REMOTE SYNC (NAS)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ☁️  REMOTE SYNC (NAS)                                       │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync" "Manual sync to NAS"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-status" "Show last sync status"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-logs" "View sync logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-errors" "View sync errors (live)"
echo ""

# ============================================
# SECTION 5: UPDATES & MAINTENANCE
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 UPDATES & MAINTENANCE                                   │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "RECOMMENDED: Backup → Snapshot → Update"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-all" "Update all sites (skips backup)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update" "Alias for wp-update-all"
echo ""

# ============================================
# SECTION 6: ROLLBACK SYSTEM
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 ROLLBACK SYSTEM — NEW in v4.3                           │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}  Instant recovery from failed updates!${NC}"
echo ""
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshot all" "Create snapshots for ALL sites"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshot [site]" "Create snapshot for one site"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-snapshots" "List all snapshots"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-rollback [site]" "Restore to LATEST snapshot"
printf "  ${GREEN}%-24s${NC} %s\n" "wp-rollback-clean [d]" "Clean old snapshots (default: 30 days)"
echo ""
echo -e "${YELLOW}  Examples:${NC}"
echo "     wp-snapshot mysite"
echo "     wp-rollback mysite"
echo "     wp-rollback mysite 20260419_143022"
echo ""

# ============================================
# SECTION 7: SECURITY
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🛡️  SECURITY                                                │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-scan" "Daily quick scan (/var/www, /home)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-deep-scan" "Full system scan"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-status" "ClamAV service status"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-update" "Update virus definitions (freshclam)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-logs" "View ClamAV scan logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-quarantine" "List quarantined files"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-clean-quarantine" "Empty quarantine directory"
echo ""

# ============================================
# SECTION 8: LOG SHORTCUTS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📝 LOG SHORTCUTS (~/logs/wsms/)                            │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "logs-backup" "Live tail: backup logs"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-update" "Live tail: update logs"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-sync" "Live tail: NAS sync logs"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-scan" "Live tail: malware scan logs"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-all" "List all log directories"
echo ""

# ============================================
# SECTION 9: TROUBLESHOOTING
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🚨 TROUBLESHOOTING                                         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${RED}%-30s${NC} %s\n" "Site down after update:" "wp-rollback [site]"
printf "  ${RED}%-30s${NC} %s\n" "Low disk space:" "backup-emergency (per site) / backup-emergency-global (most aggressive)"
printf "  ${RED}%-30s${NC} %s\n" "Permission errors:" "wp-fix-perms"
printf "  ${RED}%-30s${NC} %s\n" "Suspected malware:" "clamav-deep-scan"
printf "  ${RED}%-30s${NC} %s\n" "NAS sync failed:" "nas-sync-status; nas-sync-errors"
printf "  ${RED}%-30s${NC} %s\n" "WP-CLI broken:" "wp-cli-validator"
printf "  ${RED}%-30s${NC} %s\n" "Check all services:" "wp-health"
echo ""

# ============================================
# SECTION 10: PER-SITE COMMANDS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🎯 PER-SITE COMMANDS                                       │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-$name" "WP-CLI for $name"
done
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-$name" "Lite backup for $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot-$name" "Snapshot for $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-$name" "Rollback for $name"
    echo ""
done

# ============================================
# SECTION 11: OTHER
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📦 OTHER COMMANDS                                          │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "red-robin" "Emergency full system backup"
printf "  ${GREEN}%-22s${NC} %s\n" "wsms-clean" "Clean old logs and temp files"
printf "  ${GREEN}%-22s${NC} %s\n" "scripts-dir" "List scripts directory"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-hosts-sync" "Sync all configured domains to /etc/hosts"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "This reference"
echo ""

# ============================================
# FOOTER
# ============================================
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.3 — READY FOR OPERATIONS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}📚 Docs: ~/scripts/ │ 🐛 Issues: github.com/maleclukas-prog${NC}"
echo -e "${WHITE}👤 Maintainer: Lukasz Malec${NC}"
echo ""
EOFHELP

# -----------------------------------------------------------------
# SCRIPT 12: wp-interactive-backup-tool.sh
# -----------------------------------------------------------------
deploy "wp-interactive-backup-tool.sh" << 'EOFINTER'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🎯 INTERACTIVE BACKUP"
echo "0) All sites"
i=1; declare -A site_map
for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; echo "$i) $name"; site_map[$i]="$site"; ((i++)); done
read -p "Choice: " choice
[[ "$choice" == "0" ]] && bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" && exit
IFS=':' read -r name path user <<< "${site_map[$choice]}"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"
echo "✅ Backup complete"
EOFINTER

# -----------------------------------------------------------------
# SCRIPT 13: standalone-mysql-backup-engine.sh
# -----------------------------------------------------------------
deploy "standalone-mysql-backup-engine.sh" << 'EOFSTAND'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOFSTAND

# -----------------------------------------------------------------
# SCRIPT 14: red-robin-system-backup.sh
# -----------------------------------------------------------------
deploy "red-robin-system-backup.sh" << 'EOFROBIN'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="$HOME/backups-"* /etc /var/log /home 2>/dev/null
echo "✅ System backup: $OUT"
EOFROBIN

# -----------------------------------------------------------------
# SCRIPT 15: clamav-auto-scan.sh
# -----------------------------------------------------------------
deploy "clamav-auto-scan.sh" << 'EOFCLAM'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_CLAMAV_SCAN"
echo "--- Scan: $(date) ---" | sudo tee -a "$LOG_FILE"
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a "$LOG_FILE"
EOFCLAM

# -----------------------------------------------------------------
# SCRIPT 16: clamav-full-scan.sh
# -----------------------------------------------------------------
deploy "clamav-full-scan.sh" << 'EOFFULLCLAM'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_CLAMAV_FULL"
sudo clamscan -r --infected --move="$QUARANTINE_DIR" --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee "$LOG_FILE"
echo "✅ Full scan complete"
EOFFULLCLAM

# -----------------------------------------------------------------
# SCRIPT 17: wp-cli-infrastructure-validator.sh
# -----------------------------------------------------------------
deploy "wp-cli-infrastructure-validator.sh" << 'EOFCLI'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🧪 WP-CLI VALIDATOR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    sudo -u "$user" wp --path="$path" core version &>/dev/null && echo "✅ $name" || echo "❌ $name"
done
EOFCLI

# -----------------------------------------------------------------
# SCRIPT 18: wp-rollback.sh
# -----------------------------------------------------------------
deploy "wp-rollback.sh" << 'EOFROLLBACK'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - ROLLBACK ENGINE
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
    [ -z "$site_config" ] && { echo "Site not found"; return 1; }
    IFS=':' read -r name path user <<< "$site_config"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_path="$ROLLBACK_DIR/$name/$timestamp"
    mkdir -p "$snapshot_path"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    cp "$BACKUP_MYSQL_DIR/db-$name-"*.sql.gz "$snapshot_path/" 2>/dev/null
    tar -czf "$snapshot_path/files.tar.gz" -C "$path" wp-content/plugins wp-content/themes wp-includes wp-admin 2>/dev/null
    echo -e "${GREEN}✅ Snapshot: $snapshot_path${NC}"
}

list_snapshots() {
    echo -e "${CYAN}📸 Snapshots for $1:${NC}"
    [ -d "$ROLLBACK_DIR/$1" ] && ls -td "$ROLLBACK_DIR/$1"/*/ 2>/dev/null | while read s; do echo "  📁 $(basename "$s")"; done
}

perform_rollback() {
    local site_config=$(get_site_config "$1")
    IFS=':' read -r name path user <<< "$site_config"
    local snapshot_path=$(ls -td "$ROLLBACK_DIR/$name"/*/ 2>/dev/null | head -1)
    [ ! -d "$snapshot_path" ] && { echo "No snapshot found"; return 1; }
    echo -e "${YELLOW}🔄 Rolling back $name...${NC}"
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
    echo -e "${GREEN}✅ Rollback complete${NC}"
}

case "${1:-}" in
    snapshot) [ "$2" = "all" ] && for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; create_snapshot "$name"; done || create_snapshot "$2" ;;
    rollback) perform_rollback "$2" ;;
    list) list_snapshots "$2" ;;
    clean) find "$ROLLBACK_DIR" -type d -mtime +$RETENTION_ROLLBACK -exec rm -rf {} \; 2>/dev/null; echo "✅ Cleaned" ;;
    *) echo "Usage: wp-rollback {snapshot|rollback|list|clean} [site]" ;;
esac
EOFROLLBACK

# -----------------------------------------------------------------
# SCRIPT 19: wp-hosts-sync.sh
# -----------------------------------------------------------------
deploy "wp-hosts-sync.sh" << 'EOFHOSTS'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - LOCAL HOSTS SYNC
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

HOSTS_FILE="/etc/hosts"
MARKER_START="# >>> WSMS LOCAL HOSTS >>>"
MARKER_END="# <<< WSMS LOCAL HOSTS <<<"

if [ "${#SITES[@]}" -eq 0 ]; then
    echo -e "${RED}❌ No sites found in SITES configuration${NC}"
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
        echo -e "${YELLOW}⚠️ Skipping invalid domain in SITES: $name${NC}"
    fi
done

if [ "${#domains[@]}" -eq 0 ]; then
    echo -e "${RED}❌ No valid domains to add to hosts${NC}"
    exit 1
fi

echo -e "${CYAN}🌐 Hosts sync summary:${NC}"
echo "   Sites configured: ${#SITES[@]}"
echo "   Domains to map:  ${#domains[@]}"

TMP_BLOCK="$(mktemp)"
TMP_HOSTS="$(mktemp)"

{
    echo "$MARKER_START"
    echo "# Local redirects for WordPress sites (bypass external DNS)"
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
    echo -e "${GREEN}✅ Hosts synced successfully${NC}"
    echo "   Backup: $BACKUP_FILE"
else
    echo -e "${RED}❌ Failed to update $HOSTS_FILE${NC}"
    rm -f "$TMP_BLOCK" "$TMP_HOSTS" "${TMP_HOSTS}.new"
    exit 1
fi

rm -f "$TMP_BLOCK" "$TMP_HOSTS" "${TMP_HOSTS}.new"
EOFHOSTS

# -----------------------------------------------------------------
# SCRIPT 20: wsms-clean.sh
# -----------------------------------------------------------------
deploy "wsms-clean.sh" << 'EOFCLEAN'
#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - SYSTEM CLEANUP SCRIPT
# Description: Cleans old logs, backups, and temporary files
# Usage: ./wsms-clean.sh [--force]
# =================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.3 - SYSTEM CLEANUP                       ${NC}"
echo -e "${CYAN}==========================================================${NC}"

cd ~ || exit 1

echo -e "\n${YELLOW}📝 Cleaning old logs from home directory...${NC}"
OLD_LOGS=("aliases.fish" "backup-cron.log" "backup_sync.log" "clamav-full.log" "clamav-scan.log" "clamav-update.log" "update-cron.log" "nas-sync.log" "retention.log" "security-scan.log" "updates.log" "install_log.txt" "crontab_backup.txt")
deleted_logs=0
for file in "${OLD_LOGS[@]}"; do
    if [ -f "$file" ]; then rm -f "$file"; echo "   🗑️  $file"; ((deleted_logs++)); fi
done
[ $deleted_logs -eq 0 ] && echo "   ✅ No old logs found" || echo -e "   ${GREEN}✅ Deleted $deleted_logs old log file(s)${NC}"

echo -e "\n${YELLOW}💻 Cleaning excessive .bashrc backups...${NC}"
bashrc_backups=$(ls -t .bashrc.backup.* 2>/dev/null)
bashrc_count=$(echo "$bashrc_backups" | grep -c . 2>/dev/null || echo 0)
if [ "$bashrc_count" -gt 1 ]; then
    echo "$bashrc_backups" | tail -n +2 | while read -r file; do [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"; done
    echo -e "   ${GREEN}✅ Kept newest .bashrc.backup, deleted $((bashrc_count - 1)) old copies${NC}"
else
    echo "   ✅ No excessive .bashrc backups"
fi

echo -e "\n${YELLOW}⏰ Cleaning excessive crontab backups...${NC}"
crontab_backups=$(ls -t crontab*.txt 2>/dev/null)
crontab_count=$(echo "$crontab_backups" | grep -c . 2>/dev/null || echo 0)
if [ "$crontab_count" -gt 1 ]; then
    echo "$crontab_backups" | tail -n +2 | while read -r file; do [ -n "$file" ] && rm -f "$file" && echo "   🗑️  $file"; done
    echo -e "   ${GREEN}✅ Kept newest crontab backup, deleted $((crontab_count - 1)) old copies${NC}"
else
    echo "   ✅ No excessive crontab backups"
fi

echo -e "\n${YELLOW}📂 Cleaning old scripts backup directories...${NC}"
deleted_dirs=0
for dir in scripts-backup-old scripts_copy_* scripts-backup; do
    if [ -d "$dir" ]; then rm -rf "$dir"; echo "   🗑️  $dir/"; ((deleted_dirs++)); fi
done
[ $deleted_dirs -eq 0 ] && echo "   ✅ No old directories found" || echo -e "   ${GREEN}✅ Deleted $deleted_dirs old directories${NC}"

echo -e "\n${YELLOW}📦 Cleaning temporary files...${NC}"
deleted_temp=0
for pattern in "*.sql" "*.tmp" "*.temp" "*_BACKUP_*" "*_backup_*" ".bashrc.swp" ".config/fish/config.fish.swp"; do
    for file in $pattern; do [ -f "$file" ] && rm -f "$file" && echo "   🗑️  $file" && ((deleted_temp++)); done 2>/dev/null
done
[ $deleted_temp -eq 0 ] && echo "   ✅ No temporary files found" || echo -e "   ${GREEN}✅ Deleted $deleted_temp temporary file(s)${NC}"

echo -e "\n${YELLOW}📦 Checking for old installer files...${NC}"
deleted_installers=0
for file in install_wsms.sh install_wsms_pl.sh wsms-uninstall.sh uninstall.sh; do
    if [ -f "$file" ]; then
        if [ "$FORCE_MODE" = true ]; then rm -f "$file"; echo "   🗑️  $file"; ((deleted_installers++))
        else echo -e "   ${YELLOW}⚠️  $file (use --force to remove)${NC}"; fi
    fi
done
[ $deleted_installers -gt 0 ] && echo -e "   ${GREEN}✅ Deleted $deleted_installers old installer file(s)${NC}"

echo -e "\n${YELLOW}📝 Checking for empty log files...${NC}"
if [ -d "$HOME/logs/wsms" ]; then
    empty_logs=$(find "$HOME/logs/wsms" -name "*.log" -type f -empty 2>/dev/null)
    if [ -n "$empty_logs" ]; then
        if [ "$FORCE_MODE" = true ]; then
            echo "$empty_logs" | while read -r file; do rm -f "$file"; echo "   🗑️  $file (empty)"; done
        else echo -e "   ${YELLOW}⚠️  Empty log files found (use --force to remove)${NC}"; echo "$empty_logs" | head -5 | sed 's/^/      /'; fi
    else echo "   ✅ No empty log files"; fi
fi

echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ CLEANUP COMPLETE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo -e "\n${YELLOW}💡 Tip: Use --force to remove old installer files and empty logs${NC}"

EOFCLEAN

echo -e "${GREEN}✅ All 20 modules deployed${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Installing shell aliases...${NC}"

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
    echo -e "   ✅ Bash aliases installed"
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
    echo -e "   🐟 Fish aliases installed"
else
    log_warning "Fish shell not detected - fish aliases skipped"
    echo -e "   ${CYAN}Tip:${NC} Install with: sudo apt-get install -y fish"
fi

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Phase 6: Configuring crontab...${NC}"
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
echo -e "${GREEN}✅ Crontab configured (9 tasks)${NC}"

# ==================== PHASE 7: PERMISSIONS ====================
log_step "Phase 7: Setting script permissions"
chmod +x "$HOME/scripts/"*.sh 2>/dev/null && log_success "All scripts in ~/scripts/ set to executable"
echo -e "${GREEN}✅ Permissions set${NC}"

# ==================== FINAL SUMMARY ====================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.3 INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "   📂 Scripts: ~/scripts/"
echo "   💾 Backups: ~/backups-lite, ~/backups-full"
echo "   📸 Rollback: ~/backups-rollback"
echo "   📝 Logs: ~/logs/wsms/"
echo "   🐚 Shell: $CURRENT_SHELL"
echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
if [ "$CURRENT_SHELL" = "fish" ]; then
    echo "   source ~/.config/fish/config.fish"
else
    echo "   source ~/.bashrc"
fi
echo "   wp-status"
echo "   wp-help"
echo ""
echo -e "${GREEN}✅ Ready!${NC}"