#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - MASTER INSTALLATION ORCHESTRATOR (ENGLISH)
# Version: 4.2 (Full Production Ready)
# Description: Complete automated deployment of WSMS infrastructure
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

set -e

# =================================================================
# ⚙️ INFRASTRUCTURE CONFIGURATION - EDIT ONLY HERE!
# Format: "Identifier:PathToPublicHtml:SystemUser"
# =================================================================
MANAGED_SITES=(
    "example-site:/var/www/example-site/public_html:example_user"
    "demo-site:/var/www/demo-site/public_html:demo_user"
)

# Synology NAS Settings (UPDATE WITH YOUR VALUES)
NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="your_username"
NAS_PATH="/homes/your_username/server_backups"
NAS_SSH_KEY="$HOME/.ssh/nas_key"
# =================================================================

# UI Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   WSMS PRO - MASTER INSTALLER (ENGLISH v4.2)              ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# ==================== PHASE 1: INFRASTRUCTURE ====================
echo -e "\n${BLUE}📂 Phase 1: Initializing Infrastructure...${NC}"
DIRS=("$HOME/scripts" "$HOME/backups-lite" "$HOME/backups-full" 
      "$HOME/backups-manual" "$HOME/mysql-backups" "$HOME/logs" "$HOME/backups-rollback")
for dir in "${DIRS[@]}"; do
    mkdir -p "$dir" && echo -e "   ✅ $dir"
done

sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}🔍 Phase 2: Installing Dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon openssh-client bc curl rsync -qq
if ! command -v wp &> /dev/null; then
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi
echo -e "${GREEN}✅ Dependencies verified.${NC}"

# ==================== PHASE 3: CENTRAL CONFIG ====================
echo -e "\n${BLUE}📝 Phase 3: Generating central configuration...${NC}"
cat > "$HOME/scripts/wsms-config.sh" << EOF
#!/bin/bash
# =================================================================
# 🧠 WSMS GLOBAL CONFIGURATION - Generated: $(date)
# =================================================================

# WordPress Sites - Format: "name:/path/to/public_html:system_user"
SITES=(
$(for site in "${MANAGED_SITES[@]}"; do echo "    \"$site\""; done)
)

# Synology NAS Configuration
NAS_HOST="$NAS_HOST"
NAS_PORT="$NAS_PORT"
NAS_USER="$NAS_USER"
NAS_PATH="$NAS_PATH"
NAS_SSH_KEY="$NAS_SSH_KEY"

# Backup Retention (Days)
RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
RETENTION_ROLLBACK=30
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2

# System Thresholds
DISK_ALERT_THRESHOLD=80

# Paths
SCRIPT_DIR="\$HOME/scripts"
BACKUP_LITE_DIR="\$HOME/backups-lite"
BACKUP_FULL_DIR="\$HOME/backups-full"
BACKUP_MANUAL_DIR="\$HOME/backups-manual"
BACKUP_MYSQL_DIR="\$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="\$HOME/backups-rollback"
LOG_DIR="\$HOME/logs"
QUARANTINE_DIR="/var/quarantine"
CLAMAV_LOG_DIR="/var/log/clamav"

# Export all variables
export SITES NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL RETENTION_ROLLBACK
export NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR
export BACKUP_MYSQL_DIR BACKUP_ROLLBACK_DIR LOG_DIR
export QUARANTINE_DIR CLAMAV_LOG_DIR
EOF

chmod +x "$HOME/scripts/wsms-config.sh"
echo -e "   ✅ Config saved: ~/scripts/wsms-config.sh"
echo -e "   📋 Managed sites: ${#MANAGED_SITES[@]}"

# ==================== PHASE 4: DEPLOY ALL SCRIPTS ====================
echo -e "\n${BLUE}📝 Phase 4: Deploying Core Modules...${NC}"

deploy() { echo -e "   📦 ${CYAN}$1${NC}"; cat > "$HOME/scripts/$1"; chmod +x "$HOME/scripts/$1"; }

