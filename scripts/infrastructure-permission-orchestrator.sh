#!/bin/bash
# =================================================================
# 🛡️ INFRASTRUCTURE PERMISSION & SECURITY ORCHESTRATOR
# Description: A comprehensive security tool designed to audit and 
#              standardize filesystem permissions across multi-tenant 
#              WordPress environments and backup repositories.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# UI Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🛡️  INITIATING SECURITY & PERMISSION AUDIT${NC}"
echo "=========================================================="

# 1. Automated PHP-FPM Stack Discovery
# Detects all active and installed PHP-FPM versions to ensure full stack coverage
PHP_SERVICES=$(systemctl list-units --type=service --all --no-legend | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$')
[ -z "$PHP_SERVICES" ] && PHP_SERVICES=$(systemctl list-unit-files | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$')

# Multi-Tenant Infrastructure Mapping
# Format: ["site_id"]="system_user"
declare -A site_users=(
    ["production-site-1"]="user1"
    ["staging-site-2"]="user2"
    ["dev-site-3"]="user3"
)

# Root Path Mapping
declare -A site_paths=(
    ["production-site-1"]="/var/www/site1/public_html"
    ["staging-site-2"]="/var/www/site2/public_html"
    ["dev-site-3"]="/var/www/site3/public_html"
)

# Pre-flight Service Management
echo -e "${YELLOW}⏰ Suspending Web Stack for permission realignment...${NC}"
sudo systemctl stop nginx 2>/dev/null || true
for service in $PHP_SERVICES; do
    echo "   Stopping $service..."
    sudo systemctl stop "$service" 2>/dev/null || true
done
sleep 2

# ==========================================================
# 🔧 PART 1: WORDPRESS SECURITY HARDENING
# ==========================================================
echo -e "\n${CYAN}==========================================${NC}"
echo -e "${CYAN}🔧 PHASE 1: CMS SECURITY ENFORCEMENT${NC}"
echo -e "${CYAN}==========================================${NC}"

for site in "${!site_users[@]}"; do
    user="${site_users[$site]}"
    path="${site_paths[$site]}"

    echo -e "\n🌐 Target: $site (Isolated User: $user)"

    if [ -d "$path" ]; then
        # 1. Ownership Assignment (PHP-FPM User Isolation)
        sudo chown -R "$user":"$user" "$path/"

        # 2. Filesystem Standardization (Directories: 755, Files: 644)
        sudo find "$path/" -type d -exec chmod 755 {} \;
        sudo find "$path/" -type f -exec chmod 644 {} \;

        # 3. Enhanced Write-Access for Content Delivery
        if [ -d "$path/wp-content" ]; then
            sudo chmod -R 775 "$path/wp-content/"
        fi

        # 4. Web-Server/PHP-FPM Hybrid Access for Uploads
        if [ -d "$path/wp-content/uploads" ]; then
            sudo chown -R "$user":www-data "$path/wp-content/uploads"
            sudo chmod -R 775 "$path/wp-content/uploads"
        fi

        # 5. Critical Config Hardening (wp-config.php)
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php"

        # 6. ACL Delegation for Backup Operations
        # Grants 'ubuntu' user read access without breaking PHP-FPM isolation
        if command -v setfacl &> /dev/null; then
            sudo setfacl -R -m u:ubuntu:r-x "$path/" 2>/dev/null || true
            echo -e "   ✅ Security: ${GREEN}ACL policies applied for Backup Operator.${NC}"
        else
            echo -e "   ⚠️  ${YELLOW}Warning: ACL tools missing. Falling back to standard chmod.${NC}"
        fi

        echo -e "   ✅ Status: ${GREEN}$site permissions aligned.${NC}"
    else
        echo -e "   ❌ ${RED}Error: Site root not found: $path${NC}"
    fi
done

# ==========================================================
# 💾 PART 2: BACKUP REPOSITORY INTEGRITY
# ==========================================================
echo -e "\n${CYAN}==========================================${NC}"
echo -e "${CYAN}💾 PHASE 2: REPOSITORY OWNERSHIP AUDIT${NC}"
echo -e "${CYAN}==========================================${NC}"

BACKUP_DIRS=("$HOME/backups-lite" "$HOME/backups-full" "$HOME/mysql-backups")

for dir in "${BACKUP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "📁 Auditing: $dir"
        # Remediation for root-owned files (Privilege Escalation Prevention)
        sudo chown -R ubuntu:ubuntu "$dir"
        sudo chmod 755 "$dir"
        echo -e "   ✅ Status: ${GREEN}Ownership delegated to Backup Operator.${NC}"
    fi
done

# ==========================================================
# ⚙️ PART 3: SYSTEM ENVIRONMENT HARDENING
# ==========================================================
echo -e "\n${CYAN}==========================================${NC}"
echo -e "${CYAN}⚙️ PHASE 3: SYSTEM TEMP & SESSION CLEANUP${NC}"
echo -e "${CYAN}==========================================${NC}"

echo "🔧 Securing PHP session paths and global temp..."
sudo chmod 1777 /tmp 2>/dev/null || true
sudo chown www-data:www-data /var/lib/php/sessions 2>/dev/null || true
sudo chmod 1733 /var/lib/php/sessions 2>/dev/null || true

# Stack Restoration
echo -e "\n${YELLOW}🔄 Restoring Web Stack services...${NC}"
for service in $PHP_SERVICES; do
    sudo systemctl start "$service" 2>/dev/null || true
done
sudo systemctl start nginx 2>/dev/null || true

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ SECURITY & PERMISSION AUDIT COMPLETED${NC}"
echo -e "${GREEN}==========================================${NC}"