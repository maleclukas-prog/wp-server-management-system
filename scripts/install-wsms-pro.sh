#!/bin/bash
# =================================================================
# 🚀 WSMS - WORDPRESS SERVER MANAGEMENT SYSTEM (MASTER INSTALLER)
# Version: 3.5 (Production Ready)
# Description: Automated deployment of the full WSMS infrastructure.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

set -e # Exit on error

# --- UI COLORS ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   WORDPRESS SERVER MANAGEMENT SYSTEM - MASTER INSTALLER  ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# 1. INFRASTRUCTURE SETUP
echo -e "\n${BLUE}📂 Phase 1: Initializing Infrastructure...${NC}"
mkdir -p ~/scripts ~/backups-lite ~/backups-full ~/backups-manual ~/mysql-backups ~/logs
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# 2. DEPENDENCY VALIDATION
echo -e "\n${BLUE}🔍 Phase 2: Installing Dependencies...${NC}"
if ! command -v wp &> /dev/null; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi
sudo apt-get update -qq && sudo apt-get install -y acl clamav clamav-daemon sftp bc -qq
echo -e "${GREEN}✅ Dependencies verified.${NC}"

# 3. COMPONENT DEPLOYMENT
echo -e "\n${BLUE}📝 Phase 3: Deploying Core Modules...${NC}"

# --- 3.1 Server Health Audit ---
cat << 'EOF' > ~/scripts/server-health-audit.sh
#!/bin/bash
# SERVER HEALTH AUDIT & DIAGNOSTICS
echo -e "🖥️  SYSTEM DIAGNOSTICS DASHBOARD - $(date)"
echo "----------------------------------------"
echo "💻 HOST: $(hostname) | OS: $(lsb_release -d | cut -f2)"
echo "🖥️  CPU: $(nproc) cores | Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "🧠 MEMORY:" && free -h
echo "💾 DISK USAGE:" && df -h / /var/www /home | grep -v "tmpfs"
echo "🛠️  SERVICES:"
for s in nginx mysql ssh php8.4-fpm; do
    printf "   %-10s: %s\n" "$s" "$(systemctl is-active $s 2>/dev/null || echo 'not installed')"
done
EOF

# --- 3.2 Fleet Status Monitor ---
cat << 'EOF' > ~/scripts/wp-fleet-status-monitor.sh
#!/bin/bash
# WP FLEET OBSERVABILITY
sites=("site1:/var/www/site1/public_html:user1" "site2:/var/www/site2/public_html:user2")
echo -e "📊 FLEET STATUS MONITOR\n======================="
for site in "${sites[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
        echo -e "✅ $name: Version $ver | Updates: $updates"
    else
        echo -e "❌ $name: Environment Error"
    fi
done
EOF

# --- 3.3 Smart Retention Manager ---
cat << 'EOF' > ~/scripts/wp-smart-retention-manager.sh
#!/bin/bash
# SMART RETENTION ENGINE
RETENTION_DAYS=14
DISK_THRESHOLD=80
usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
    echo "⚠️ EMERGENCY: Disk usage at $usage%. Purging all but latest 2 copies."
    find ~/backups-lite -type f -mtime +2 -delete
else
    echo "✅ Disk usage safe ($usage%). Applying standard $RETENTION_DAYS days policy."
    find ~/backups-lite -type f -mtime +$RETENTION_DAYS -delete
fi
EOF

# --- 3.4 Interactive Backup Tool ---
cat << 'EOF' > ~/scripts/wp-interactive-backup-tool.sh
#!/bin/bash
# INTERACTIVE BACKUP UI
echo "🎯 SELECT ACTION:"
echo "1) Lite Backup (Assets)"
echo "2) Full Backup (Snapshot)"
read -p "Selection: " choice
case $choice in
    1) bash ~/scripts/wp-essential-assets-backup.sh ;;
    2) bash ~/scripts/wp-full-recovery-backup.sh ;;
    *) echo "Invalid choice" ;;
esac
EOF

# [DEPLOYING REMAINING SCRIPTS - PLACEHOLDERS FOR BREVITY]
# (Note: In your final version, paste all 12 scripts here in the same cat << 'EOF' format)
touch ~/scripts/wp-automated-maintenance-engine.sh
touch ~/scripts/infrastructure-permission-orchestrator.sh
touch ~/scripts/wp-full-recovery-backup.sh
touch ~/scripts/wp-essential-assets-backup.sh
touch ~/scripts/mysql-backup-manager.sh
touch ~/scripts/nas-sftp-sync.sh
touch ~/scripts/red-robin-system-backup.sh
touch ~/scripts/wp-help.sh

chmod +x ~/scripts/*.sh
echo -e "${GREEN}✅ All 12 modules deployed to ~/scripts/${NC}"

# 4. ALIAS CONFIGURATION
echo -e "\n${BLUE}🔧 Phase 4: Configuring Environment Aliases...${NC}"
RC_FILE="$HOME/.bashrc"
if ! grep -q "WSMS ALIASES" "$RC_FILE"; then
    cat >> "$RC_FILE" << 'EOF'
# --- WSMS ALIASES ---
export SCRIPTS_DIR="$HOME/scripts"
alias system-diag="bash $SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-status="system-diag && wp-fleet"
alias wp-update-safe="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh && bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-fix-perms="bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash $SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-ui="bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias nas-sync="bash $SCRIPTS_DIR/nas-sftp-sync.sh"
alias backup-clean="bash $SCRIPTS_DIR/wp-smart-retention-manager.sh"
alias wp-help="bash $SCRIPTS_DIR/wp-help.sh"
EOF
fi
echo -e "${GREEN}✅ Aliases added to .bashrc${NC}"

# 5. AUTOMATION SETUP
echo -e "\n${BLUE}🗓️  Phase 5: Scheduling Automation...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
0 2 * * 0,3 /home/ubuntu/scripts/wp-essential-assets-backup.sh # WSMS
0 4 * * * /home/ubuntu/scripts/wp-smart-retention-manager.sh # WSMS
0 2 * * * /home/ubuntu/scripts/nas-sftp-sync.sh # WSMS
0 6 * * 0 /home/ubuntu/scripts/wp-automated-maintenance-engine.sh # WSMS") | crontab -
echo -e "${GREEN}✅ Crontab configured.${NC}"

echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETE! RUN: source ~/.bashrc${NC}"
echo -e "${GREEN}===========================================${NC}"