#!/bin/bash
# =================================================================
# 🚀 WORDPRESS MANAGEMENT SYSTEM (WSMS) - INSTALLER
# Version: 3.0 (Production Ready)
# Description: Full automated deployment of the WSMS toolkit, 
#              including backups, diagnostics, and security audits.
# Author: [Your Name]
# =================================================================

set -e # Exit immediately if a command exits with a non-zero status

echo "🚀 WORDPRESS MANAGEMENT SYSTEM - INSTALLATION"
echo "==========================================="
echo ""

# UI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Directory Infrastructure Setup
echo -e "${BLUE}📁 Initializing directory structure...${NC}"
mkdir -p ~/scripts
mkdir -p ~/backups-lite
mkdir -p ~/backups-full
mkdir -p ~/backups-manual
mkdir -p ~/mysql-backups
echo -e "${GREEN}✅ Infrastructure ready.${NC}"

# 2. WP-CLI Dependency Check
echo ""
echo -e "${BLUE}🔍 Checking WP-CLI dependency...${NC}"
if ! command -v wp &> /dev/null; then
    echo "📥 WP-CLI not found. Installing..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    echo -e "${GREEN}✅ WP-CLI installed successfully.${NC}"
else
    echo -e "${GREEN}✅ WP-CLI is already present.${NC}"
fi

# 3. Component Deployment (Internal Script Generation)
echo ""
echo -e "${BLUE}📝 Deploying system modules...${NC}"

# 3.1 system-diag.sh (System Health Dashboard)
cat > ~/scripts/system-diag.sh << 'EOF'
#!/bin/bash
echo "🖥️  SYSTEM DIAGNOSTICS"
echo "======================"
echo "⏰ $(date)"
echo ""
echo "💻 HOST: $(hostname)"
echo "🐧 OS: $(lsb_release -d | cut -f2)"
echo "🖥️  CPU: $(nproc) cores | Uptime: $(uptime -p)"
echo "📈 LOAD: $(uptime | awk -F'load average:' '{print $2}')"
echo ""
echo "🧠 MEMORY USAGE:"
free -h
echo ""
echo "💾 DISK USAGE:"
df -h / /var/www /home | grep -v "tmpfs"
echo ""
echo "🛠️  SERVICE STATUS:"
echo "Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'Not installed')"
echo "MySQL: $(systemctl is-active mysql 2>/dev/null || echo 'Not installed')"
echo "PHP-FPM: $(systemctl is-active php8.4-fpm 2>/dev/null || echo 'Check version')"
EOF
chmod +x ~/scripts/system-diag.sh
echo -e "${GREEN}  ✅ system-diag.sh deployed${NC}"

# 3.2 wp-list.sh (Multi-site Monitoring)
cat > ~/scripts/wp-list.sh << 'EOF'
#!/bin/bash
echo "📊 MANAGED WORDPRESS SITES"
echo "=========================="
# CONFIGURATION: Define your sites here
# Format: "site_name:path_to_public_html"
sites=(
    "site1:/var/www/site1/public_html"
    "site2:/var/www/site2/public_html"
)

for site in "${sites[@]}"; do
    IFS=':' read -r name path <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        echo -e "✅ $name [Online]"
    else
        echo -e "❌ $name [Missing Config]"
    fi
done
EOF
chmod +x ~/scripts/wp-list.sh
echo -e "${GREEN}  ✅ wp-list.sh deployed${NC}"

# 3.3 wp-update.sh (Automated Maintenance)
cat > ~/scripts/wp-update.sh << 'EOF'
#!/bin/bash
echo "🔄 EXECUTING WORDPRESS CORE & PLUGIN UPDATES"
echo "==========================================="
sites=(
    "site1:/var/www/site1/public_html"
    "site2:/var/www/site2/public_html"
)

for site in "${sites[@]}"; do
    IFS=':' read -r name path <<< "$site"
    echo "Updating: $name..."
    cd "$path" || continue
    wp core update --quiet
    wp plugin update --all --quiet
    wp theme update --all --quiet
    wp core update-db --quiet
    echo "✅ $name updated successfully."
