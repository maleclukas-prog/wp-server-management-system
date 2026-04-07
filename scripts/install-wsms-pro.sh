#!/bin/bash
# =================================================================
# 🚀 WSMS PRO - MASTER INSTALLATION ORCHESTRATOR
# Version: 3.5 (English Production Ready)
# Description: Automated deployment of the full WordPress Server 
#              Management System suite.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

set -e # Exit on any error

# --- UI COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}🚀 WORDPRESS SERVER MANAGEMENT SYSTEM - MASTER INSTALLER${NC}"
echo -e "${CYAN}==========================================================${NC}"

# 1. INFRASTRUCTURE SETUP
echo -e "\n${BLUE}📁 Phase 1: Initializing Infrastructure...${NC}"
DIRS=(
    "$HOME/scripts"
    "$HOME/backups-lite"
    "$HOME/backups-full"
    "$HOME/backups-manual"
    "$HOME/mysql-backups"
    "$HOME/logs"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "   ✅ Created: $dir"
    fi
done

sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# 2. DEPENDENCY VALIDATION
echo -e "\n${BLUE}🔍 Phase 2: Validating Dependencies (WP-CLI, ACL, ClamAV)...${NC}"
# WP-CLI
if ! command -v wp &> /dev/null; then
    echo "📥 Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi
# Packages
sudo apt-get update -qq
sudo apt-get install -y acl clamav clamav-daemon sftp bc -qq
echo -e "${GREEN}✅ Dependencies verified.${NC}"

# 3. SCRIPT DEPLOYMENT
echo -e "\n${BLUE}📝 Phase 3: Deploying Core Management Modules...${NC}"

# --- Internal Helper to save scripts ---
deploy_script() {
    local name=$1
    local content=$2
    echo "$content" > "$HOME/scripts/$name"
    chmod +x "$HOME/scripts/$name"
    echo -e "   📦 Deployed: ${GREEN}$name${NC}"
}

# 3.1 Server Health Audit
deploy_script "server-health-audit.sh" '#!/bin/bash
# [PASTE CONTENT OF server-health-audit.sh HERE]'

# 3.2 Fleet Status Monitor
deploy_script "wp-fleet-status-monitor.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-fleet-status-monitor.sh HERE]'

# 3.3 Automated Maintenance Engine
deploy_script "wp-automated-maintenance-engine.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-automated-maintenance-engine.sh HERE]'

# 3.4 Smart Retention Manager
deploy_script "wp-smart-retention-manager.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-smart-retention-manager.sh HERE]'

# 3.5 Infrastructure Permission Orchestrator
deploy_script "infrastructure-permission-orchestrator.sh" '#!/bin/bash
# [PASTE CONTENT OF infrastructure-permission-orchestrator.sh HERE]'

# 3.6 Full Recovery Backup
deploy_script "wp-full-recovery-backup.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-full-recovery-backup.sh HERE]'

# 3.7 Essential Assets Backup
deploy_script "wp-essential-assets-backup.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-essential-assets-backup.sh HERE]'

# 3.8 MySQL Backup Manager
deploy_script "mysql-backup-manager.sh" '#!/bin/bash
# [PASTE CONTENT OF mysql-backup-manager.sh HERE]'

# 3.9 Hybrid Cloud Sync (NAS)
deploy_script "nas-sftp-sync.sh" '#!/bin/bash
# [PASTE CONTENT OF nas-sftp-sync.sh HERE]'

# 3.10 System Recovery (Red Robin)
deploy_script "red-robin-system-backup.sh" '#!/bin/bash
# [PASTE CONTENT OF red-robin-system-backup.sh HERE]'

# 3.11 Interactive Backup Tool
deploy_script "wp-interactive-backup-tool.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-interactive-backup-tool.sh HERE]'

# 3.12 Help System
deploy_script "wp-help.sh" '#!/bin/bash
# [PASTE CONTENT OF wp-help.sh HERE]'

# 4. ENVIRONMENT PROVISIONING (Aliases)
echo -e "\n${BLUE}🔧 Phase 4: Provisioning Shell Environment (Aliases)...${NC}"
RC_FILE="$HOME/.bashrc"
if ! grep -q "WORDPRESS MANAGEMENT SYSTEM - ALIASES" "$RC_FILE"; then
    cat >> "$RC_FILE" << EOF

# ============================================
# WORDPRESS MANAGEMENT SYSTEM - ALIASES
# ============================================
export SCRIPTS_DIR="\$HOME/scripts"
alias system-diag="bash \$SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash \$SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash \$SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias wp-update-all="bash \$SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all"
alias wp-fix-perms="bash \$SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"
alias wp-backup-lite="bash \$SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash \$SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash \$SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias red-robin="bash \$SCRIPTS_DIR/red-robin-system-backup.sh"
alias db-backup="bash \$SCRIPTS_DIR/mysql-backup-manager.sh"
alias backup-clean="bash \$SCRIPTS_DIR/wp-smart-retention-manager.sh apply"
alias backup-size="bash \$SCRIPTS_DIR/wp-smart-retention-manager.sh list"
alias nas-sync="bash \$SCRIPTS_DIR/nas-sftp-sync.sh"
alias clamav-scan="bash \$SCRIPTS_DIR/clamav-auto-scan.sh"
alias wp-help="bash \$SCRIPTS_DIR/wp-help.sh"
alias wp-status="system-diag && wp-fleet"
EOF
    echo -e "   ✅ Aliases injected into $RC_FILE."
else
    echo -e "   ⚠️  Aliases already exist. Skipping."
fi

# 5. AUTOMATION (Crontab)
echo -e "\n${BLUE}🗓️  Phase 5: Scheduling Automation Cycles (Crontab)...${NC}"
(crontab -l 2>/dev/null | grep -v "WSMS"; echo "
# --- WSMS AUTOMATION SCHEDULE ---
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1 # WSMS
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas-sync.log 2>&1 # WSMS
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/security-scan.log 2>&1 # WSMS
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh apply >> $HOME/logs/retention.log 2>&1 # WSMS
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1 # WSMS
0 2 * * 0,3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1 # WSMS
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-full.log 2>&1 # WSMS") | crontab -
echo -e "${GREEN}✅ Crontab successfully configured.${NC}"

# 6. FINAL SUMMARY
echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ WSMS PRO DEPLOYMENT COMPLETED!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "1. Run: ${YELLOW}source ~/.bashrc${NC} to load aliases."
echo -e "2. Run: ${YELLOW}wp-status${NC} to audit your new system."
echo -e "3. Run: ${YELLOW}wp-help${NC} for command reference."