# 1. SYSTEM DIAGNOSTICS
deploy "server-health-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS DASHBOARD${NC}"
echo "=========================================================="
echo -e "⏰ Audit Timestamp: $(date)"
echo -e "💻 System Host:    $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"
echo -e "\n${CYAN}📈 SYSTEM LOAD & RESOURCES:${NC}"
echo "   CPU Cores:    $(nproc)"
echo "   Uptime:       $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory:       " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used"}'
echo -e "\n${CYAN}💾 STORAGE AUDIT:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v tmpfs | sed 's/^/   /'
echo -e "\n${CYAN}🛠️  CORE SERVICES STATUS:${NC}"
for s in nginx apache2 mysql mariadb ssh; do
    status=$(systemctl is-active "$s" 2>/dev/null || echo "not installed")
    if [ "$status" = "active" ]; then
        echo -e "   ✅ $s: ${GREEN}Active${NC}"
    elif [ "$status" != "not installed" ]; then
        echo -e "   ❌ $s: ${RED}$status${NC}"
    fi
done
echo -e "\n${CYAN}🌐 MANAGED WORDPRESS FLEET:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        id "$user" &>/dev/null && echo -e "      - Status: ${GREEN}Active${NC} | WP: v$wp_ver" || echo -e "      - Status: ${RED}User missing!${NC}"
    else 
        echo -e "      - ${RED}CRITICAL: Config missing!${NC}"
    fi
done
echo -e "\n${CYAN}💾 BACKUP STATUS:${NC}"
total=0
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
        total=$((total + count))
    fi
done
disk_usage=$(df /home 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$total" -eq 0 ]; then
    echo -e "   ${RED}⚠️ ALERT: No backups found! Run 'wp-backup-lite'${NC}"
fi
if [ -n "$disk_usage" ] && [ "$disk_usage" -ge 80 ]; then
    echo -e "   ${RED}⚠️ CRITICAL: Disk usage at ${disk_usage}%${NC}"
fi
echo -e "\n${GREEN}✅ INFRASTRUCTURE AUDIT COMPLETE${NC}"
EOF

# 2. FLEET STATUS MONITOR
deploy "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "${CYAN}📊 WORDPRESS FLEET INVENTORY AUDIT${NC}"
echo "=========================================================="
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        updates_plugins=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        updates_themes=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        total_updates=$((updates_plugins + updates_themes))
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            status_icon="${GREEN}✅${NC}"
        else
            status_icon="${RED}❌${NC}"
        fi
        echo -e "   $status_icon $name: Core v$ver | ${YELLOW}Updates: $total_updates${NC}"
    else
        echo -e "   ${RED}❌ $name: Environment Error at $path${NC}"
    fi
done
echo ""
echo -e "${CYAN}📸 ROLLBACK SNAPSHOTS:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $count snapshots (Latest: $latest)"
    fi
done
EOF

# 3. DEEP AUDIT
deploy "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "${CYAN}🔍 DEEP INFRASTRUCTURE AUDIT${NC}"
echo "=========================================================="
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- $name ---${NC}"
    if [ -f "$path/wp-config.php" ]; then
        echo -e "${CYAN}📊 Database:${NC}"
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Database OK" || echo "   ⚠️ Database issues"
        echo -e "${CYAN}📦 Plugins needing updates:${NC}"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=table 2>/dev/null)
        if [ -n "$updates" ]; then echo "$updates"; else echo "   ✅ All plugins up to date"; fi
        echo -e "${CYAN}🔒 Security:${NC}"
        wp_config_perms=$(stat -c "%a" "$path/wp-config.php" 2>/dev/null)
        if [ "$wp_config_perms" = "640" ] || [ "$wp_config_perms" = "600" ]; then
            echo "   ✅ wp-config.php permissions: $wp_config_perms"
        else
            echo "   ⚠️ wp-config.php permissions: $wp_config_perms (should be 640)"
        fi
    else
        echo -e "   ${RED}❌ wp-config.php missing${NC}"
    fi
