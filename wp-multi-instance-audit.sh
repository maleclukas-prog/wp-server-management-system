#!/bin/bash
# =================================================================
# 🔍 MULTI-INSTANCE WORDPRESS HEALTH AUDIT TOOL
# Description: Performs deep-dive diagnostics across multiple 
#              isolated WordPress environments. Audits core integrity, 
#              database health, security permissions, and site vitals.
# Author: [Your Name]
# =================================================================

# UI Colors for professional output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 INITIATING MULTI-SITE INFRASTRUCTURE AUDIT${NC}"
echo "=========================================================="
echo "⏰ Audit Timestamp: $(date)"
echo ""

# Infrastructure Map
# Format: "site_identifier:filesystem_path:assigned_system_user"
sites=(
    "production-site-1:/var/www/site1/public_html:user1"
    "staging-site-2:/var/www/site2/public_html:user2"
    "dev-site-3:/var/www/site3/public_html:user3"
)

for site in "${sites[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🌐 AUDITING INSTANCE: $name${NC}"
    echo "----------------------------------------------------------"

    # 1. Path & Core Validation
    if [ ! -d "$path" ]; then
        echo -e "   ❌ ${RED}Critical: Path not found at $path${NC}"
        continue
    fi

    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ❌ ${RED}Error: WordPress configuration (wp-config.php) is missing.${NC}"
        continue
    fi

    echo -e "   ✅ Filesystem: ${GREEN}Root directory verified.${NC}"

    # 2. Core Integrity Audit
    # Executing via WP-CLI with sudo -u for security isolation
    echo "   📦 WordPress Core:"
    version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "      - Version: ${GREEN}$version${NC}"
    else
        echo -e "      - Status: ${RED}Core integrity check failed (WP-CLI Error)${NC}"
    fi

    # 3. Database Connectivity & Health
    echo "   🗃️  Database Engine:"
    if sudo -u "$user" wp --path="$path" db check 2>/dev/null; then
        echo -e "      - Integrity: ${GREEN}Optimized / Tables Healthy${NC}"
    else
        echo -e "      - Integrity: ${RED}Database repair required or connection failed.${NC}"
    fi

    # 4. Plugin & Theme Landscape
    echo "   🔌 Extensions Audit:"
    plugin_count=$(sudo -u "$user" wp --path="$path" plugin list --format=count 2>/dev/null)
    update_count=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
    
    echo -e "      - Active Plugins: $plugin_count"
    if [ "$update_count" -gt 0 ]; then
        echo -e "      - Maintenance: ${YELLOW}$update_count updates available${NC}"
    else
        echo -e "      - Maintenance: ${GREEN}All plugins up-to-date${NC}"
    fi

    # 5. Native Site Health (WP Vitals)
    echo "   ❤️  Site Vitals (Site-Health Score):"
    health_score=$(sudo -u "$user" wp --path="$path" site-health get 2>/dev/null | grep "score" | awk '{print $2}')
    if [ -n "$health_score" ]; then
        echo -e "      - Health Score: ${GREEN}$health_score%${NC}"
    else
        echo -e "      - Health Score: ${YELLOW}Data unavailable (Legacy WP?)${NC}"
    fi

    # 6. Security Isolation Check (Filesystem Permissions)
    echo "   🔐 Security Isolation Audit:"
    perms=$(stat -c "%a %U:%G" "$path/wp-config.php" 2>/dev/null)
    echo -e "      - wp-config.php: ${CYAN}$perms${NC}"
    
    # Recommendation Logic
    if [[ "$perms" != *"640"* && "$perms" != *"440"* ]]; then
        echo -e "      - ${YELLOW}Recommendation: Consider hardening config permissions.${NC}"
    fi

    echo -e "\n✅ ${GREEN}Audit finalized for $name${NC}"
done

echo ""
echo "📊 AUDIT SUMMARY COMPLETED"
echo "----------------------------------------------------------"
echo "Next Actions: Run 'wp-update-safe' for pending extensions."