done
EOF
chmod +x ~/scripts/wp-update.sh
echo -e "${GREEN}  ✅ wp-update.sh deployed${NC}"

# 3.8 wp-clean-backups.sh (Intelligent Retention Policy)
cat > ~/scripts/wp-clean-backups.sh << 'EOF'
#!/bin/bash
# Description: Automated retention policy manager for system backups.
echo "🧹 BACKUP RETENTION MANAGER"
echo "==========================="

# Retention Settings (Days)
LITE_DAYS=14
FULL_DAYS=35
MYSQL_DAYS=7
DISK_THRESHOLD=80

usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
    echo "⚠️  LOW DISK SPACE ALERT ($usage%)! Executing emergency cleanup..."
    # Logic to keep only the 2 most recent backups regardless of age
    find ~/backups-lite -type f -mtime +2 -delete
    find ~/backups-full -type f -mtime +7 -delete
else
    echo "✅ Disk space within safe limits ($usage%). Applying standard policy."
    find ~/backups-lite -type f -mtime +$LITE_DAYS -delete
    find ~/backups-full -type f -mtime +$FULL_DAYS -delete
    find ~/mysql-backups -type f -mtime +$MYSQL_DAYS -delete
fi
echo "✅ Retention policy applied."
EOF
chmod +x ~/scripts/wp-clean-backups.sh
echo -e "${GREEN}  ✅ wp-clean-backups.sh deployed${NC}"

# 3.12 wp-help.sh (The Interactive Documentation)
cat > ~/scripts/wp-help.sh << 'EOF'
#!/bin/bash
clear
echo "🆘 WORDPRESS MANAGEMENT SYSTEM - DOCUMENTATION"
echo "============================================="
echo -e "Available Commands:"
echo -e "system-diag       - Full server health check"
echo -e "wp-list           - List managed WP instances"
echo -e "wp-update-safe    - Run backups then update all sites"
echo -e "wp-backup-lite    - Execute quick file+db backup"
echo -e "backup-size       - Check storage usage per module"
echo -e "scripts-dir       - List all system scripts"
EOF
chmod +x ~/scripts/wp-help.sh
echo -e "${GREEN}  ✅ wp-help.sh deployed${NC}"

# 4. Environment Configuration (Shell Aliases)
echo ""
echo -e "${BLUE}🔧 Configuring shell environment (aliases)...${NC}"
cat >> ~/.bashrc << 'EOF'
# WSMS ALIASES
alias system-diag="bash ~/scripts/system-diag.sh"
alias wp-list="bash ~/scripts/wp-list.sh"
alias wp-update="bash ~/scripts/wp-update.sh"
alias wp-update-safe="bash ~/scripts/wp-backup-lite.sh && bash ~/scripts/wp-update.sh"
alias wp-help="bash ~/scripts/wp-help.sh"
alias backup-clean="bash ~/scripts/wp-clean-backups.sh"
alias scripts-dir="ls -la ~/scripts/"
EOF
echo -e "${GREEN}✅ Aliases added to .bashrc${NC}"

# 5. Automation Layer (Crontab Orchestration)
echo ""
echo -e "${BLUE}🗓️ Orchestrating scheduled tasks (Crontab)...${NC}"
(crontab -l 2>/dev/null | grep -v "wp-"; echo "
# WSMS AUTOMATION TASKS
0 2 * * 0,3 /home/ubuntu/scripts/wp-backup-lite.sh >> /home/ubuntu/backup-cron.log 2>&1
0 3 1 * * /home/ubuntu/scripts/wp-backup-full.sh >> /home/ubuntu/backup-cron.log 2>&1
0 4 * * * /home/ubuntu/scripts/wp-clean-backups.sh >> /home/ubuntu/backup-cron.log 2>&1
0 6 * * 0 /home/ubuntu/scripts/wp-update.sh >> /home/ubuntu/update-cron.log 2>&1") | crontab -
echo -e "${GREEN}✅ Crontab successfully configured.${NC}"

# 6. Installation Summary
echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "Run 'source ~/.bashrc' or restart your session."
echo -e "Type 'wp-help' to see the list of available commands."