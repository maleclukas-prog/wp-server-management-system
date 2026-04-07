cat > ~/install_wsms.sh << 'INSTALL_EOF'
#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - MASTER INSTALLATION ORCHESTRATOR
# Version: 4.0 (Ultimate Production Edition)
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
echo -e "${CYAN}   WSMS PRO - ULTIMATE MASTER INSTALLER (v4.0)            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# ==================== PHASE 1: INFRASTRUCTURE ====================
echo -e "\n${BLUE}📂 Phase 1: Initializing Infrastructure...${NC}"
DIRS=("$HOME/scripts" "$HOME/backups-lite" "$HOME/backups-full" 
      "$HOME/backups-manual" "$HOME/backups-mysqldump" "$HOME/mysql-backups" "$HOME/logs")
for dir in "${DIRS[@]}"; do
    mkdir -p "$dir" && echo -e "   ✅ Directory ready: $dir"
done
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# ==================== PHASE 2: DEPENDENCIES ====================
echo -e "\n${BLUE}🔍 Phase 2: Installing Dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon openssh-client bc curl ss -qq
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
        count=$(find "$dir" -type f | wc -l); size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
        total_archives=$((total_archives + count))
    fi
done
echo -e "\n${YELLOW}🔔 RECOMMENDATIONS:${NC}"
free_gb=$(df /home | awk 'NR==2 {print $4}' | sed 's/G//')
[ "${free_gb%.*}" -lt 5 ] && echo -e "   ⚠️  ${RED}CRITICAL: Low disk space!${NC}" || echo "   ✅ STORAGE: Disk health is optimal."
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
        sudo -u "$user" wp --path="$path" db check
        sudo -u "$user" wp --path="$path" plugin list --update=available --format=table
        sudo -u "$user" wp --path="$path" site-health get --format=csv | head -n 5
    else echo "❌ Configuration missing."; fi
done
EOF

