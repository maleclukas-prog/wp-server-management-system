cat > ~/install_wsms.sh << 'INSTALL_EOF'
#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - MASTER INSTALLATION ORCHESTRATOR (DYNAMIC CONFIG)
# Version: 4.0 (Full Production Ready)
# Description: Complete automated deployment of WSMS infrastructure
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

set -e

# =================================================================
# ⚙️ INFRASTRUCTURE CONFIGURATION - EDIT ONLY HERE!
# Format: "Identifier:PathToPublicHtml:SystemUser"
# =================================================================
MANAGED_SITES=(
    "Site_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_sitet"
    "Site_nick:/var/www/your_site/public_html:your_site"
)

# Synology NAS Settings
NAS_HOST="your_server_details.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admi/server_backups"
NAS_SSH_KEY="$HOME/.ssh/Your_id_rsa_KEY"
# =================================================================

# UI Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   WSMS PRO - MASTER INSTALLER (FULL VERSION 4.0)         ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# ==================== PHASE 1: INFRASTRUCTURE ====================
echo -e "\n${BLUE}📂 Phase 1: Initializing Infrastructure...${NC}"
DIRS=("$HOME/scripts" "$HOME/backups-lite" "$HOME/backups-full" 
      "$HOME/backups-manual" "$HOME/mysql-backups" "$HOME/logs")
for dir in "${DIRS[@]}"; do
    mkdir -p "$dir" && echo -e "   ✅ $dir"
done
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}🔍 Phase 2: Installing Dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon openssh-client bc curl -qq
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
# WSMS GLOBAL CONFIGURATION - Generated: $(date)

SITES=(
$(for site in "${MANAGED_SITES[@]}"; do echo "    \"$site\""; done)
)

NAS_HOST="$NAS_HOST"; NAS_PORT="$NAS_PORT"; NAS_USER="$NAS_USER"
NAS_PATH="$NAS_PATH"; NAS_SSH_KEY="$NAS_SSH_KEY"

RETENTION_LITE=14; RETENTION_FULL=35; RETENTION_MYSQL=7
NAS_RETENTION_DAYS=120; NAS_MIN_KEEP_COPIES=2
DISK_ALERT_THRESHOLD=80

SCRIPT_DIR="\$HOME/scripts"
BACKUP_LITE_DIR="\$HOME/backups-lite"; BACKUP_FULL_DIR="\$HOME/backups-full"
BACKUP_MANUAL_DIR="\$HOME/backups-manual"; BACKUP_MYSQL_DIR="\$HOME/mysql-backups"
LOG_DIR="\$HOME/logs"

export SITES NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL
export NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR LOG_DIR
EOF
chmod +x "$HOME/scripts/wsms-config.sh"
echo -e "   ✅ Config saved: ~/scripts/wsms-config.sh"
echo -e "   📋 Managed sites: ${#MANAGED_SITES[@]}"

# ==================== PHASE 4: DEPLOY SCRIPTS ====================
echo -e "\n${BLUE}📝 Phase 4: Deploying 17 Core Modules...${NC}"

deploy() { echo -e "   📦 ${CYAN}$1${NC}"; cat > "$HOME/scripts/$1"; chmod +x "$HOME/scripts/$1"; }

# 1. SYSTEM DIAGNOSTICS
deploy "server-health-audit.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
echo -e "${BLUE}🖥️ SYSTEM DIAGNOSTICS${NC}"
echo "⏰ $(date)"
echo -e "${BLUE}💻 HARDWARE:${NC}"
echo "   Host: $(hostname) | CPU: $(nproc) cores | Uptime: $(uptime -p)"
echo -e "${BLUE}💾 STORAGE:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v tmpfs | sed 's/^/   /'
echo -e "${BLUE}🌐 WORDPRESS SITES:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        echo -e "   ✅ $name: ${GREEN}Active${NC} ($user)"
    else
        echo -e "   ❌ $name: ${RED}Missing${NC}"
    fi
done
echo -e "${GREEN}✅ DIAGNOSTICS COMPLETE${NC}"
EOF

# 2. FLEET STATUS
deploy "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${CYAN}📊 WORDPRESS FLEET STATUS${NC}"
total=0; healthy=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"; ((total++))
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        plugins=$(sudo -u "$user" wp --path="$path" plugin list --format=count 2>/dev/null || echo "0")
        echo "   ✅ $name: WP $ver | $plugins plugins"
        ((healthy++))
    else
        echo "   ❌ $name: INACCESSIBLE"
    fi
