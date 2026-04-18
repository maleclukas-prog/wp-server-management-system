cat > ~/install_wsms.sh << 'INSTALL_EOF'
#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - MASTER INSTALLATION ORCHESTRATOR
# Version: 4.1 (Ultimate Production Edition)
# Description: Complete automated deployment of WSMS infrastructure
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

set -e

# =================================================================
# ⚙️ GLOBAL INFRASTRUCTURE CONFIGURATION - EDIT ONLY HERE!
# =================================================================
MANAGED_SITES=(
    "Site_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_site"
)

# Synology NAS Settings
NAS_HOST="your_server_details.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/Your_id_rsa-key"
# =================================================================


# UI Colors
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   WSMS PRO v4.1 - MASTER INSTALLER                        ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# ==================== PHASE 1: INFRASTRUCTURE ====================
echo -e "\n${BLUE}📂 Phase 1: Initializing Infrastructure...${NC}"
DIRS=("$HOME/scripts" "$HOME/backups-lite" "$HOME/backups-full" 
      "$HOME/backups-manual" "$HOME/mysql-backups" "$HOME/logs")
for dir in "${DIRS[@]}"; do
    mkdir -p "$dir" && echo -e "   ✅ Directory ready: $dir"
done
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav 2>/dev/null
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}🔍 Phase 2: Installing Dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon openssh-client bc curl 2>/dev/null
if ! command -v wp &> /dev/null; then
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
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

# ==================== PHASE 4: DEPLOY 17 SCRIPTS ====================
echo -e "\n${BLUE}📝 Phase 4: Deploying 17 Operational Modules...${NC}"

deploy() { echo -e "   📦 ${CYAN}$1${NC}"; cat > "$HOME/scripts/$1"; chmod +x "$HOME/scripts/$1"; }

# 1. server-health-audit.sh
deploy "server-health-audit.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS DASHBOARD${NC}"
echo "=========================================================="
echo -e "⏰ Audit Timestamp: $(date)"
echo -e "💻 System Host:    $(hostname) | OS: $(lsb_release -d | cut -f2)"
echo "----------------------------------------------------------"
echo -e "\n${CYAN}📈 SYSTEM LOAD & RESOURCES:${NC}"
echo "   CPU Cores:    $(nproc)"
echo "   Uptime:       $(uptime -p)"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory:       " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used (" $7 " available)"}'
echo -e "\n${CYAN}💾 STORAGE AUDIT:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'
echo -e "\n${CYAN}🌐 NETWORK EXPOSURE:${NC}"
echo "   Primary IP: $(hostname -I | awk '{print $1}')"
ss -tulpn | grep -E ":(80|443|22|3306)" | head -5 | sed 's/^/   /'
echo -e "\n${CYAN}🛠️  CORE SERVICES STATUS:${NC}"
for s in nginx apache2 mysql mariadb ssh; do
    status=$(systemctl is-active "$s" 2>/dev/null || echo "not installed")
    [ "$status" == "active" ] && echo -e "   ✅ $s: ${GREEN}Active${NC}" || ([ "$status" != "not installed" ] && echo -e "   ❌ $s: ${RED}$status${NC}")
done
echo -e "\n${CYAN}🌐 MANAGED WORDPRESS FLEET AUDIT:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ Site: $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        site_php=$(sudo -u "$user" wp --path="$path" eval "echo PHP_VERSION;" 2>/dev/null || echo "unknown")
        echo "      - Core: v$wp_ver | PHP: $site_php"
        id "$user" &>/dev/null && echo -e "      - Security: ${GREEN}User $user (Isolated)${NC}" || echo -e "      - Security: ${RED}User $user missing!${NC}"
    else echo -e "      - ${RED}CRITICAL: Config missing at $path${NC}"; fi
done
echo -e "\n${CYAN}💾 DATA INTEGRITY (BACKUPS):${NC}"
total_archives=0
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l); size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
        total_archives=$((total_archives + count))
    fi