done
echo -e "\n${GREEN}✅ DEEP AUDIT COMPLETE${NC}"
EOF

# 4. MAINTENANCE ENGINE
deploy "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
echo -e "${CYAN}🔄 FLEET-WIDE MAINTENANCE ENGINE STARTED${NC}"
echo "=========================================================="
echo -e "⏰ Started: $(date)"
success=0; fail=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🔄 Processing: $name${NC}"
    if [ -f "$path/wp-config.php" ]; then
        echo "   📸 Creating pre-update snapshot..."
        bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null
        echo "   ⚙️ Updating core..."
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        echo "   ⚙️ Updating plugins..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        echo "   ⚙️ Updating database..."
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        echo "   ⚙️ Flushing cache..."
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            echo -e "   ${GREEN}✅ $name updated successfully (HTTP $http_code)${NC}"
            ((success++))
        else
            echo -e "   ${RED}❌ $name may have issues (HTTP $http_code) - rolling back...${NC}"
            bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name" 2>/dev/null
            ((fail++))
        fi
    else
        echo -e "   ${RED}❌ wp-config.php not found${NC}"
        ((fail++))
    fi
done
echo -e "\n${CYAN}📊 SUMMARY:${NC}"
echo -e "   ${GREEN}✅ Successful: $success${NC}"
echo -e "   ${RED}❌ Failed: $fail${NC}"
echo -e "${GREEN}✅ MAINTENANCE CYCLE COMPLETE${NC}"
EOF

# 5. PERMISSION ORCHESTRATOR
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
echo -e "${BLUE}🔐 SECURITY PERMISSIONS ORCHESTRATOR${NC}"
echo "=========================================================="
WEB_SERVER=""
systemctl is-active --quiet nginx && WEB_SERVER="nginx"
systemctl is-active --quiet apache2 && WEB_SERVER="apache2"
[ -n "$WEB_SERVER" ] && { echo "⏸️ Stopping $WEB_SERVER..."; sudo systemctl stop "$WEB_SERVER" 2>/dev/null || true; }
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🔧 Fixing $name (User: $user)${NC}"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php" 2>/dev/null && echo "   ✅ wp-config.php secured"
        command -v setfacl &>/dev/null && sudo setfacl -R -m "u:$USER:r-x" "$path" 2>/dev/null && echo "   ✅ ACL set"
        echo -e "   ${GREEN}✅ Permissions fixed${NC}"
    else
        echo -e "   ${YELLOW}⚠️ Directory not found${NC}"
    fi
done
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
    [ -d "$dir" ] && sudo chown -R "$USER":"$USER" "$dir" 2>/dev/null && sudo chmod 755 "$dir" 2>/dev/null
done
[ -n "$WEB_SERVER" ] && { echo -e "\n▶️ Starting $WEB_SERVER..."; sudo systemctl start "$WEB_SERVER" 2>/dev/null || true; }
echo -e "\n${GREEN}✅ SECURITY POLICIES APPLIED${NC}"
EOF

# 6. FULL BACKUP
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${BLUE}💾 FULL FLEET SNAPSHOT${NC}"
echo "=========================================================="
echo -e "⏰ Started: $(date)"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📦 Snapshotting $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
    if [ -f "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" | cut -f1)
        echo -e "   ${GREEN}✅ Full backup created: $size${NC}"
    else
        echo -e "   ${RED}❌ Failed to create backup${NC}"
    fi
done
echo -e "\n🧹 Cleaning old backups (older than $RETENTION_FULL days)..."
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime "+$RETENTION_FULL" -delete 2>/dev/null
echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ FULL BACKUP COMPLETE${NC}"
EOF

# 7. LITE BACKUP
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${BLUE}⚡ LEAN ASSETS BACKUP${NC}"
echo "=========================================================="
echo -e "⏰ Started: $(date)"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n📁 Archiving $name assets..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php .htaccess 2>/dev/null
    if [ -f "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" ]; then
        size=$(du -h "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" | cut -f1)
        echo -e "   ${GREEN}✅ Lite backup created: $size${NC}"
    fi