done
echo -e "${CYAN}📈 SUMMARY:${NC} $healthy/$total healthy"
EOF

# 3. DEEP AUDIT
deploy "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${CYAN}🔍 DEEP INFRASTRUCTURE AUDIT${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}📁 $name${NC}"
    if [ ! -f "$path/wp-config.php" ]; then
        echo "   ❌ wp-config.php missing"; continue
    fi
    version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
    echo "   📦 Core: ${GREEN}$version${NC}"
    if sudo -u "$user" wp --path="$path" db check 2>/dev/null; then
        echo "   🗃️ Database: ${GREEN}Healthy${NC}"
    else
        echo "   🗃️ Database: ${RED}Issues${NC}"
    fi
    updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
    [ "$updates" -gt 0 ] && echo "   🔌 Updates: ${YELLOW}$updates available${NC}" || echo "   🔌 Plugins: ${GREEN}Up to date${NC}"
done
EOF

# 4. MAINTENANCE ENGINE
deploy "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${CYAN}🔄 MAINTENANCE CYCLE${NC}"
updates=0; failures=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🌐 $name${NC}"
    [ ! -f "$path/wp-config.php" ] && { echo "   ❌ Invalid"; ((failures++)); continue; }
    if sudo -u "$user" wp --path="$path" core check-update --format=count 2>/dev/null | grep -q "^[1-9]"; then
        echo "   📦 Updating core..."
        sudo -u "$user" wp --path="$path" core update --quiet && ((updates++))
    fi
    plugin_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
    if [ "$plugin_updates" -gt 0 ]; then
        echo "   🔌 Updating $plugin_updates plugins..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet
        updates=$((updates + plugin_updates))
    fi
    sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" cache flush --quiet
    echo "   ✅ Completed"
done
echo -e "\n${CYAN}📊 SUMMARY:${NC} $updates updates, $failures failures"
EOF

