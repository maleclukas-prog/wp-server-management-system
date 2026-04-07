#!/bin/bash
# =================================================================
# 📊 WORDPRESS FLEET OBSERVABILITY & INVENTORY AUDIT
# Description: Automated monitoring tool to assess the health, 
#              versioning, and update status of multiple WP 
#              environments in a multi-tenant infrastructure.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# UI Colors for professional reporting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📊 INITIATING INFRASTRUCTURE HEALTH AUDIT${NC}"
echo "=========================================================="
echo "⏰ Audit Timestamp: $(date)"
echo ""

# Multi-Tenant Infrastructure Mapping
# Format: "instance_id:filesystem_path:system_user"
sites=(
    "production-site-1:/var/www/site1/public_html:user1"
    "staging-site-2:/var/www/site2/public_html:user2"
    "dev-site-3:/var/www/site3/public_html:user3"
)

total_instances=0
healthy_instances=0

for site in "${sites[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    ((total_instances++))

    echo -e "${YELLOW}🌐 Instance: $name${NC}"
    echo "   📍 Root Path: $path"
    echo "   👤 System User: $user"

    # 1. Filesystem Integrity Check
    if [ ! -d "$path" ]; then
        echo -e "   ❌ ${RED}Status: Directory missing or inaccessible.${NC}"
        continue
    fi

    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ❌ ${RED}Status: WordPress core configuration not found.${NC}"
        continue
    fi

    ((healthy_instances++))
    echo -e "   ✅ ${GREEN}Status: Environment Verified.${NC}"

    # 2. Versioning & Asset Audit
    # Using WP-CLI with user impersonation for security isolation
    version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
    plugins=$(sudo -u "$user" wp --path="$path" plugin list --format=count 2>/dev/null || echo "0")
    themes=$(sudo -u "$user" wp --path="$path" theme list --format=count 2>/dev/null || echo "0")

    echo "   📦 Core Version: $version"
    echo "   🔌 Active Plugins: $plugins | 🎨 Themes: $themes"

    # 3. Proactive Update Monitoring
    plugin_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
    theme_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")

    if [ "$plugin_updates" -gt "0" ] || [ "$theme_updates" -gt "0" ]; then
        echo -e "   ⚠️  ${YELLOW}Maintenance Required: $plugin_updates plugins, $theme_updates themes awaiting updates.${NC}"
    else
        echo -e "   ✅ ${GREEN}Maintenance Status: All components up to date.${NC}"
    fi
    echo "   -------------------------------------------------------"
done

# --- FINAL FLEET SUMMARY ---
echo -e "\n${CYAN}📈 FLEET AUDIT SUMMARY:${NC}"
echo "   Total Instances Tracked: $total_instances"
echo -e "   Healthy Instances: ${GREEN}$healthy_instances${NC}"
echo -e "   Critical Alerts: ${RED}$((total_instances - healthy_instances))${NC}"

if [ "$healthy_instances" -eq "$total_instances" ]; then
    echo -e "\n${GREEN}🎉 OPERATIONAL EXCELLENCE: All instances are healthy and accessible.${NC}"
elif [ "$healthy_instances" -eq 0 ]; then
    echo -e "\n${RED}🚨 CRITICAL FLEET FAILURE: All instances report issues.${NC}"
else
    echo -e "\n${YELLOW}⚠️  ATTENTION REQUIRED: Some instances require administrative intervention.${NC}"
fi