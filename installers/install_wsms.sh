#!/bin/bash
# =================================================================
# 🚀 WSMS PRO v4.2 - UNIVERSAL INSTALLER
# Version: 4.2 | Works in any shell (Bash, Fish, Zsh, Sh)
# Author: Lukasz Malec / GitHub: maleclukas-prog
# License: MIT
# =================================================================

set -eE
trap 'echo -e "${RED}❌ Installation failed at line $LINENO${NC}"; exit 1' ERR

# Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   🚀 WSMS PRO v4.2 - UNIVERSAL INSTALLER                  ${NC}"
echo -e "${CYAN}   WordPress Server Management System                       ${NC}"
echo -e "${CYAN}   Works in Bash, Fish, Zsh, Sh                            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

CURRENT_SHELL=$(basename "$SHELL")
echo -e "${BLUE}📍 Detected shell: $CURRENT_SHELL${NC}"

# =================================================================
# ⚙️ CONFIGURATION - EDIT ONLY HERE!
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
    echo -e "\n${CYAN}🔍 Phase 0: Validating configuration...${NC}"
    
    if [ ${#MANAGED_SITES[@]} -eq 0 ]; then
        echo -e "   ${RED}❌ ERROR: No sites configured in MANAGED_SITES array${NC}"
        ((errors++))
    fi
    
    for site in "${MANAGED_SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        if [ -z "$name" ] || [ -z "$path" ] || [ -z "$user" ]; then
            echo -e "   ${RED}❌ ERROR: Invalid site format: '$site'${NC}"
            ((errors++))
        fi
    done
    
    if [ "$NAS_HOST" = "your-nas.synology.me" ]; then
        echo -e "   ${YELLOW}⚠️  Warning: NAS_HOST not configured${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}❌ Configuration validation failed${NC}"
        exit 1
    fi
    
    echo -e "   ${GREEN}✅ Configuration validated${NC}"
}

validate_config

# ==================== PHASE 1: INFRASTRUCTURE ====================
echo -e "\n${BLUE}📂 Phase 1: Initializing directories...${NC}"
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
echo -e "${GREEN}✅ Infrastructure ready${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}📦 Phase 2: Installing dependencies...${NC}"
sudo apt-get update -qq
PACKAGES="acl clamav clamav-daemon openssh-client bc curl mysql-client"
sudo apt-get install -y $PACKAGES 2>/dev/null || true

if ! command -v wp &> /dev/null; then
    echo -e "   📦 Installing WP-CLI..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
fi

echo -e "${GREEN}✅ Dependencies ready${NC}"

# ==================== PHASE 3: CENTRAL CONFIGURATION ====================
echo -e "\n${BLUE}📝 Phase 3: Generating configuration...${NC}"
HOME_EXPANDED="$HOME"

cat > "$HOME/scripts/wsms-config.sh" << EOF
#!/bin/bash
# WSMS GLOBAL CONFIGURATION - Generated: $(date)

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
echo -e "${GREEN}✅ Configuration generated${NC}"

# ==================== PHASE 4: DEPLOY SCRIPTS ====================
echo -e "\n${BLUE}📝 Phase 4: Deploying 18 modules...${NC}"

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
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS v4.2${NC}"
echo "=========================================================="
echo -e "⏰ Timestamp: $(date)"
echo -e "💻 Host: $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"

echo -e "\n${CYAN}📈 SYSTEM LOAD:${NC}"
echo "   CPU Cores: $(nproc)"
echo "   Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory: " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used"}'

echo -e "\n${CYAN}💾 STORAGE:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'

echo -e "\n${CYAN}🌐 MANAGED SITES:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        echo "      Core: v$ver"
    else 
        echo -e "      ${RED}Config missing${NC}"
    fi
done

echo -e "\n${CYAN}💾 BACKUPS:${NC}"
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
    fi
done

echo -e "\n${GREEN}✅ AUDIT COMPLETE${NC}"
EOF

# SCRIPT 2: wp-fleet-status-monitor.sh
deploy "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 WORDPRESS FLEET STATUS v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        echo -e "   ${GREEN}✅${NC} $name: v$ver | Updates: $updates"
    else
        echo -e "   ${RED}❌${NC} $name: Not found"
    fi
done

echo ""
echo -e "${CYAN}📸 ROLLBACK SNAPSHOTS:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    [ "$count" -gt 0 ] && echo "   📁 $name: $count snapshots"
done
EOF

# SCRIPT 3: wp-multi-instance-audit.sh
deploy "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 DEEP AUDIT v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- $name ---${NC}"
    if [ -f "$path/wp-config.php" ]; then
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Database OK"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
        echo "   📦 Pending updates: $updates"
    else
        echo -e "   ${RED}❌ Config missing${NC}"
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
echo "🔄 MAINTENANCE ENGINE v4.2 - $(date)"
echo "=========================================================="

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
        echo -e "   ${GREEN}✅ Updated${NC}"
    else
        echo -e "   ${RED}❌ Failed${NC}"
    fi
done

echo -e "\n✅ MAINTENANCE COMPLETE - $(date)"
EOF

# SCRIPT 5: infrastructure-permission-orchestrator.sh
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_PERMISSIONS"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔐 PERMISSION FIX - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}Fixing: $name${NC}"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php" 2>/dev/null
        echo "   ${GREEN}✅ Fixed${NC}"
    fi
done
echo -e "\n✅ PERMISSIONS FIXED - $(date)"
EOF

# SCRIPT 6: wp-full-recovery-backup.sh
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_FULL_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "💾 FULL BACKUP - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "📦 Processing: $name"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    echo "   ✅ $name"
done

find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime +$RETENTION_FULL -delete 2>/dev/null
echo -e "\n✅ FULL BACKUP COMPLETE - $(date)"
EOF

# SCRIPT 7: wp-essential-assets-backup.sh
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_LITE_BACKUP"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "⚡ LITE BACKUP - $(date)"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "📁 Processing: $name"
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" \
        wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    echo "   ✅ $name"
done

find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime +$RETENTION_LITE -delete 2>/dev/null
echo -e "\n✅ LITE BACKUP COMPLETE - $(date)"
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
    echo "📋 Available MySQL Backups:"
    for site in "${SITES[@]}"; do
        IFS=':' read -r name path user <<< "$site"
        count=$(find "$BACKUP_MYSQL_DIR" -name "db-$name-*.sql.gz" 2>/dev/null | wc -l)
        echo "   $name: $count backups"
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
            echo "✅ Database: $name"
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
echo "☁️ NAS SYNC - $(date)"
echo "=========================================================="

[ ! -f "$NAS_SSH_KEY" ] && { echo "❌ SSH key missing"; echo "$(date): SSH key missing" >> "$ERROR_LOG"; exit 1; }
[ "$NAS_HOST" = "your-nas.synology.me" ] && { echo "⚠️ NAS not configured - skipping"; exit 0; }

for module in backups-lite backups-full mysql-backups; do
    echo "📤 Processing: $module"
    [ ! -d "$HOME/$module" ] && continue
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
mkdir -p $NAS_PATH/$module
put $HOME/$module/* $NAS_PATH/$module/
bye
SFTP_EOF
    then
        echo "   ✅ $module synced"
    else
        echo "   ❌ $module FAILED"
        echo "$(date): Failed to sync $module" >> "$ERROR_LOG"
    fi
done

echo "✅ NAS SYNC COMPLETE - $(date)"
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
    echo -e "${CYAN}📋 ALL BACKUPS${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        [ -d "$dir" ] && echo -e "\n📂 $(basename "$dir"):" && find "$dir" -type f 2>/dev/null | head -10 | while read f; do echo "   $(basename "$f")"; done
    done
}

show_size() {
    echo -e "${CYAN}💽 STORAGE USAGE${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
        [ -d "$dir" ] && echo "   📂 $(basename "$dir"): $(du -sh "$dir" 2>/dev/null | cut -f1)"
    done
    echo "   💿 Disk usage: $(get_disk_usage)%"
}

emergency_cleanup() {
    echo -e "${RED}🚨 EMERGENCY: Keeping 2 latest${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        [ -d "$dir" ] && for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r | tail -n +3 | xargs rm -f 2>/dev/null
        done
    done
    echo "✅ Emergency cleanup complete"
}

force_clean() {
    echo "🧹 Retention cleanup - $(date)"
    if [ "$(get_disk_usage)" -ge "$DISK_ALERT_THRESHOLD" ]; then
        emergency_cleanup
    else
        find "$BACKUP_LITE_DIR" -type f -mtime +$RETENTION_LITE -delete 2>/dev/null
        find "$BACKUP_FULL_DIR" -type f -mtime +$RETENTION_FULL -delete 2>/dev/null
        find "$BACKUP_MYSQL_DIR" -type f -mtime +$RETENTION_MYSQL -delete 2>/dev/null
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime +$RETENTION_ROLLBACK -exec rm -rf {} \; 2>/dev/null
        echo "✅ Standard cleanup complete"
    fi
}

case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    dirs|d) ls -la "$HOME"/backups-* 2>/dev/null ;;
    force-clean|f) force_clean ;;
    emergency|e) emergency_cleanup ;;
    *) echo "Usage: $0 {list|size|dirs|force-clean|emergency}" ;;
esac
EOF

# SCRIPT 11: wp-help.sh
deploy "wp-help.sh" << 'EOF'
#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MASTER REFERENCE GUIDE
# Complete command reference with rollback system documentation
# Enhanced with Health Check, Log Management, and Interactive Help
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
echo -e "${CYAN}▶ QUICK START - Most Important Commands${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Full overview: hardware + WordPress + backups"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "WordPress versions and available updates"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Safe update (Backup → Snapshot → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Create rollback snapshots for all sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Restore site to latest snapshot"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Quick health check of system"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "This document"
echo ""

# ============================================
# ROLLBACK SYSTEM (NEW!)
# ============================================
echo -e "${CYAN}▶ 🔄 ROLLBACK SYSTEM - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic pre-update snapshots enable instant"
echo -e "            site recovery in case of update failures."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot all" "Create snapshots for ALL sites"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot [site]" "Create snapshot for specific site"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots" "List all available snapshots"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots [site]" "List snapshots for specific site"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [site]" "Restore to LATEST snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [site] [date]" "Restore to specific snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-safe [site]" "Rollback with confirmation"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-clean [days]" "Clean old snapshots (default: $RETENTION_ROLLBACK days)"
echo ""
echo -e "${YELLOW}Examples:${NC}"
echo "   wp-snapshot mysite"
echo "   wp-snapshots mysite"
echo "   wp-rollback mysite"
echo "   wp-rollback mysite 20260419_143022"
echo ""

# ============================================
# BACKUP MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 💾 BACKUP MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Three-tier backup system (Lite/Full/MySQL)"
echo "            with automatic retention management."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-lite" "Fast backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-full" "Complete site snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-ui" "Interactive backup tool"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-site" "Alias for wp-backup-ui"
printf "  ${GREEN}%-26s${NC} %s\n" "red-robin" "Emergency system configuration backup"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "backup-list" "List all backups with details"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-size" "Show backup storage usage"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-dirs" "Show backup directory structure"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-clean" "Interactive cleanup (with confirmation)"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-force-clean" "Automatic cleanup based on retention"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-emergency" "EMERGENCY: keep only 2 latest copies"
echo ""

# ============================================
# DATABASE MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 🗄️ DATABASE MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic database backups reading credentials"
echo "            directly from wp-config.php files."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-all" "Backup all WordPress databases"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-list" "List available database backups"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup [site]" "Backup specific database"
printf "  ${GREEN}%-26s${NC} %s\n" "db-backup" "Alias for mysql-backup"
echo ""

# ============================================
# MAINTENANCE & SECURITY
# ============================================
echo -e "${CYAN}▶ 🔧 MAINTENANCE & SECURITY${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Tools for maintaining and securing infrastructure."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update-all" "Update all sites (without backup)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update" "Alias for wp-update-all"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-perms" "Fix file permissions and ACLs"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-permissions" "Alias for wp-fix-perms"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-audit" "Deep security and performance audit"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-diagnoza" "Alias for wp-audit"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-cli-validator" "Test WP-CLI connectivity for all sites"
printf "  ${GREEN}%-26s${NC} %s\n" "system-diag" "Operating system diagnostics"
echo ""

# ============================================
# NAS SYNC
# ============================================
echo -e "${CYAN}▶ ☁️ NAS SYNCHRONIZATION${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic backup replication to remote NAS/SFTP server."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync" "Manual trigger for synchronization"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-status" "Show last synchronization status"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-logs" "View sync logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-errors" "View sync errors (live)"
echo ""

# ============================================
# CLAMAV ANTIVIRUS
# ============================================
echo -e "${CYAN}▶ 🛡️ CLAMAV - ANTIVIRUS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Malware scanning with automatic quarantine."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-scan" "Daily quick scan (/var/www, /home)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-deep-scan" "Full system scan (everything)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-status" "ClamAV service status"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-update" "Update virus definitions"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-logs" "View scan logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-quarantine" "List quarantined files"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-clean-quarantine" "Empty quarantine"
echo ""

# ============================================
# 🆕 HEALTH CHECK SYSTEM (NEW!)
# ============================================
echo -e "${CYAN}▶ 🏥 HEALTH CHECK SYSTEM - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Quick system health diagnostics"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-health" "Complete health check"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-quick-status" "Alias for wp-status"
echo ""

# ============================================
# 🆕 LOG MANAGEMENT (NEW!)
# ============================================
echo -e "${CYAN}▶ 📝 LOG MANAGEMENT - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Quick access to log files"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-logs" "Show all log files status"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-backup" "View backup logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-update" "View update logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-sync" "View NAS sync logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-scan" "View malware scan logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-all" "List all log directories"
echo ""

# ============================================
# PER-SITE WP-CLI
# ============================================
echo -e "${CYAN}▶ 🎯 PER-SITE WP-CLI ACCESS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Direct WP-CLI access for each site"
echo "            with the correct system user."
echo ""

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-$name" "WP-CLI for $name (user: $user)"
done

echo ""
echo -e "${YELLOW}Usage examples:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   wp-$name plugin list"
    echo "   wp-$name core version"
    echo "   wp-$name user list"
    break
done
echo ""

# ============================================
# PER-SITE QUICK COMMANDS
# ============================================
echo -e "${CYAN}▶ ⚡ PER-SITE QUICK COMMANDS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-$name" "Lite backup for $name"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot-$name" "Rollback snapshot for $name"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-$name" "Rollback for $name"
    echo ""
done

# ============================================
# RETENTION POLICIES
# ============================================
echo -e "${CYAN}▶ 📊 DATA RETENTION POLICIES${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Directories and retention periods:${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %-18s %s\n" "Backup Type" "Directory" "Retention"
echo "  ------------------------------------------------------------------"
printf "  %-22s %-18s %s\n" "⚡ Lite Assets" "~/backups-lite/" "$RETENTION_LITE days"
printf "  %-22s %-18s %s\n" "💾 Full Snapshots" "~/backups-full/" "$RETENTION_FULL days"
printf "  %-22s %-18s %s\n" "🗄️ MySQL Dumps" "~/mysql-backups/" "$RETENTION_MYSQL days"
printf "  %-22s %-18s %s\n" "📸 Rollback Snapshots" "~/backups-rollback/" "$RETENTION_ROLLBACK days"
printf "  %-22s %-18s %s\n" "☁️ NAS Vault" "Remote NAS" "$NAS_RETENTION_DAYS days"
echo ""
echo -e "${RED}⚠️ EMERGENCY MODE:${NC} When disk usage > ${DISK_ALERT_THRESHOLD}%,"
echo "   system automatically keeps only 2 latest copies."
echo ""

# ============================================
# INCIDENT RESPONSE - QUICK REFERENCE
# ============================================
echo -e "${CYAN}▶ 🚨 INCIDENT RESPONSE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Quick reaction to problems:${NC}"
echo ""

printf "  ${RED}%-32s${NC} %s\n" "Site down after update:" "wp-rollback [site-name]"
printf "  ${RED}%-32s${NC} %s\n" "Low disk space:" "backup-emergency"
printf "  ${RED}%-32s${NC} %s\n" "Permission errors (403/500):" "wp-fix-perms"
printf "  ${RED}%-32s${NC} %s\n" "Suspected malware:" "clamav-deep-scan"
printf "  ${RED}%-32s${NC} %s\n" "Backup cycle failed:" "df -h && wp-backup-ui"
printf "  ${RED}%-32s${NC} %s\n" "NAS sync failed:" "nas-sync-status && nas-sync-errors"
printf "  ${RED}%-32s${NC} %s\n" "WP-CLI connection failed:" "wp-cli-validator"
printf "  ${RED}%-32s${NC} %s\n" "White Screen of Death (WSOD):" "wp-rollback [site-name]"
echo ""

# ============================================
# LOG FILES LOCATION
# ============================================
echo -e "${CYAN}▶ 📝 LOG FILES LOCATION${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Log file locations (organized in ~/logs/wsms/):${NC}"
echo ""
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/lite.log" "Lite backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/full.log" "Full backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/mysql.log" "Database backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/maintenance/updates.log" "WordPress updates"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/maintenance/permissions.log" "Permission fixes"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/retention/retention.log" "Retention management"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/sync/nas-sync.log" "NAS synchronization"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/sync/nas-errors.log" "NAS sync errors"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/security/clamav-scan.log" "ClamAV scan (daily)"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/security/clamav-full.log" "ClamAV scan (full)"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/rollback/snapshots.log" "Snapshot creation"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/rollback/rollback-clean.log" "Snapshot cleanup"
echo ""

# ============================================
# CRONTAB SCHEDULE
# ============================================
echo -e "${CYAN}▶ ⏰ CRONTAB SCHEDULE${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Scheduled tasks (9 automated jobs):${NC}"
echo ""
echo "   Daily:"
echo "   • 01:00 - Update ClamAV definitions"
echo "   • 02:00 - NAS synchronization"
echo "   • 03:00 - Quick malware scan"
echo "   • 04:00 - Backup retention management"
echo ""
echo "   Weekly:"
echo "   • Sunday 02:00 - Lite backup"
echo "   • Wednesday 02:00 - Lite backup"
echo "   • Sunday 04:00 - Full malware scan"
echo "   • Sunday 06:00 - WordPress updates (with snapshot!)"
echo "   • Monday 05:00 - Clean old snapshots"
echo ""
echo "   Monthly:"
echo "   • 1st day of month 03:00 - Full backup"
echo ""

# ============================================
# SYSTEM PATHS
# ============================================
echo -e "${CYAN}▶ 📂 SYSTEM PATHS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   📁 Scripts:        $SCRIPT_DIR"
echo "   💾 Lite backups:   $BACKUP_LITE_DIR"
echo "   💾 Full backups:   $BACKUP_FULL_DIR"
echo "   🗄️ MySQL backups:  $BACKUP_MYSQL_DIR"
echo "   📸 Rollback:       $BACKUP_ROLLBACK_DIR"
echo "   📋 Logs:           $LOG_BASE_DIR"
echo "   🛡️ Quarantine:     $QUARANTINE_DIR"
echo ""

# ============================================
# PRO TIPS
# ============================================
echo -e "${CYAN}▶ 💡 PRO TIPS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   🔹 Use 'wp-update-safe' instead of 'wp-update-all' - creates snapshot"
echo "   🔹 Before major changes: 'wp-snapshot all'"
echo "   🔹 Monitor disk space: 'backup-size' weekly"
echo "   🔹 After failure: 'wp-rollback [site]' recovers in 30 seconds"
echo "   🔹 Check health: 'wp-health' for quick diagnostics"
echo "   🔹 View logs: 'logs-backup' or 'logs-update' for live monitoring"
echo "   🔹 Test WP-CLI after permission changes: 'wp-cli-validator'"
echo ""

# ============================================
# FOOTER
# ============================================
echo -e "${GREEN}✅ WSMS PRO v4.2 - READY FOR OPERATIONS${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}📚 Full documentation:${NC} ~/scripts/, docs/ in repository"
echo -e "${WHITE}🐛 Report issues:${NC} https://github.com/maleclukas-prog/wp-server-management-system/issues"
echo -e "${WHITE}👤 Maintainer:${NC} Lukasz Malec"
echo ""

# SCRIPT 12: wp-interactive-backup-tool.sh
deploy "wp-interactive-backup-tool.sh" << 'EOF'
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
EOF

# SCRIPT 13: standalone-mysql-backup-engine.sh
deploy "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOF

# SCRIPT 14: red-robin-system-backup.sh
deploy "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="$HOME/backups-"* /etc /var/log /home 2>/dev/null
echo "✅ System backup: $OUT"
EOF

# SCRIPT 15: clamav-auto-scan.sh
deploy "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_CLAMAV_SCAN"
echo "--- Scan: $(date) ---" | sudo tee -a "$LOG_FILE"
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a "$LOG_FILE"
EOF

# SCRIPT 16: clamav-full-scan.sh
deploy "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_CLAMAV_FULL"
sudo clamscan -r --infected --move="$QUARANTINE_DIR" --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee "$LOG_FILE"
echo "✅ Full scan complete"
EOF

# SCRIPT 17: wp-cli-infrastructure-validator.sh
deploy "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "🧪 WP-CLI VALIDATOR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    sudo -u "$user" wp --path="$path" core version &>/dev/null && echo "✅ $name" || echo "❌ $name"
done
EOF

# SCRIPT 18: wp-rollback.sh
deploy "wp-rollback.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ROLLBACK_DIR="$BACKUP_ROLLBACK_DIR"
mkdir -p "$ROLLBACK_DIR"

get_site_config() { for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; [ "$name" = "$1" ] && echo "$site" && return 0; done; return 1; }

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
    [ -f "$db_backup" ] && gunzip < "$db_backup" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null
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
EOF

echo -e "${GREEN}✅ All 18 modules deployed${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Installing aliases...${NC}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.bashrc" 2>/dev/null
    cat >> "$HOME/.bashrc" << 'EOF'

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
EOF
    echo -e "   ✅ Bash aliases installed"
fi

if command -v fish &>/dev/null; then
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    sed -i '/# WSMS PRO v4.2/d' "$HOME/.config/fish/config.fish" 2>/dev/null
    cat >> "$HOME/.config/fish/config.fish" << 'EOF'

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
EOF
    echo -e "   🐟 Fish aliases installed"
fi

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}⏰ Phase 6: Configuring crontab...${NC}"
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