# 5. PERMISSION ORCHESTRATOR
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${CYAN}🛡️ PERMISSION AUDIT${NC}"
sudo systemctl stop nginx 2>/dev/null || true
for service in $(systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$'); do
    sudo systemctl stop "$service" 2>/dev/null || true
done
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 $name ($user)"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path/"
        sudo find "$path/" -type d -exec chmod 755 {} \;
        sudo find "$path/" -type f -exec chmod 644 {} \;
        [ -d "$path/wp-content" ] && sudo chmod -R 775 "$path/wp-content/"
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php"
        echo "   ✅ Permissions aligned"
    fi
done
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
    [ -d "$dir" ] && sudo chown -R "$USER":"$USER" "$dir" && sudo chmod 755 "$dir"
done
for service in $(systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$'); do
    sudo systemctl start "$service" 2>/dev/null || true
done
sudo systemctl start nginx 2>/dev/null || true
echo -e "\n${GREEN}✅ SECURITY AUDIT COMPLETED${NC}"
EOF

# 6. FULL BACKUP
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
echo "💾 FULL BACKUP - $(date)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_FULL_DIR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 $name"
    [ ! -f "$path/wp-config.php" ] && { echo "   ❌ Skipping"; continue; }
    sudo -u "$user" wp --path="$path" transient delete --expired --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" db optimize --quiet 2>/dev/null
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    ARCHIVE="$BACKUP_FULL_DIR/backup-full-$name-$TIMESTAMP.tar.gz"
    sudo tar -czf "$ARCHIVE" -C "$path" --exclude="wp-content/cache" --exclude="*.log" . 2>/dev/null
    [ -f "$ARCHIVE" ] && echo "   ✅ $(du -h "$ARCHIVE" | cut -f1)"
done
find "$BACKUP_FULL_DIR" -name "backup-full-*" -type f -mtime +$RETENTION_FULL -delete
echo -e "\n✅ FULL BACKUP COMPLETED"
EOF

# 7. LITE BACKUP
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
echo "⚡ LITE BACKUP - $(date)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_LITE_DIR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 $name"
    [ ! -f "$path/wp-config.php" ] && { echo "   ❌ Skipping"; continue; }
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    ARCHIVE="$BACKUP_LITE_DIR/backup-lite-$name-$TIMESTAMP.tar.gz"
    sudo tar -czf "$ARCHIVE" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    [ -f "$ARCHIVE" ] && echo "   ✅ $(du -h "$ARCHIVE" | cut -f1)"
done
find "$BACKUP_LITE_DIR" -name "backup-lite-*" -type f -mtime +$RETENTION_LITE -delete
echo -e "\n✅ LITE BACKUP COMPLETED"
EOF

# 8. MYSQL MANAGER
deploy "mysql-backup-manager.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
BACKUP_DIR="$BACKUP_MYSQL_DIR"; TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"
get_mysql_creds() {
    local config="$1/wp-config.php"; [ ! -f "$config" ] && return 1
    DB_NAME=$(grep -E "define.*DB_NAME" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_NAME'.*'\(.*\)'.*/\1/p" | head -1)
    DB_USER=$(grep -E "define.*DB_USER" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_USER'.*'\(.*\)'.*/\1/p" | head -1)
    DB_PASS=$(grep -E "define.*DB_PASSWORD" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=$(grep -E "define.*DB_HOST" "$config" | grep -vE "^[[:space:]]*\/\/" | sed -n "s/.*'DB_HOST'.*'\(.*\)'.*/\1/p" | head -1)
    DB_HOST=${DB_HOST:-localhost}; [ -z "$DB_NAME" ] && return 1; return 0
}
backup_site() {
    local name="$1" path="$2"
    if ! get_mysql_creds "$path"; then echo "   ❌ Failed"; return 1; fi
    local backup_file="$BACKUP_DIR/mysql-$name-$DB_NAME-$TIMESTAMP.sql.gz"
    if mysqldump --single-transaction --quick --no-tablespaces -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$backup_file"; then
        echo "   ✅ $DB_NAME"; return 0
    else rm -f "$backup_file"; return 1; fi
}
case "${1:-all}" in
    "all") for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; echo -e "\n🌐 $name"; backup_site "$name" "$path"; done ;;
    "list") for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; echo "  - $name"; done; exit 0 ;;
    *) for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; [ "$name" = "$1" ] && { backup_site "$name" "$path"; exit $?; }; done; echo "❌ Site '$1' not found"; exit 1 ;;
esac
find "$BACKUP_DIR" -name "mysql-*.sql.gz" -type f -mtime +$RETENTION_MYSQL -delete
echo -e "\n✅ MYSQL BACKUP COMPLETED"
EOF

# 9. NAS SYNC
deploy "nas-sftp-sync.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
LOG_FILE="$LOG_DIR/nas_sync.log"
BACKUP_MODULES=("backups-full" "backups-lite" "backups-manual" "mysql-backups")
log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
get_age() { [[ "$1" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]] && echo $((( $(date +%s) - $(date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}" +%s 2>/dev/null) / 86400 ))) || echo 0; }
sync_module() {
    local module="$1" local_path="$HOME/$module" remote_path="$NAS_PATH/$module"
    [ ! -d "$local_path" ] && { log "⚠️ Skipping: $module"; return 1; }
    echo "mkdir -p $remote_path" | sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" >/dev/null 2>&1
    local copied=0
    for file in "$local_path"/*; do
        [ ! -f "$file" ] && continue; filename=$(basename "$file")
        if ! echo "ls $remote_path/$filename" | sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" 2>/dev/null | grep -q "$filename"; then
            echo "put \"$file\" \"$remote_path/\"" | sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" >/dev/null 2>&1 && ((copied++))
        fi
    done
    local remote_files=$(echo "ls -1 $remote_path" | sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" 2>/dev/null | grep -v "sftp>" | tr -d '\r')
    local keep=0; deleted=0
    for file in $remote_files; do
        [ -z "$file" ] && continue; age=$(get_age "$file")
        if [ $keep -lt $NAS_MIN_KEEP_COPIES ]; then ((keep++))
        elif [ $age -gt $NAS_RETENTION_DAYS ]; then
            echo "rm \"$remote_path/$file\"" | sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" "$NAS_USER@$NAS_HOST" >/dev/null 2>&1 && ((deleted++))
        else ((keep++)); fi
    done
    log "   📊 $module: +$copied, -$deleted, $keep on NAS"
}
mkdir -p "$LOG_DIR"; log "🚀 NAS sync started"
for module in "${BACKUP_MODULES[@]}"; do sync_module "$module"; done
log "✅ NAS sync completed"
EOF

# 10. SMART RETENTION
deploy "wp-smart-retention-manager.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BACKUP_DIRS=("$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MANUAL_DIR" "$BACKUP_MYSQL_DIR")
declare -A RETENTION=([$BACKUP_LITE_DIR]=$RETENTION_LITE [$BACKUP_FULL_DIR]=$RETENTION_FULL [$BACKUP_MANUAL_DIR]=$RETENTION_LITE [$BACKUP_MYSQL_DIR]=$RETENTION_MYSQL)
apply_retention() {
    local dir="$1" days="${RETENTION[$dir]}"; [ ! -d "$dir" ] && return
    echo -e "${CYAN}📂 $(basename "$dir") (${days}d)${NC}"
    declare -A latest
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ "$file" =~ (backup-[a-z0-9-]+|mysql-[a-z0-9-]+) ]]; then
            pattern="${BASH_REMATCH[1]}"; mtime=$(stat -c %Y "$file")
            if [ -z "${latest[$pattern]}" ] || [ "$mtime" -gt "${latest[$pattern]}" ]; then
                latest[$pattern]="$mtime"; latest["${pattern}_path"]="$file"
            fi
        fi
    done < <(find "$dir" -type f 2>/dev/null)
    local deleted=0
    for file in "$dir"/*; do
        [ ! -f "$file" ] && continue; mtime=$(stat -c %Y "$file"); age=$((( $(date +%s) - mtime ) / 86400))
        if [ "$age" -gt "$days" ]; then
            is_latest=0
            for p in "${!latest[@]}"; do [[ "$p" =~ _path$ ]] && continue; [ "$file" = "${latest[${p}_path]}" ] && { is_latest=1; break; }; done
            [ "$is_latest" -eq 0 ] && { rm -f "$file"; ((deleted++)); }
        fi
    done
    echo -e "   🗑️ Deleted: $deleted files"
}
case "${1:-list}" in
    "list") for dir in "${BACKUP_DIRS[@]}"; do [ -d "$dir" ] && echo "   📂 $(basename "$dir"): $(find "$dir" -type f | wc -l) files ($(du -sh "$dir" 2>/dev/null | cut -f1))"; done ;;
    "apply") echo -e "${YELLOW}🔄 Applying retention...${NC}"; for dir in "${BACKUP_DIRS[@]}"; do apply_retention "$dir"; done; echo -e "${GREEN}✅ Completed${NC}" ;;
esac
EOF

# 11. HELP SYSTEM (FULL VERSION)
deploy "wp-help.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'
clear
echo -e "${WHITE}🆘 WORDPRESS MANAGEMENT SYSTEM - HELP & REFERENCE${NC}"
echo -e "${WHITE}=================================================${NC}"
echo -e "${BLUE}⏰ $(date)${NC}\n"
show_section() { echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}$(printf '%.0s-' {1..55})${NC}"; }
show_command() { printf "  ${GREEN}%-26s${NC} %s\n" "$1" "$2"; }
show_section "⚡ QUICK START"
show_command "wp-status" "# Executive overview"
show_command "system-diag" "# Server health"
show_command "wp-fleet" "# All sites status"
show_command "wp-update-safe" "# Backup then update"
show_command "wp-backup-lite" "# Fast backup"
show_command "nas-sync" "# Sync to NAS"
echo ""
show_section "💾 BACKUP SYSTEM"
show_command "wp-backup-lite" "# Lite (14 days)"
show_command "wp-backup-full" "# Full (35 days)"
show_command "wp-backup-ui" "# Interactive menu"
show_command "red-robin" "# Emergency backup"
show_command "backup-size" "# Storage usage"
show_command "backup-clean" "# Smart cleanup"
echo ""
show_section "🗄️ DATABASE"
show_command "db-backup all" "# All databases"
show_command "db-backup list" "# List sites"
show_command "db-backup [site]" "# Specific site"
echo ""
show_section "🔄 NAS SYNC"
show_command "nas-sync" "# Sync to NAS"
show_command "nas-sync-status" "# Last sync"
show_command "nas-sync-logs" "# Real-time logs"
echo -e "  ${YELLOW}📋 Target: $NAS_HOST:$NAS_PORT${NC}"
echo -e "  ${YELLOW}📋 Path: $NAS_PATH${NC}\n"
show_section "🦠 ANTIVIRUS"
show_command "clamav-scan" "# Daily scan"
show_command "clamav-deep-scan" "# Full scan"
show_command "clamav-status" "# Service status"
show_command "clamav-update" "# Update definitions"
show_command "clamav-logs" "# View logs"
show_command "clamav-quarantine" "# Check quarantine"
echo ""
show_section "📋 RETENTION"
echo -e "  ${YELLOW}⚡ Lite:${NC} 14d | ${YELLOW}💾 Full:${NC} 35d | ${YELLOW}🗄️ MySQL:${NC} 7d"
echo -e "  ${YELLOW}🔄 NAS:${NC} 120d (min 2 copies)\n"
show_section "🔖 QUICK REFERENCE"
echo -e "  ${GREEN}wp-status${NC} | ${GREEN}wp-help${NC} | ${GREEN}wp-backup-lite${NC} | ${GREEN}nas-sync${NC}"
echo -e "\n${GREEN}✅ SYSTEM READY${NC}"
EOF

# 12. INTERACTIVE BACKUP
deploy "wp-interactive-backup-tool.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
backup_site() {
    local name="$1" path="$2" user="$3" type="$4"
    echo -e "\n${YELLOW}🌐 $name ($type)${NC}"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    if [ "$type" = "full" ]; then
        ARCHIVE="$BACKUP_FULL_DIR/backup-full-$name-$TIMESTAMP.tar.gz"
        sudo tar -czf "$ARCHIVE" -C "$path" --exclude="wp-content/cache" . 2>/dev/null
    else
        ARCHIVE="$BACKUP_MANUAL_DIR/backup-lite-$name-$TIMESTAMP.tar.gz"
        sudo tar -czf "$ARCHIVE" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
    fi
    [ -f "$ARCHIVE" ] && echo -e "   ✅ ${GREEN}Success${NC}" || echo -e "   ❌ ${RED}Failed${NC}"
}
while true; do
    echo -e "\n${CYAN}🎯 SELECT SITE:${NC}"
    for i in "${!SITES[@]}"; do IFS=':' read -r name path user <<< "${SITES[$i]}"; echo "  $((i+1))) $name"; done
    echo "  a) All sites"; echo "  q) Exit"; read -p "Choice: " choice
    case $choice in q|Q) echo -e "${GREEN}Goodbye!${NC}"; break ;;
        a|A) read -p "Backup type (lite/full): " btype
            for site in "${SITES[@]}"; do IFS=':' read -r name path user <<< "$site"; backup_site "$name" "$path" "$user" "$btype"; done ;;
        [0-9]*) idx=$((choice-1)); [ -z "${SITES[$idx]}" ] && continue
            IFS=':' read -r name path user <<< "${SITES[$idx]}"; read -p "Backup type (lite/full): " btype; backup_site "$name" "$path" "$user" "$btype" ;;
    esac
done
EOF

# 13. STANDALONE MYSQL
deploy "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
echo "Standalone MySQL - use 'db-backup' instead"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOF

# 14. RED ROBIN
deploy "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
echo "🔴 RED ROBIN - Emergency system backup"
BACKUP_NAME="red-robin-$(hostname)-$(date +%Y%m%d-%H%M%S).tar.gz"
sudo tar -czf "/tmp/$BACKUP_NAME" --exclude="$HOME/backups-*" --exclude="*/wp-content/uploads" --exclude="/proc" --exclude="/sys" --exclude="/dev" / 2>/dev/null
echo "✅ Created: /tmp/$BACKUP_NAME ($(du -h /tmp/$BACKUP_NAME | cut -f1))"
EOF

# 15. CLAMAV AUTO
deploy "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/clamav/auto_scan.log"
sudo mkdir -p /var/log/clamav
echo "=== ClamAV Scan - $(date) ===" | sudo tee -a $LOG_FILE
sudo clamscan -r --infected --no-summary /home /var/www 2>/dev/null | sudo tee -a $LOG_FILE
echo "=== Completed ===" | sudo tee -a $LOG_FILE
EOF

# 16. CLAMAV FULL
deploy "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d)
LOG_FILE="/var/log/clamav/full_audit_$TIMESTAMP.log"
sudo mkdir -p /var/quarantine
echo "=== Full System Scan - $(date) ===" | sudo tee -a $LOG_FILE
sudo clamscan -r --infected --move=/var/quarantine --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee -a $LOG_FILE
echo "=== Completed ===" | sudo tee -a $LOG_FILE
EOF

# 17. WP-CLI VALIDATOR
deploy "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source ~/scripts/wsms-config.sh
echo "🧪 WP-CLI VALIDATOR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        echo " ✅ $name: $(sudo -u "$user" wp --path="$path" core version)"
    else
        echo " ❌ $name: Connection failed"
    fi
done
EOF

echo -e "${GREEN}✅ All 17 scripts deployed.${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Configuring Aliases...${NC}"
sed -i '/# WSMS/d' ~/.bashrc 2>/dev/null
cat >> ~/.bashrc << 'EOF'

# ==================== WSMS PRO ALIASES ==================== # WSMS
export SCRIPTS_DIR="$HOME/scripts"

# Help
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh"
alias help-wp="wp-help"

# Status
alias wp-status="system-diag && echo '' && wp-fleet && echo '' && backup-size"

# Diagnostics
alias system-diag="bash $SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash $SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias wp-cli-validator="bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh"
alias scripts-dir="ls -la $SCRIPTS_DIR"

# Maintenance
alias wp-update-all="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all"
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"

# Backups
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias red-robin="bash $SCRIPTS_DIR/red-robin-system-backup.sh"

# Database
alias db-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh"
alias db-backup-all="db-backup all"
alias db-backup-list="db-backup list"

# Retention
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh apply"
alias backup-size="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list"

# NAS Sync
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh"
alias nas-sync-logs="tail -f $HOME/logs/nas_sync.log"
alias nas-sync-status="echo '📊 Last NAS sync:'; tail -10 $HOME/logs/nas_sync.log 2>/dev/null || echo 'No logs'"

# ClamAV
alias clamav-scan="bash $SCRIPTS_DIR/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $SCRIPTS_DIR/clamav-full-scan.sh"
alias clamav-status="sudo systemctl status clamav-daemon --no-pager | head -15"
alias clamav-update="sudo freshclam"
alias clamav-logs="sudo tail -f /var/log/clamav/auto_scan.log"
alias clamav-quarantine="sudo ls -la /var/quarantine/"
alias clamav-clean-quarantine="sudo rm -rf /var/quarantine/* && echo '✅ Quarantine cleaned'"

# Backward compatibility
alias wp-list="wp-fleet"
alias wp-diagnoza="wp-audit"
alias wp-test-cli="wp-cli-validator"
alias wp-update="wp-update-all"
alias wp-fix-permissions="wp-fix-perms"
alias mysql-backup="db-backup"
alias mysql-backup-all="db-backup all"
alias mysql-backup-list="db-backup list"
alias backup-list="backup-size"
alias backup-dirs="scripts-dir"
alias backup-smart-clean="backup-clean"
alias sync-backup="nas-sync"
alias sync-backup-logs="nas-sync-logs"
alias sync-backup-status="nas-sync-status"
alias clamav-auto-scan="clamav-scan"
alias clamav-full-scan="clamav-deep-scan"

# Per-site WP-CLI (generated from config)
EOF

# Generate per-site aliases dynamically
for site in "${MANAGED_SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    cat >> ~/.bashrc << EOF
alias wp-$name="sudo -u $user /usr/local/bin/wp --path=$path"
alias wp-backup-$name="db-backup $name && wp-backup-lite"
EOF
done

echo -e "${GREEN}✅ Aliases configured.${NC}"

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}🗓️ Phase 6: Scheduling Crontab...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
# --- WSMS AUTOMATION --- # WSMS
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1 # WSMS
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas-sync.log 2>&1 # WSMS
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/security-scan.log 2>&1 # WSMS
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh apply >> $HOME/logs/retention.log 2>&1 # WSMS
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1 # WSMS
0 2 * * 0,3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1 # WSMS
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-full.log 2>&1 # WSMS
") | crontab -
echo -e "${GREEN}✅ Crontab configured.${NC}"

# ==================== FINAL SUMMARY ====================
echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ WSMS PRO 4.0 DEPLOYMENT COMPLETED!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "   📋 Managed sites: ${#MANAGED_SITES[@]}"
echo -e "   🔧 Config file:   ~/scripts/wsms-config.sh"
echo -e "   📜 Scripts:        $(ls -1 ~/scripts/*.sh 2>/dev/null | wc -l) files"
echo ""
echo -e "${YELLOW}🚀 NEXT STEPS:${NC}"
echo -e "   1. ${CYAN}source ~/.bashrc${NC}"
echo -e "   2. ${CYAN}wp-status${NC} - Verify all sites"
echo -e "   3. ${CYAN}wp-help${NC}   - Command reference"
echo -e "   4. ${CYAN}wp-backup-lite${NC} - Test backup"
echo ""
echo -e "${BLUE}💡 To add/modify sites, edit MANAGED_SITES at the top of this installer and re-run.${NC}"
INSTALL_EOF

# Make executable and run
chmod +x ~/install_wsms.sh
~/install_wsms.sh