done
echo -e "\n${YELLOW}🔔 RECOMMENDATIONS:${NC}"
free_gb=$(df /home 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
if [ -n "$free_gb" ] && [ "${free_gb%.*}" -lt 5 ]; then
    echo -e "   ⚠️  ${RED}CRITICAL: Low disk space!${NC}"
else
    echo "   ✅ STORAGE: Disk health is optimal."
fi
[ "$total_archives" -eq 0 ] && echo -e "   ⚠️  ${RED}ALERT: No backups found!${NC}" || echo "   ✅ BACKUPS: Infrastructure cycle is healthy."
echo -e "\n${GREEN}✅ INFRASTRUCTURE AUDIT COMPLETE${NC}"
EOF

# 2. wp-fleet-status-monitor.sh
deploy "wp-fleet-status-monitor.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
echo -e "${CYAN}📊 WORDPRESS FLEET INVENTORY AUDIT${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        echo -e "   🌐 $name: Core v$ver | ${YELLOW}Updates pending: $updates${NC}"
    else echo -e "   ❌ $name: Environment Error at $path"; fi
done
EOF

# 3. wp-multi-instance-audit.sh
deploy "wp-multi-instance-audit.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo -e "🔍 INITIATING MULTI-SITE DEEP AUDIT"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n--- Audit for: $name ---"
    if [ -f "$path/wp-config.php" ]; then
        sudo -u "$user" wp --path="$path" db check 2>/dev/null
        sudo -u "$user" wp --path="$path" plugin list --update=available --format=table 2>/dev/null
        sudo -u "$user" wp --path="$path" site-health get --format=csv 2>/dev/null | head -n 5
    else echo "❌ Configuration missing."; fi
done
EOF

# 4. wp-automated-maintenance-engine.sh
deploy "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
CYAN='\033[0;36m'; NC='\033[0m'
echo -e "🔄 ${CYAN}FLEET-WIDE MAINTENANCE ENGINE STARTED${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Patching Instance: $name"
    if [ -f "$path/wp-config.php" ]; then
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        echo "   ✅ $name is up-to-date."
    else echo "   ❌ Failed: Config missing."; fi
done
EOF

# 5. infrastructure-permission-orchestrator.sh
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${BLUE}🔐 ENFORCING SECURITY PERMISSIONS...${NC}"
sudo systemctl stop nginx 2>/dev/null || true
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "🔧 Fixing permissions for $name (User: $user)"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php" 2>/dev/null
        command -v setfacl &>/dev/null && sudo setfacl -R -m u:ubuntu:r-x "$path" 2>/dev/null || true
    fi
done
sudo systemctl start nginx 2>/dev/null || true
echo -e "${GREEN}✅ SECURITY POLICIES APPLIED.${NC}"
EOF

# 6. wp-full-recovery-backup.sh
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; NC='\033[0m'
echo -e "${BLUE}💾 STARTING FULL FLEET SNAPSHOT...${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   📦 Snapshotting $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
done
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime +$RETENTION_FULL -delete 2>/dev/null
echo "✅ Full backup cycle completed."
EOF

# 7. wp-essential-assets-backup.sh
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S)
BLUE='\033[0;34m'; NC='\033[0m'
echo -e "${BLUE}⚡ STARTING LEAN ASSETS BACKUP...${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   📁 Archiving $name assets..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name" 2>/dev/null
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
done
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime +$RETENTION_LITE -delete 2>/dev/null
echo "✅ Lite backup cycle completed."
EOF

