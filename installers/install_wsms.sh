#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.2 - UNIVERSAL INSTALLER
# Version: 4.2 | Works in any shell (Bash, Fish, Zsh, Sh)
# Author: Lukasz Malec / GitHub: maleclukas-prog
# License: MIT
# Description: Complete WordPress Server Management System installer
# =================================================================

set -eE
trap 'echo -e "${RED}❌ Installation failed at line $LINENO${NC}"; exit 1' ERR

# Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; WHITE='\033[1;37m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.2 - UNIVERSAL INSTALLER                  ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Works in Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

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
echo -e "\n${BLUE}📂 Phase 1: Initializing directory infrastructure...${NC}"

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
    mkdir -p "$dir" && echo -e "   ✅ $dir"
done

# System directories (require sudo)
sudo mkdir -p /var/quarantine /var/log/clamav 2>/dev/null || true
sudo chown "$USER":"$USER" /var/log/clamav 2>/dev/null || true
sudo chmod 755 /var/quarantine 2>/dev/null || true

echo -e "${GREEN}✅ Infrastructure ready${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}📦 Phase 2: Installing dependencies...${NC}"
sudo apt-get update -qq

PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
echo -e "   Installing: $PACKAGES"
sudo apt-get install -y $PACKAGES 2>/dev/null || true

# Install WP-CLI if missing
if ! command -v wp &> /dev/null; then
    echo -e "   📦 Installing WP-CLI..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
    echo -e "   ✅ WP-CLI installed"
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
# WSMS PRO v4.2 - CENTRAL CONFIGURATION
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
RETENTION_ROLLBACK=7

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
sed -i "s|SITES=.*|SITES=(\n$(for site in "${MANAGED_SITES[@]}"; do echo "    \"$site\""; done)\n)|" "$HOME/scripts/wsms-config.sh"
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
echo -e "\n${BLUE}📝 Phase 4: Deploying 18 operational modules...${NC}"

deploy() { 
    echo -e "   📦 ${CYAN}$1${NC}"
    cat > "$HOME/scripts/$1"
    chmod +x "$HOME/scripts/$1"
}

# -----------------------------------------------------------------
# SCRIPT 1: server-health-audit.sh
# -----------------------------------------------------------------
deploy "server-health-audit.sh" << 'EOFAUDIT'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ENHANCED EXECUTIVE DIAGNOSTICS
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS v4.2${NC}"
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
# WSMS PRO v4.2 - WORDPRESS FLEET STATUS MONITOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 WORDPRESS FLEET STATUS v4.2${NC}"
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
# WSMS PRO v4.2 - MULTI-INSTANCE DEEP AUDIT
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 INITIATING MULTI-SITE DEEP AUDIT v4.2${NC}"
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
# WSMS PRO v4.2 - FLEET-WIDE MAINTENANCE ENGINE
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔄 MAINTENANCE ENGINE v4.2 - $(date)"
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
# WSMS PRO v4.2 - INFRASTRUCTURE PERMISSION ORCHESTRATOR
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
# WSMS PRO v4.2 - FULL RECOVERY BACKUP
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_FULL_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "💾 FULL BACKUP v4.2 - $(date)"
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
# WSMS PRO v4.2 - ESSENTIAL ASSETS BACKUP (LITE)
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'

LOG_FILE="$LOG_LITE_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "⚡ LITE BACKUP v4.2 - $(date)"
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
# WSMS PRO v4.2 - MYSQL BACKUP MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_MYSQL_BACKUP"
exec >> "$LOG_FILE" 2>&1

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
# WSMS PRO v4.2 - NAS SFTP SYNC
# =================================================================

source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_NAS_SYNC"
ERROR_LOG="$LOG_NAS_ERRORS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "☁️ NAS SYNC - $(date)"
echo "=========================================================="

if [ ! -f "$NAS_SSH_KEY" ]; then
    echo "❌ ERROR: SSH key not found at $NAS_SSH_KEY"
    echo "$(date): SSH key missing" >> "$ERROR_LOG"
    exit 1
fi

if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
    echo "⚠️ WARNING: NAS_HOST not configured - sync skipped"
    exit 0
fi

sync_success=0
sync_fail=0