done
echo -e "\n🧹 Cleaning old backups (older than $RETENTION_LITE days)..."
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime "+$RETENTION_LITE" -delete 2>/dev/null
echo -e "\n⏰ Completed: $(date)"
echo -e "${GREEN}✅ LITE BACKUP COMPLETE${NC}"
EOF

# 8. MYSQL MANAGER
deploy "mysql-backup-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
target="${1:-all}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
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
                echo -e "   ${GREEN}✅ Database backup for $name: $size${NC}"
            else
                echo -e "   ${RED}❌ Failed to backup database for $name${NC}"
            fi
        else
            echo -e "   ${YELLOW}⚠️ wp-config.php not found for $name${NC}"
        fi
    fi
done
find "$BACKUP_MYSQL_DIR" -name "*.sql.gz" -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
EOF

# 9. NAS SYNC (ENGLISH)
deploy "nas-sftp-sync.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
echo ""
echo "=========================================================="
echo -e "${CYAN}☁️ NAS SYNCHRONIZATION - $(date)${NC}"
echo "=========================================================="
if [ ! -f "$NAS_SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found: $NAS_SSH_KEY${NC}"
    exit 1
fi
sync_success=0; sync_fail=0
for module in backups-lite backups-full backups-manual mysql-backups; do
    echo -e "\n${CYAN}📤 Processing: $module${NC}"
    if [ ! -d "$HOME/$module" ] || [ -z "$(ls -A "$HOME/$module" 2>/dev/null)" ]; then
        echo -e "   ${YELLOW}⚠️ No files - skipping${NC}"
        continue
    fi
    echo -e "   📁 Found $(ls -1 "$HOME/$module" | wc -l) file(s)"
    if sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << EOF
mkdir -p $NAS_PATH/$module
cd $NAS_PATH/$module
lcd $HOME/$module
mput *
bye
EOF
    then
        echo -e "   ${GREEN}✅ $module synced successfully${NC}"
        ((sync_success++))
    else
        echo -e "   ${RED}❌ $module sync FAILED${NC}"
        ((sync_fail++))
    fi
done
echo ""
echo "=========================================================="
echo -e "${CYAN}📊 SYNC SUMMARY:${NC}"
echo -e "   ${GREEN}✅ Successful: $sync_success module(s)${NC}"
echo -e "   ${RED}❌ Failed: $sync_fail module(s)${NC}"
echo "=========================================================="
echo -e "${GREEN}✅ NAS Sync Finished: $(date)${NC}"
echo ""
EOF

# 10. SMART RETENTION MANAGER
deploy "wp-smart-retention-manager.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
get_disk_usage() { df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }
list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS${NC}"
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
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE${NC}"
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
        echo -e "   ${RED}⚠️ WARNING: Disk usage above threshold!${NC}"
    fi
}
force_clean() {
    usage=$(get_disk_usage)
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "${YELLOW}⚠️ Disk usage at ${usage}% - triggering emergency mode${NC}"
        for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
            if [ -d "$dir" ]; then
                for site in "${SITES[@]}"; do
                    IFS=':' read -r name path user <<< "$site"
                    files=$(find "$dir" -type f -name "*$name*" 2>/dev/null | sort -r)
                    count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
                    if [ "$count" -gt 2 ]; then
                        echo "$files" | tail -n +3 | xargs rm -f 2>/dev/null
                        echo "   🗑️ $name: Kept 2 latest"
                    fi
                done
            fi
        done
    else
        echo -e "${GREEN}✅ Standard cleanup: Deleting files older than retention period${NC}"
        find "$BACKUP_LITE_DIR" -type f -mtime "+$RETENTION_LITE" -delete 2>/dev/null
        find "$BACKUP_FULL_DIR" -type f -mtime "+$RETENTION_FULL" -delete 2>/dev/null
        find "$BACKUP_MYSQL_DIR" -type f -mtime "+$RETENTION_MYSQL" -delete 2>/dev/null
        find "$BACKUP_ROLLBACK_DIR" -type d -mtime "+$RETENTION_ROLLBACK" -exec rm -rf {} \; 2>/dev/null
        echo "   🗑️ Cleanup complete"
    fi
}
case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    clean|c) force_clean ;;
    *) echo "Usage: $0 {list|size|clean}" ;;