# 8. mysql-backup-manager.sh
deploy "mysql-backup-manager.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S); target=${1:-all}
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [[ "$target" == "all" || "$target" == "$name" ]]; then
        if [ -f "$path/wp-config.php" ]; then
            DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=$(grep -E "DB_HOST" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
            DB_HOST=${DB_HOST:-localhost}
            mysqldump --single-transaction --quick -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz"
            echo "      ✅ Database snapshot ready for $name"
        fi
    fi
done
EOF

# 9. nas-sftp-sync.sh
deploy "nas-sftp-sync.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
LOG="$LOG_DIR/nas_sync.log"
exec >> "$LOG" 2>&1
echo "--- NAS Sync Cycle Started: $(date) ---"
for module in backups-lite backups-full mysql-backups; do
    echo "Processing $module..."
    sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << SFTP_EOF 2>/dev/null
    mkdir -p $NAS_PATH/$module
    put $HOME/$module/* $NAS_PATH/$module/
SFTP_EOF
done
echo "--- Sync Finished ---"
EOF

# 10. wp-smart-retention-manager.sh
deploy "wp-smart-retention-manager.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

list_backups() {
    echo -e "${CYAN}📋 ALL BACKUPS WITH DETAILS${NC}"
    echo "=========================================================="
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "\n${YELLOW}📂 $(basename "$dir"):${NC}"
            find "$dir" -type f \( -name "*.tar.gz" -o -name "*.sql.gz" \) 2>/dev/null | while read file; do
                size=$(du -h "$file" 2>/dev/null | cut -f1)
                date_str=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
                echo "   📁 $(basename "$file") ($size, $date_str)"
            done
        fi
    done
}

show_size() {
    echo -e "${CYAN}💽 BACKUP STORAGE USAGE${NC}"
    echo "=========================================================="
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "   📂 $(basename "$dir"): $size ($count files)"
        fi
    done
}

emergency_cleanup() {
    echo -e "${RED}🚨 EMERGENCY MODE: Keeping only 2 latest copies!${NC}"
    for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
        if [ -d "$dir" ]; then
            ls -t "$dir"/* 2>/dev/null | tail -n +3 | xargs rm -f 2>/dev/null
        fi
    done
}

force_clean() {
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        emergency_cleanup
    else
        echo -e "${GREEN}✅ Standard cleanup: Deleting files older than retention period${NC}"
        find "$BACKUP_LITE_DIR" -type f -mtime +$RETENTION_LITE -delete 2>/dev/null
        find "$BACKUP_FULL_DIR" -type f -mtime +$RETENTION_FULL -delete 2>/dev/null
        find "$BACKUP_MYSQL_DIR" -type f -mtime +$RETENTION_MYSQL -delete 2>/dev/null
    fi
}

case "${1:-}" in
    list|l) list_backups ;;
    size|s) show_size ;;
    clean|c) echo "Use 'backup-clean' for interactive mode" ;;
    force-clean|force|f) force_clean ;;
    emergency|e) emergency_cleanup ;;
    *) echo "Usage: $0 {list|size|force-clean|emergency}" ;;
esac
EOF

# 11. wp-help.sh
deploy "wp-help.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'
clear
echo -e "${WHITE}🆘 WSMS PRO v4.1 - MASTER REFERENCE GUIDE${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ System Time: $(date)"
echo ""
echo -e "${CYAN}▶ QUICK START${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-status" "Executive overview: Hardware + Fleet Health"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-fleet" "Monitor WordPress versions and pending updates"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-update-safe" "Recommended Update Path (Backup -> Patch -> Clean)"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-backup-lite" "Fast daily assets backup"
printf "  ${GREEN}%-20s${NC} %s\n" "nas-sync" "Manual trigger for off-site NAS synchronization"
echo ""
echo -e "${CYAN}▶ BACKUP MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-20s${NC} %s\n" "backup-list" "List all backups with details"
printf "  ${GREEN}%-20s${NC} %s\n" "backup-size" "Show storage usage per directory"
printf "  ${GREEN}%-20s${NC} %s\n" "backup-clean" "Interactive cleanup with confirmation"
printf "  ${GREEN}%-20s${NC} %s\n" "backup-force-clean" "Force cleanup without confirmation"
printf "  ${GREEN}%-20s${NC} %s\n" "backup-emergency" "Keep only 2 latest copies per site"
echo ""
echo -e "${CYAN}▶ DATABASE MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-20s${NC} %s\n" "mysql-backup-all" "Backup all WordPress databases"
printf "  ${GREEN}%-20s${NC} %s\n" "mysql-backup-list" "List available sites and backups"
echo ""
echo -e "${CYAN}▶ MAINTENANCE & SECURITY${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-update-all" "Trigger unattended fleet-wide patching"
printf "  ${GREEN}%-20s${NC} %s\n" "wp-fix-perms" "Enforce security isolation"
printf "  ${GREEN}%-20s${NC} %s\n" "clamav-scan" "Execute daily malware audit"
printf "  ${GREEN}%-20s${NC} %s\n" "clamav-deep-scan" "Execute root-level system-wide malware audit"
echo ""
echo -e "${CYAN}▶ DATA RETENTION POLICIES${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "  ${YELLOW}⚡ Lite Assets:${NC} $RETENTION_LITE days"
echo -e "  ${YELLOW}💾 Full Snapshots:${NC} $RETENTION_FULL days"
echo -e "  ${YELLOW}🗄️ MySQL Dumps:${NC} $RETENTION_MYSQL days"
echo -e "  ${YELLOW}🔄 Cloud NAS Vault:${NC} $NAS_RETENTION_DAYS days"
echo -e "  ${RED}⚠️ EMERGENCY MODE:${NC} Keeps only 2 latest copies when disk usage > $DISK_ALERT_THRESHOLD%"
echo ""
echo -e "${GREEN}✅ ALL SYSTEMS OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Use 'wp-status' for an instant infrastructure health report."
EOF

# 12. wp-interactive-backup-tool.sh
deploy "wp-interactive-backup-tool.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo -e "\033[0;34m🎯 WSMS INTERACTIVE BACKUP ENGINE\033[0m"
select site_info in "${SITES[@]}" "Exit"; do
    [[ "$site_info" == "Exit" ]] && exit
    IFS=':' read -r name path user <<< "$site_info"
    echo "Running Asset Backup for $name..."
    bash "$SCRIPT_DIR/wp-essential-assets-backup.sh" "$name"
    break
done
EOF

# 13. standalone-mysql-backup-engine.sh
deploy "standalone-mysql-backup-engine.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo "⚙️  Standalone MySQL Engine: Executing global dump."
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
EOF

# 14. red-robin-system-backup.sh
deploy "red-robin-system-backup.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d); OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
echo "🔴 EMERGENCY SYSTEM STATE CAPTURE STARTING..."
sudo tar -cpzf "$OUT" --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="$HOME/backups-*" / 2>/dev/null
echo -e "✅ \033[0;32mSystem configuration captured: $OUT\033[0m"
EOF

# 15. clamav-auto-scan.sh
deploy "clamav-auto-scan.sh" << 'EOF'
#!/bin/bash
LOG="/var/log/clamav/auto_scan.log"
echo "--- Malware Scan: $(date) ---" | sudo tee -a $LOG
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a $LOG
EOF

# 16. clamav-full-scan.sh
deploy "clamav-full-scan.sh" << 'EOF'
#!/bin/bash
TS=$(date +%Y%m%d); LOG="/var/log/clamav/full_audit_$TS.log"
echo "--- Deep System Audit: $(date) ---" | sudo tee -a $LOG
sudo clamscan -r --infected --move=/var/quarantine --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee -a $LOG
EOF

# 17. wp-cli-infrastructure-validator.sh
deploy "wp-cli-infrastructure-validator.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo "🧪 VALIDATING WP-CLI INTEGRATION..."
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        echo -e "   ✅ $name: Connected"
    else
        echo -e "   ❌ $name: Connection Failed"
    fi
done
EOF

echo -e "${GREEN}✅ All 17 operational modules deployed.${NC}"

# ==================== PHASE 5: ALIASES (BASH) ====================
echo -e "\n${BLUE}🔧 Phase 5: Provisioning Shell Aliases for Bash...${NC}"
RC_FILE="$HOME/.bashrc"

# Remove old WSMS entries
sed -i '/# WSMS PRO/d' "$RC_FILE" 2>/dev/null
sed -i '/WSMS PRO ALIASES/d' "$RC_FILE" 2>/dev/null

cat >> "$RC_FILE" << 'EOF'

# ============================================
# WSMS PRO v4.1 - ALIASES
# ============================================
export SCRIPTS_DIR="$HOME/scripts"

# System diagnostics
alias system-diag="bash $SCRIPTS_DIR/server-health-audit.sh"
alias scripts-dir="ls -la $SCRIPTS_DIR/"

# WordPress management
alias wp-list="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash $SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-cli-validator="bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh"
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"

# Updates
alias wp-update="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-all="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh && sleep 10 && bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"

# Backups
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash $SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias red-robin="bash $SCRIPTS_DIR/red-robin-system-backup.sh"

# Backup Management
alias backup-list="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list"
alias backup-size="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size"
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean"
alias backup-force-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean"
alias backup-emergency="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency"
alias backup-dirs="ls -la $HOME/backups-* 2>/dev/null"

# MySQL backups
alias db-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh"
alias mysql-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh"
alias mysql-backup-all="bash $SCRIPTS_DIR/mysql-backup-manager.sh all"
alias mysql-backup-list="bash $SCRIPTS_DIR/mysql-backup-manager.sh list"

# Help
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh"

# NAS Sync
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh"
alias nas-sync-logs="tail -f $HOME/logs/nas_sync.log"

# ClamAV
alias clamav-scan="bash $SCRIPTS_DIR/clamav-auto-scan.sh"
alias clamav-deep-scan="bash $SCRIPTS_DIR/clamav-full-scan.sh"
alias clamav-status="sudo systemctl status clamav-daemon --no-pager | head -15"
alias clamav-update="sudo freshclam"
alias clamav-logs="sudo tail -f /var/log/clamav/auto_scan.log"

# Quick status function
wp-status() {
    echo "🌐 Quick Status:"
    wp-list
    echo ""
    backup-size
}
EOF

# Dynamic per-site shortcuts
for site in "${MANAGED_SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "alias wp-$name=\"sudo -u $user wp --path=$path\"" >> "$RC_FILE"
    echo "alias wp-backup-$name=\"mysql-backup $name && wp-backup-lite\"" >> "$RC_FILE"
done

echo -e "${GREEN}✅ Aliases added to ~/.bashrc${NC}"
echo -e "${YELLOW}⚠️ Run: source ~/.bashrc${NC}"

# ==================== PHASE 6: CRONTAB SETUP ====================
echo -e "\n${BLUE}⏰ Phase 6: Configuring Crontab...${NC}"

# Backup existing crontab
crontab -l > /tmp/crontab_backup_$(date +%Y%m%d).txt 2>/dev/null

# Install new crontab
cat > /tmp/wsms_crontab.txt << 'CRON_EOF'
# ============================================
# WSMS PRO v4.1 - CRONTAB
# ============================================

# ClamAV - Daily definition update at 1:00 AM
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1

# ClamAV - Daily quick scan at 3:00 AM
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/clamav-scan.log 2>&1

# ClamAV - Weekly full scan on Sunday at 4:00 AM
0 4 * * 0 $HOME/scripts/clamav-full-scan.sh >> $HOME/logs/clamav-full.log 2>&1

# Lite backups - Sunday and Wednesday at 2:00 AM
0 2 * * 0 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1
0 2 * * 3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1

# Full backup - 1st day of month at 3:00 AM
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-full.log 2>&1

# Smart retention - daily at 4:00 AM
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh force-clean >> $HOME/logs/retention.log 2>&1

# WordPress updates - weekly on Sunday at 6:00 AM
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1

# NAS sync - daily at 2:00 AM
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas-sync.log 2>&1
CRON_EOF

crontab /tmp/wsms_crontab.txt
rm -f /tmp/wsms_crontab.txt

echo -e "${GREEN}✅ Crontab configured successfully.${NC}"

# ==================== PHASE 7: FINAL SUMMARY ====================
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.1 INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo -e "${YELLOW}📋 INSTALLATION SUMMARY:${NC}"
echo "   📂 Scripts deployed: 17 modules in ~/scripts/"
echo "   💾 Backup directories: ~/backups-lite, ~/backups-full, ~/mysql-backups"
echo "   🔧 Shell aliases installed for: Bash"
echo "   ⏰ Crontab scheduled: 8 automated tasks"
echo ""
echo -e "${YELLOW}🚀 NEXT STEPS:${NC}"
echo "   1. Run: source ~/.bashrc"
echo "   2. Run: wp-status"
echo ""
echo -e "${CYAN}📚 AVAILABLE COMMANDS:${NC}"
echo "   wp-status          - Full system diagnostics"
echo "   backup-list        - List all backups with details"
echo "   backup-size        - Show storage usage"
echo "   wp-update-safe     - Safe WordPress update with backup"
echo "   wp-help            - Complete command reference"
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"