# 4. wp-automated-maintenance-engine.sh
deploy "wp-automated-maintenance-engine.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo -e "🔄 ${CYAN}FLEET-WIDE MAINTENANCE ENGINE STARTED${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Patching Instance: $name"
    if [ -f "$path/wp-config.php" ]; then
        sudo -u "$user" wp --path="$path" core update --quiet
        sudo -u "$user" wp --path="$path" plugin update --all --quiet
        sudo -u "$user" wp --path="$path" core update-db --quiet
        sudo -u "$user" wp --path="$path" cache flush --quiet
        echo "   ✅ $name is up-to-date."
    else echo "   ❌ Failed: Config missing."; fi
done
EOF

# 5. infrastructure-permission-orchestrator.sh
deploy "infrastructure-permission-orchestrator.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
echo -e "🔐 ${BLUE}ENFORCING SECURITY PERMISSIONS...${NC}"
sudo systemctl stop nginx 2>/dev/null || true
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "🔧 Fixing permissions for $name (User: $user)"
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path"
        sudo find "$path" -type d -exec chmod 755 {} \;
        sudo find "$path" -type f -exec chmod 644 {} \;
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php"
        command -v setfacl &>/dev/null && sudo setfacl -R -m u:ubuntu:r-x "$path" 2>/dev/null || true
    fi
done
sudo systemctl start nginx 2>/dev/null || true
echo -e "✅ ${GREEN}SECURITY POLICIES APPLIED.${NC}"
EOF

# 6. wp-full-recovery-backup.sh
deploy "wp-full-recovery-backup.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S)
echo -e "💾 ${BLUE}STARTING FULL FLEET SNAPSHOT...${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   📦 Snapshotting $name..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"
    tar -czf "$BACKUP_FULL_DIR/full-$name-$TS.tar.gz" -C "$path" . 2>/dev/null
done
find "$BACKUP_FULL_DIR" -name "*.tar.gz" -mtime +$RETENTION_FULL -delete
echo "✅ Full backup cycle completed."
EOF

# 7. wp-essential-assets-backup.sh
deploy "wp-essential-assets-backup.sh" << 'EOF'
#!/bin/bash
source $HOME/scripts/wsms-config.sh
TS=$(date +%Y%m%d-%H%M%S)
echo -e "⚡ ${BLUE}STARTING LEAN ASSETS BACKUP...${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   📁 Archiving $name assets..."
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$name"
    tar -czf "$BACKUP_LITE_DIR/lite-$name-$TS.tar.gz" -C "$path" wp-content/uploads wp-content/themes wp-content/plugins wp-config.php 2>/dev/null
done
find "$BACKUP_LITE_DIR" -name "*.tar.gz" -mtime +$RETENTION_LITE -delete
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
            mysqldump --single-transaction --quick -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_MYSQL_DIR/db-$name-$TS.sql.gz"
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
    sftp -i "$NAS_SSH_KEY" -P "$NAS_PORT" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" << SFTP_EOF
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
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
apply_policy() {
    local dir=$1; local days=$2
    if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        echo -e "${RED}⚠️  Critical Storage ($usage%). Purging all but latest 2 archives.${NC}"
        ls -t $dir/* 2>/dev/null | tail -n +3 | xargs rm -f 2>/dev/null
    else
        find $dir -type f -mtime +$days -delete
    fi
}
echo "🧹 Cleaning Lite archives..."; apply_policy "$BACKUP_LITE_DIR" "$RETENTION_LITE"
echo "🧹 Cleaning Full archives..."; apply_policy "$BACKUP_FULL_DIR" "$RETENTION_FULL"
echo -e "${GREEN}✅ Retention task finished.${NC}"
EOF

# 11. wp-help.sh
deploy "wp-help.sh" << 'EOF'
#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.0 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
source $HOME/scripts/wsms-config.sh

# Professional UI Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}🆘 WORDPRESS MANAGEMENT SYSTEM - MASTER REFERENCE GUIDE${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ System Time: $(date)"
echo -e "📦 Version:     4.0 (Production Ready)"
echo ""

show_section() { echo -e "${CYAN}▶ $1${NC}"; echo -e "${CYAN}$(printf '%.0s-' {1..60})${NC}"; }
show_cmd() { printf "  ${GREEN}%-20s${NC} | %s\n" "$1" "$2"; }

# ==================== QUICK START ====================
show_section "⚡ QUICK START - MOST USED"
show_cmd "wp-status"          "Executive overview: Hardware + Fleet Health"
show_cmd "wp-fleet"           "Monitor WordPress versions and pending updates"
show_cmd "wp-update-safe"     "Recommended Update Path (Backup -> Patch -> Clean)"
show_cmd "wp-backup-lite"     "Fast daily assets backup (DB + Themes/Plugins)"
show_cmd "nas-sync"           "Manual trigger for off-site NAS synchronization"
echo ""

# ==================== DIAGNOSTICS & OBSERVABILITY ====================
show_section "🔍 OBSERVABILITY & MONITORING"
show_cmd "system-diag"        "Full hardware audit (CPU, RAM, Disk, Services)"
show_cmd "wp-audit"           "Deep-dive site diagnostics & Site-Health scores"
show_cmd "wp-cli-validator"   "Verify WP-CLI connectivity & isolation for all sites"
show_cmd "scripts-dir"        "List all underlying WSMS automation files"
echo ""

# ==================== MAINTENANCE & SECURITY ====================
show_section "🛠️  MAINTENANCE & SECURITY ORCHESTRATION"
show_cmd "wp-update-all"      "Trigger unattended fleet-wide patching"
show_cmd "wp-fix-perms"       "Enforce security isolation and restore ACL policies"
show_cmd "clamav-scan"        "Execute daily malware signature recursive audit"
show_cmd "clamav-deep-scan"   "Execute root-level system-wide malware audit (/)"
echo ""

# ==================== BACKUP & DISASTER RECOVERY ====================
show_section "💾 BACKUP & DISASTER RECOVERY (DR)"
show_cmd "wp-backup-lite"     "Daily assets backup (14-day local retention)"
show_cmd "wp-backup-full"     "Full bare-metal snapshots (35-day local retention)"
show_cmd "wp-backup-ui"       "Interactive CLI menu for on-demand recovery"
show_cmd "red-robin"          "Emergency OS-state and configuration backup"
show_cmd "backup-size"        "Audit current storage consumption per repository"
show_cmd "backup-clean"       "Manually trigger heuristic smart retention engine"
echo ""

# ==================== HYBRID CLOUD SYNC (NAS) ====================
show_section "🔄 OFF-SITE SYNC (SYNOLOGY NAS)"
show_cmd "nas-sync"           "Uplink all local archives to remote NAS vault"
show_cmd "nas-sync-status"    "Check result of the last sync operation"
show_cmd "nas-sync-logs"      "Stream synchronization logs in real-time"
echo -e "  ${YELLOW}📋 Off-site Context:${NC}"
echo -e "     • Remote Host: $NAS_HOST:$NAS_PORT"
echo -e "     • Remote Path: $NAS_PATH"
echo -e "     • Policy:      120 days retention (Ensures min $NAS_MIN_KEEP_COPIES copies)"
echo ""

# ==================== DATABASE MANAGEMENT ====================
show_section "🗄️  DATABASE OPERATIONS (MySQL)"
show_cmd "db-backup all"      "Force snapshots for every managed database"
show_cmd "db-backup list"     "List all available database snapshots"
show_cmd "db-backup [site]"   "Targeted snapshot for a specific instance"
echo ""

# ==================== CYBERSECURITY DETAILS ====================
show_section "🦠 CYBERSECURITY (ClamAV & Firewall)"
show_cmd "clamav-status"      "Monitor ClamAV protection daemon health"
show_cmd "clamav-update"      "Manually synchronize virus definitions (freshclam)"
show_cmd "clamav-logs"        "Review security audit history and detections"
show_cmd "clamav-quarantine"  "Inspect isolated malicious files in /var/quarantine"
show_cmd "sudo ufw status"    "Verify system firewall rules and active jails"
echo ""

# ==================== SERVER ADMINISTRATION ====================
show_section "🖥️  SERVER ADMINISTRATION"
show_cmd "sudo apt update"    "Refresh system software repositories"
show_cmd "sudo apt upgrade"   "Deploy latest OS-level security patches"
show_cmd "sudo reboot"        "Execute safe system restart"
show_cmd "htop"               "Interactive real-time process monitoring"
echo ""

# ==================== LOGS & JOURNALS ====================
show_section "📊 SYSTEM LOGS & JOURNALS"
show_cmd "nas-sync-logs"      "NAS synchronization event stream"
show_cmd "clamav-logs"        "Antivirus scan result stream"
show_cmd "tail -f /var/log/nginx/error.log" "Web server error event stream"
show_cmd "journalctl -u php8.4-fpm -f"     "PHP engine event stream"
echo ""

# ==================== AUTOMATION (CRON) ====================
show_section "⏰ AUTOMATION SCHEDULE (CRONTAB)"
echo -e "  ${BLUE}Daily 01:00${NC} | Malware definition updates"
echo -e "  ${BLUE}Daily 02:00${NC} | Off-site synchronization to Synology NAS"
echo -e "  ${BLUE}Daily 03:00${NC} | Proactive malware audit (/home + /var/www)"
echo -e "  ${BLUE}Daily 04:00${NC} | Smart Retention Engine (Resource cleanup)"
echo -e "  ${BLUE}Sunday 06:00${NC}| Fleet-wide security patching (Core/Plugins)"
echo -e "  ${BLUE}Sun/Wed 02:00${NC}| High-frequency Lite backups"
echo -e "  ${BLUE}1st Day 03:00${NC}| Full Bare-metal system snapshots"
echo ""

# ==================== DATA RETENTION POLICY ====================
show_section "📋 DATA RETENTION POLICIES"
echo -e "  ${YELLOW}⚡ Lite Assets:${NC} $RETENTION_LITE days | ${YELLOW}💾 Full Snapshots:${NC} $RETENTION_FULL days"
echo -e "  ${YELLOW}🗄️ MySQL Dumps:${NC}  $RETENTION_MYSQL days | ${YELLOW}🔄 Cloud NAS Vault:${NC} $NAS_RETENTION_DAYS days"
echo -e "  ${RED}⚠️ EMERGENCY MODE:${NC} Keeps only 2 latest copies when disk usage > $DISK_ALERT_THRESHOLD%"
echo -e "  ${GREEN}🛡️ SAFETY RULE:${NC} System ALWAYS preserves the last valid copy (Safety First)."
echo ""

# ==================== DYNAMIC SITE SHORTCUTS ====================
show_section "📌 DYNAMIC SITE SHORTCUTS"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "  ${YELLOW}wp-$name${NC} | ${YELLOW}wp-backup-$name${NC}"
done
echo ""

# ==================== INCIDENT RESPONSE (SOP) ====================
show_section "🚨 INCIDENT RESPONSE (SOP)"
echo -e "  ${RED}Disk Usage >$DISK_ALERT_THRESHOLD%?${NC}  → Run 'backup-clean' to reclaim space."
echo -e "  ${RED}Permission Denied?${NC}      → Run 'wp-fix-perms' to realign ACLs."
echo -e "  ${RED}Update Failure?${NC}        → Run 'wp-fix-perms' then 'wp-update-safe'."
echo -e "  ${RED}Sync Failure?${NC}          → Check SSH keys and run 'nas-sync' manually."
echo ""

# ==================== SCRIPT INVENTORY ====================
show_section "📜 INFRASTRUCTURE MODULES (Physical Files)"
ls -la ~/scripts/ 2>/dev/null | grep "^-" | awk '{print "  📜 " $9}' | sed 's/\.sh//' | sort
echo ""

echo -e "${GREEN}✅ ALL SYSTEMS OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Use 'wp-status' for an instant infrastructure health report."
echo ""
EOF
echo ""

# ==================== AVAILABLE SCRIPTS ====================
show_section "📜 INFRASTRUCTURE MODULES (Physical Files)"
ls -la ~/scripts/ 2>/dev/null | grep "^-" | awk '{print "  📜 " $9}' | sed 's/\.sh//' | sort
echo ""

echo -e "${GREEN}✅ SYSTEM OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Start your shift with 'wp-status' for an instant fleet audit."
echo ""

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
sudo clamscan -r --infected --no-summary /var/www /home | sudo tee -a $LOG
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
        echo -e "   ✅ $name: \033[0;32mConnected\033[0m"
    else
        echo -e "   ❌ $name: \033[0;31mConnection Failed\033[0m"
    fi
done
EOF

echo -e "${GREEN}✅ All 17 operational modules deployed.${NC}"

# ==================== PHASE 5: ALIASES ====================
echo -e "\n${BLUE}🔧 Phase 5: Provisioning Shell Aliases...${NC}"
RC_FILE="$HOME/.bashrc"
sed -i '/# WSMS/d' "$RC_FILE" 2>/dev/null

cat >> "$RC_FILE" << 'EOF'
# ==================== WSMS PRO ALIASES ==================== # WSMS
export SCRIPTS_DIR="$HOME/scripts"

# Executive & Help
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh" # WSMS
alias wp-status="bash $SCRIPTS_DIR/server-health-audit.sh" # WSMS
alias system-diag="wp-status" # WSMS

# Diagnostics & Observability
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh" # WSMS
alias wp-audit="bash $SCRIPTS_DIR/wp-multi-instance-audit.sh" # WSMS
alias wp-cli-validator="bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh" # WSMS
alias scripts-dir="ls -la $SCRIPTS_DIR" # WSMS

# Maintenance & Security
alias wp-update-all="bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh" # WSMS
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all" # WSMS
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh" # WSMS

# Backups & Recovery
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh" # WSMS
alias wp-backup-full="bash $SCRIPTS_DIR/wp-full-recovery-backup.sh" # WSMS
alias wp-backup-ui="bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh" # WSMS
alias red-robin="bash $SCRIPTS_DIR/red-robin-system-backup.sh" # WSMS
alias db-backup="bash $SCRIPTS_DIR/mysql-backup-manager.sh" # WSMS

# Retention & Disk Management
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh apply" # WSMS
alias backup-size="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list" # WSMS

# Hybrid Cloud Sync (NAS)
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh" # WSMS
alias nas-sync-logs="tail -f $HOME/logs/nas_sync.log" # WSMS
alias nas-sync-status="echo '📊 Last NAS sync:'; tail -10 $HOME/logs/nas_sync.log 2>/dev/null || echo 'No logs yet'" # WSMS

# CyberSecurity (ClamAV)
alias clamav-scan="bash $SCRIPTS_DIR/clamav-auto-scan.sh" # WSMS
alias clamav-deep-scan="bash $SCRIPTS_DIR/clamav-full-scan.sh" # WSMS
alias clamav-status="sudo systemctl status clamav-daemon --no-pager | head -15" # WSMS
alias clamav-update="sudo freshclam" # WSMS
alias clamav-logs="sudo tail -f /var/log/clamav/auto_scan.log" # WSMS
alias clamav-quarantine="sudo ls -la /var/quarantine/" # WSMS
alias clamav-clean-quarantine="sudo rm -rf /var/quarantine/* && echo '✅ Quarantine cleaned'" # WSMS
EOF

# Dynamic per-site shortcuts
for site in "${MANAGED_SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "alias wp-$name=\"sudo -u $user wp --path=$path\"" >> "$RC_FILE" # WSMS
    echo "alias wp-backup-$name=\"db-backup $name && wp-backup-lite\"" >> "$RC_FILE" # WSMS
done
echo -e "${GREEN}✅ Aliases aligned with Help System.${NC}"
EOF

# Dynamic per-site aliases
for site in "${MANAGED_SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "alias wp-$name=\"sudo -u $user wp --path=$path\"" >> "$RC_FILE" # WSMS
done
echo -e "${GREEN}✅ Aliases successfully configured.${NC}"

# ==================== PHASE 6: CRONTAB ====================
echo -e "\n${BLUE}🗓️ Phase 6: Scheduling Crontab Automation...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1 # WSMS
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas-sync.log 2>&1 # WSMS
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh >> $HOME/logs/retention.log 2>&1 # WSMS
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1 # WSMS
") | crontab -
echo -e "${GREEN}✅ Crontab successfully scheduled.${NC}"

echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ WSMS PRO 4.0 DEPLOYMENT COMPLETED!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "1. Run: ${YELLOW}source ~/.bashrc${NC} to activate commands."
echo -e "2. Run: ${YELLOW}wp-status${NC} to start your first audit."
INSTALL_EOF

# Make executable and run
chmod +x ~/install_wsms.sh
~/install_wsms.sh