esac
EOF

# 11. HELP SYSTEM
deploy "wp-help.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'
clear
echo -e "${WHITE}🆘 WSMS PRO - HELP & REFERENCE${NC}"
echo -e "${WHITE}=================================================${NC}"
echo -e "${BLUE}⏰ $(date)${NC}"
echo -e "${BLUE}📋 Managed Sites: ${#SITES[@]}${NC}\n"
echo -e "${CYAN}⚡ QUICK START${NC}"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-status" "Full infrastructure overview"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-help" "This help menu"
printf "  ${GREEN}%-26s${NC} %s\n" "system-diag" "Server diagnostics"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fleet" "WordPress sites status"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update-all" "Update all sites"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-perms" "Fix permissions"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-lite" "Lite backup"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-full" "Full backup"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync" "Sync to NAS"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-clean" "Clean old backups"
echo -e "\n${CYAN}📋 DATA RETENTION POLICY${NC}"
echo -e "  ⚡ Lite backups:   ${YELLOW}$RETENTION_LITE days${NC}"
echo -e "  💾 Full backups:   ${YELLOW}$RETENTION_FULL days${NC}"
echo -e "  🗄️ MySQL backups:  ${YELLOW}$RETENTION_MYSQL days${NC}"
echo -e "  🔄 NAS retention:  ${YELLOW}$NAS_RETENTION_DAYS days${NC}"
echo -e "\n${GREEN}✅ SYSTEM READY${NC}"
EOF

# 12. INTERACTIVE BACKUP TOOL
deploy "wp-interactive-backup-tool.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${BLUE}🎯 INTERACTIVE BACKUP ENGINE${NC}"
echo "=========================================================="
echo -e "\n${CYAN}Select a site to backup:${NC}"
echo "   0) All sites"
i=1; declare -A site_map
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   $i) $name"
    site_map[$i]="$site"
    ((i++))
done
echo "   q) Quit"
echo ""; read -p "Enter choice: " choice
if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then echo "Goodbye!"; exit 0; fi
echo -e "\n${CYAN}Select backup type:${NC}"
echo "   1) Lite backup (themes, plugins, uploads, config)"
echo "   2) Full backup (complete site)"
echo "   3) Database only"
echo "   4) Rollback snapshot"
echo "   q) Quit"
echo ""; read -p "Enter choice: " backup_type
case $backup_type in
    1) [ "$choice" = "0" ] && bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" || { IFS=':' read -r name path user <<< "${site_map[$choice]}"; echo "Running Lite Backup for $name..."; bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" "$name"; } ;;
    2) [ "$choice" = "0" ] && bash "$SCRIPT_DIR/wp-full-recovery-backup.sh" || { IFS=':' read -r name path user <<< "${site_map[$choice]}"; echo "Running Full Backup for $name..."; bash "$SCRIPT_DIR/wp-full-recovery-backup.sh" "$name"; } ;;
    3) [ "$choice" = "0" ] && bash "$SCRIPT_DIR/mysql-backup-manager.sh" all || { IFS=':' read -r name path user <<< "${site_map[$choice]}"; echo "Running Database Backup for $name..."; bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"; } ;;
    4) [ "$choice" = "0" ] && bash "$SCRIPT_DIR/wp-rollback.sh" snapshot all || { IFS=':' read -r name path user <<< "${site_map[$choice]}"; echo "Creating rollback snapshot for $name..."; bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name"; } ;;
    q|Q) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice" ;;
esac
echo -e "\n${GREEN}✅ Backup operation completed!${NC}"
EOF

# 13. STANDALONE MYSQL
deploy "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
echo "⚙️ Standalone MySQL Engine: Executing global dump"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOF

# 14. RED ROBIN
deploy "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
echo "🔴 EMERGENCY SYSTEM BACKUP"
echo "=========================================================="
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="/tmp" --exclude="/run" --exclude="$HOME/backups-*" /etc /var/log /home 2>/dev/null
if [ -f "$OUT" ]; then
    size=$(du -h "$OUT" | cut -f1)
    echo -e "${GREEN}✅ System backup created: $OUT ($size)${NC}"
else
    echo -e "${RED}❌ Failed to create system backup${NC}"
fi
EOF

# 15. CLAMAV AUTO SCAN
deploy "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
LOG="/var/log/clamav/auto_scan.log"
sudo mkdir -p /var/log/clamav
echo "=== ClamAV Daily Scan - $(date) ===" | sudo tee -a $LOG
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a $LOG
echo "=== Scan Completed ===" | sudo tee -a $LOG
EOF

# 16. CLAMAV FULL SCAN
deploy "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
TS=$(date +%Y%m%d-%H%M%S)
LOG="/var/log/clamav/full_audit_$TS.log"
QUARANTINE="/var/quarantine"
echo "=== Full System Scan - $(date) ===" | sudo tee "$LOG"
sudo clamscan -r --infected --move="$QUARANTINE" --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" / 2>&1 | sudo tee -a "$LOG"
echo "=== Scan Complete: $(date) ===" | sudo tee -a "$LOG"
infected=$(grep -c "FOUND" "$LOG" 2>/dev/null || echo "0")
echo "Infected files found: $infected" | sudo tee -a "$LOG"
EOF

# 17. WP-CLI VALIDATOR
deploy "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
echo "🧪 WP-CLI VALIDATION"
echo "=========================================================="
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ${RED}❌ $name: wp-config.php not found${NC}"
        continue
    fi
    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
        echo -e "   ${GREEN}✅ $name: Connected (WP v$version)${NC}"
    else
        echo -e "   ${RED}❌ $name: WP-CLI connection failed${NC}"
    fi
done
echo -e "\n${YELLOW}📋 WP-CLI Version:${NC}"
wp --version 2>/dev/null || echo "   ❌ WP-CLI not found"
EOF