for module in backups-lite backups-full mysql-backups; do
    echo -e "\n📤 Processing $module..."
    
    if [ ! -d "$HOME/$module" ] || [ -z "$(ls -A "$HOME/$module" 2>/dev/null)" ]; then
        echo "   ⚠️ No files in $module - skipping"
        continue
    fi
    
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
mkdir -p $NAS_PATH/$module
put $HOME/$module/* $NAS_PATH/$module/
bye
SFTP_EOF
    then
        echo "   ✅ $module synced successfully"
        ((sync_success++))
    else
        echo "   ❌ $module sync FAILED"
        echo "$(date): Failed to sync $module" >> "$ERROR_LOG"
        ((sync_fail++))
    fi
done

echo -e "\n📊 SYNC SUMMARY:"
echo "   ✅ Successful: $sync_success module(s)"
echo "   ❌ Failed: $sync_fail module(s)"

echo "=========================================================="
echo "--- NAS Sync Finished: $(date) ---"
echo "=========================================================="
EOFNAS

# -----------------------------------------------------------------
# SCRIPT 10: wp-smart-retention-manager.sh
# -----------------------------------------------------------------
deploy "wp-smart-retention-manager.sh" << 'EOFRET'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SMART RETENTION MANAGER
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
LOG_FILE="$LOG_RETENTION"
exec >> "$LOG_FILE" 2>&1

get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS v4.2${NC}"
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
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE v4.2${NC}"
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
    
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n📂 Processing $(basename "$dir")..."
            
            for site in "${SITES[@]}"; do
                IFS=':' read -r name path user <<< "$site"
                
                files=$(find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r)
                count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
                
                if [ "$count" -gt 2 ]; then
                    echo "$files" | tail -n +3 | xargs rm -f 2>/dev/null
                    deleted=$((count - 2))
                    echo "   🗑️ $name: Kept 2 latest, deleted $deleted"
                fi
            done
        fi
    done
    
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
    echo "   6) EMERGENCY (keep only 2 latest)"
    echo "   0) Cancel"
    echo ""
    read -p "Enter choice [0-6]: " choice
    
    case $choice in
        1) find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null && echo "✅ Lite backups cleaned" ;;
        2) find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null && echo "✅ Full backups cleaned" ;;
        3) find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null && echo "✅ MySQL backups cleaned" ;;
        4) find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null && echo "✅ Rollback snapshots cleaned" ;;
        5) force_clean ;;
        6) emergency_cleanup ;;
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
    *) 
        echo "Usage: $0 {list|size|dirs|clean|force-clean|emergency}"
        echo ""
        echo "Commands:"
        echo "  list, l        - List all backups with details"
        echo "  size, s        - Show storage usage per directory"
        echo "  dirs, d        - Show directory structure"
        echo "  clean, c       - Interactive cleanup"
        echo "  force-clean, f - Automatic cleanup based on retention"
        echo "  emergency, e   - Keep only 2 latest copies per site"
        ;;
esac
EOFRET

# -----------------------------------------------------------------
# SCRIPT 11: wp-help.sh
# -----------------------------------------------------------------
deploy "wp-help.sh" << 'EOFHELP'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MASTER REFERENCE GUIDE
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

echo -e "${CYAN}▶ QUICK START - Most Important Commands${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Full overview: hardware + WordPress + backups"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "WordPress versions and available updates"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Safe update (Backup → Snapshot → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Create rollback snapshots for all sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Restore site to latest snapshot"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "This document"
echo ""

echo -e "${CYAN}▶ 🔄 ROLLBACK SYSTEM - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot all" "Create snapshots for ALL sites"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot [site]" "Create snapshot for specific site"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots" "List all available snapshots"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [site]" "Restore to LATEST snapshot"
echo ""

echo -e "${CYAN}▶ 💾 BACKUP MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-lite" "Fast backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-full" "Complete site snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-list" "List all backups with details"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-size" "Show backup storage usage"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-emergency" "EMERGENCY: keep only 2 latest copies"
echo ""

echo -e "${CYAN}▶ 🔧 MAINTENANCE & SECURITY${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update-all" "Update all sites"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-perms" "Fix file permissions and ACLs"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-all" "Backup all WordPress databases"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync" "Sync backups to remote NAS"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-scan" "Daily malware scan"
echo ""

echo -e "${CYAN}▶ 📝 LOG FILES (~/logs/wsms/)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "backups/lite.log" "Lite backups"
printf "  ${GREEN}%-26s${NC} %s\n" "backups/full.log" "Full backups"
printf "  ${GREEN}%-26s${NC} %s\n" "maintenance/updates.log" "WordPress updates"
printf "  ${GREEN}%-26s${NC} %s\n" "sync/nas-sync.log" "NAS sync"
echo ""

echo -e "${CYAN}▶ 🚨 INCIDENT RESPONSE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${RED}%-32s${NC} %s\n" "Site down after update:" "wp-rollback [site-name]"
printf "  ${RED}%-32s${NC} %s\n" "Low disk space:" "backup-emergency"
printf "  ${RED}%-32s${NC} %s\n" "Permission errors:" "wp-fix-perms"
printf "  ${RED}%-32s${NC} %s\n" "Suspected malware:" "clamav-deep-scan"
echo ""

echo -e "${GREEN}✅ WSMS PRO v4.2 - READY FOR OPERATIONS${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}👤 Maintainer:${NC} Lukasz Malec"
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
# WSMS PRO v4.2 - ROLLBACK ENGINE
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
# SCRIPT 19: wsms-clean.sh
# -----------------------------------------------------------------
deploy "wsms-clean.sh" << 'EOFCLEAN'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - SYSTEM CLEANUP SCRIPT
# Description: Cleans old logs, backups, and temporary files
# Usage: ./wsms-clean.sh [--force]
# =================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FORCE_MODE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🧹 WSMS PRO v4.2 - SYSTEM CLEANUP                       ${NC}"
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
for file in install_wsms.sh install_wsms.fish wsms-cleanup.fish wsms-uninstall.fish; do
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

echo -e "${GREEN}✅ All 18 modules deployed${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Installing shell aliases...${NC}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.bashrc" 2>/dev/null
    cat >> "$HOME/.bashrc" << 'EOFALIAS'

# ============================================
# WSMS PRO v4.2 - ALIASES
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
    echo -e "   ✅ Bash aliases installed"
fi

if command -v fish &>/dev/null; then
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.config/fish/config.fish" 2>/dev/null
    cat >> "$HOME/.config/fish/config.fish" << 'EOFFISH'

# ============================================
# WSMS PRO v4.2 - FISH ALIASES
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
    echo "📦 Creating backup..."
    wp-backup-lite
    and wp-snapshot all
    and wp-update-all
    and echo "✅ Update complete!"
end
echo "✅ WSMS PRO v4.2 - Fish aliases loaded!"
EOFFISH
    echo -e "   🐟 Fish aliases installed"
fi

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Phase 6: Configuring crontab...${NC}"
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
echo -e "${GREEN}✅ Crontab configured (9 tasks)${NC}"

# ==================== FINAL SUMMARY ====================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.2 INSTALLATION COMPLETE!${NC}"
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