# 18. ROLLBACK ENGINE
deploy "wp-rollback.sh" << 'EOF'
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ROLLBACK_DIR="$BACKUP_ROLLBACK_DIR"; mkdir -p "$ROLLBACK_DIR"
get_site_config() { local target=$1; for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; [ "$name" = "$target" ] && { echo "$site"; return 0; }; done; return 1; }
create_snapshot() {
    local site_name=$1; local site_config=$(get_site_config "$site_name")
    [ -z "$site_config" ] && { echo -e "${RED}❌ Site '$site_name' not found${NC}"; return 1; }
    IFS=':' read -r name path user <<< "$site_config"; local timestamp=$(date +%Y%m%d_%H%M%S); local snapshot_path="$ROLLBACK_DIR/$name/$timestamp"
    echo -e "${CYAN}📸 Creating snapshot for $name...${NC}"; mkdir -p "$snapshot_path"
    echo "   📊 Backing up database..."; bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    local latest_db=$(ls -t "$BACKUP_MYSQL_DIR/db-$name-"*.sql.gz 2>/dev/null | head -1)
    [ -n "$latest_db" ] && cp "$latest_db" "$snapshot_path/" && echo "   ✅ Database backed up"
    echo "   📁 Backing up files..."; tar -czf "$snapshot_path/files.tar.gz" -C "$path" wp-content/plugins wp-content/themes wp-includes wp-admin 2>/dev/null
    echo -e "${GREEN}✅ Snapshot created${NC}"
}
list_snapshots() {
    local site_name=$1
    if [ -n "$site_name" ]; then
        echo -e "${CYAN}📸 Snapshots for $site_name:${NC}"
        [ -d "$ROLLBACK_DIR/$site_name" ] && for snapshot in $(ls -td "$ROLLBACK_DIR/$site_name"/*/ 2>/dev/null); do echo "  📁 $(basename "$snapshot") ($(du -sh "$snapshot" 2>/dev/null | cut -f1))"; done || echo "  No snapshots found"
    else
        echo -e "${CYAN}📸 All Rollback Snapshots:${NC}"
        for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; count=$(find "$ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l); [ "$count" -gt 0 ] && echo "  📂 $name: $count snapshots" || echo "  📂 $name: No snapshots"; done
    fi
}
perform_rollback() {
    local site_name=$1; local snapshot_name=$2
    local site_config=$(get_site_config "$site_name"); [ -z "$site_config" ] && { echo -e "${RED}❌ Site '$site_name' not found${NC}"; return 1; }
    IFS=':' read -r name path user <<< "$site_config"
    local snapshot_path; [ -n "$snapshot_name" ] && snapshot_path="$ROLLBACK_DIR/$name/$snapshot_name" || snapshot_path=$(ls -td "$ROLLBACK_DIR/$name"/*/ 2>/dev/null | head -1)
    [ ! -d "$snapshot_path" ] && { echo -e "${RED}❌ No snapshot found${NC}"; return 1; }
    echo -e "${YELLOW}🔄 Rolling back $name...${NC}"
    echo "   🔒 Enabling maintenance mode..."; sudo -u "$user" wp --path="$path" maintenance-mode activate 2>/dev/null
    echo "   📁 Restoring files..."; [ -f "$snapshot_path/files.tar.gz" ] && tar -xzf "$snapshot_path/files.tar.gz" -C "$path" 2>/dev/null && echo "   ✅ Files restored"
    echo "   🗄️ Restoring database..."; local db_backup=$(ls "$snapshot_path"/db-*.sql.gz 2>/dev/null | head -1)
    if [ -f "$db_backup" ]; then
        DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        gunzip < "$db_backup" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null && echo "   ✅ Database restored"
    fi
    echo "   🔓 Disabling maintenance mode..."; sudo -u "$user" wp --path="$path" maintenance-mode deactivate 2>/dev/null
    echo -e "${GREEN}✅ Rollback completed${NC}"
}
case "${1:-}" in
    snapshot) [ -z "$2" ] && { echo "Usage: wp-rollback snapshot <site|all>"; exit 1; }; [ "$2" = "all" ] && for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; create_snapshot "$name"; echo ""; done || create_snapshot "$2" ;;
    rollback) [ -z "$2" ] && { echo "Usage: wp-rollback rollback <site> [snapshot]"; exit 1; }; perform_rollback "$2" "$3" ;;
    list) list_snapshots "$2" ;;
    *) echo -e "${CYAN}🔄 WSMS ROLLBACK ENGINE${NC}"; echo "Usage: wp-rollback {snapshot|rollback|list} [site]"; exit 1 ;;
esac
EOF

echo -e "${GREEN}✅ All scripts deployed.${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Configuring Aliases...${NC}"
sed -i '/# WSMS/d' ~/.bashrc 2>/dev/null
cat >> ~/.bashrc << 'BASH_EOF'
# ==================== WSMS PRO ALIASES ==================== # WSMS
export SCRIPTS_DIR="$HOME/scripts"
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh"
alias help-wp="wp-help"
alias wp-status="system-diag && echo '' && wp-fleet && echo '' && backup-size"
alias system-diag="bash $SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash $SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias wp-cli-validator="bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh"
alias scripts-dir="ls -la $SCRIPTS_DIR"
alias wp-update-all="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all"
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias red-robin="bash $SCRIPTS_DIR/red-robin-system-backup.sh"
alias db-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh"
alias db-backup-all="db-backup all"
alias db-backup-list="db-backup list"
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean"
alias backup-size="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size"
alias backup-list="backup-size"
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh"
alias nas-sync-logs="tail -f $HOME/logs/nas_sync.log"
alias nas-sync-status="echo '📊 Last NAS sync:'; tail -20 $HOME/logs/nas_sync.log 2>/dev/null || echo 'No logs yet'"
alias clamav-scan="bash $SCRIPTS_DIR/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $SCRIPTS_DIR/clamav-full-scan.sh"
alias clamav-status="sudo systemctl status clamav-daemon --no-pager | head -15"
alias clamav-update="sudo freshclam"
alias clamav-logs="sudo tail -f /var/log/clamav/auto_scan.log"
alias clamav-quarantine="sudo ls -la /var/quarantine/"
alias clamav-clean-quarantine="sudo rm -rf /var/quarantine/* && echo '✅ Quarantine cleaned'"
alias wp-snapshot="bash $SCRIPTS_DIR/wp-rollback.sh snapshot"
alias wp-rollback="bash $SCRIPTS_DIR/wp-rollback.sh rollback"
alias wp-snapshots="bash $SCRIPTS_DIR/wp-rollback.sh list"
# Backward compatibility
alias wp-list="wp-fleet"
alias wp-diagnoza="wp-audit"
alias wp-update="wp-update-all"
alias wp-fix-permissions="wp-fix-perms"
alias mysql-backup="db-backup"
alias mysql-backup-all="db-backup all"
alias mysql-backup-list="db-backup list"
alias backup-smart-clean="backup-clean"
alias sync-backup="nas-sync"
BASH_EOF

# Fish aliases
mkdir -p ~/.config/fish
cat >> ~/.config/fish/config.fish << 'FISH_EOF'
# ==================== WSMS PRO ALIASES ==================== # WSMS
set -gx SCRIPTS_DIR "$HOME/scripts"
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh"
alias wp-status="system-diag; and echo ''; and wp-fleet; and echo ''; and backup-size"
alias system-diag="bash $SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash $SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias wp-update-all="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite; and sleep 5; and wp-update-all"
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias db-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh"
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean"
alias backup-size="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size"
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh"
alias clamav-scan="bash $SCRIPTS_DIR/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $SCRIPTS_DIR/clamav-full-scan.sh"
alias wp-snapshot="bash $SCRIPTS_DIR/wp-rollback.sh snapshot"
alias wp-rollback="bash $SCRIPTS_DIR/wp-rollback.sh rollback"
alias wp-snapshots="bash $SCRIPTS_DIR/wp-rollback.sh list"
echo "✅ WSMS PRO aliases loaded (fish)"
FISH_EOF

echo -e "${GREEN}✅ Aliases configured.${NC}"

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}🗓️ Phase 6: Scheduling Crontab...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
# --- WSMS PRO AUTOMATION SCHEDULE ---
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1 # WSMS
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas_sync.log 2>&1 # WSMS
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/security-scan.log 2>&1 # WSMS
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh clean >> $HOME/logs/retention.log 2>&1 # WSMS
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1 # WSMS
0 2 * * 0,3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1 # WSMS
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-full.log 2>&1 # WSMS
") | crontab -
echo -e "${GREEN}✅ Crontab configured.${NC}"

# ==================== FINAL SUMMARY ====================
echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ WSMS PRO DEPLOYMENT COMPLETED!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "   📋 Managed sites: ${#MANAGED_SITES[@]}"
echo -e "   🔧 Config file:   ~/scripts/wsms-config.sh"
echo ""
echo -e "${YELLOW}🚀 NEXT STEPS:${NC}"
echo -e "   1. ${CYAN}source ~/.bashrc${NC} (or open new terminal for fish)"
echo -e "   2. ${CYAN}wp-status${NC} - Verify all sites"
echo -e "   3. ${CYAN}wp-help${NC} - Command reference"
echo -e "   4. ${CYAN}wp-backup-lite${NC} - Test backup"
echo ""
echo -e "${BLUE}💡 Edit ~/scripts/wsms-config.sh to update your sites and NAS settings.${NC}"
EOF

chmod +x ~/install_wsms.sh
echo "✅ English installer created: ~/install_wsms.sh"

# Run the installer
~/install_wsms.sh