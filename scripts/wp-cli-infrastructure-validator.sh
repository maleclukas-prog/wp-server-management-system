#!/bin/bash
# =================================================================
# 🧪 WP-CLI INFRASTRUCTURE & CONNECTIVITY VALIDATOR
# Description: Verifies global WP-CLI installation and tests 
#              secure connectivity to individual WordPress instances 
#              within their specific system-user contexts.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# UI Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧪 INITIATING WP-CLI INTEGRATION TEST${NC}"
echo "=========================================================="

# Infrastructure Mapping
# Format: "site_id:filesystem_path:system_user"
sites=(
    "production-site-1:/var/www/site1/public_html:user1"
    "staging-site-2:/var/www/site2/public_html:user2"
    "dev-site-3:/var/www/site3/public_html:user3"
)

# 1. Dependency Validation (Global Binary)
echo -e "${YELLOW}🔍 Phase 1: Checking Global WP-CLI Installation...${NC}"
if /usr/local/bin/wp --info &> /dev/null; then
    echo -e "   ✅ Status: ${GREEN}WP-CLI Binary found and operational.${NC}"
    /usr/local/bin/wp --version | sed 's/^/      - /'
else
    echo -e "   ❌ ${RED}Critical: WP-CLI binary not found in /usr/local/bin/wp${NC}"
    exit 1
fi

# 2. Multi-Tenant Connectivity Test
echo -e "\n${YELLOW}🔍 Phase 2: Testing Secure Site Access & User Impersonation...${NC}"

for site in "${sites[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 Target: $name"
    echo "   📍 Path: $path"
    echo "   👤 Context: $user"

    # Path Verification
    if [ ! -d "$path" ]; then
        echo -e "   ❌ ${RED}Error: Filesystem path does not exist.${NC}"
        continue
    fi

    # Database & Application Connectivity Test
    # Executing 'core version' as the specific site user to verify permission isolation
    if sudo -u "$user" /usr/local/bin/wp --path="$path" core version &> /dev/null; then
        version=$(sudo -u "$user" /usr/local/bin/wp --path="$path" core version)
        echo -e "   ✅ Status: ${GREEN}Connectivity verified.${NC}"
        echo -e "      - Detected WordPress version: $version"
    else
        echo -e "   ❌ ${RED}Error: Connectivity failed. Check DB credentials or user permissions.${NC}"
    fi
done

# 3. Operational Quick Reference
echo -e "\n${CYAN}📋 QUICK REFERENCE FOR ADMINISTRATORS:${NC}"
echo "----------------------------------------------------------"
echo "  wp core version          # Output WordPress version"
echo "  wp plugin list           # List installed plugins"
echo "  wp theme list            # List installed themes"
echo "  wp db size               # Display database utilization"
echo "  wp site-health get       # Fetch internal health score"
echo "----------------------------------------------------------"

echo -e "\n✅ ${GREEN}INFRASTRUCTURE VALIDATION COMPLETED${NC}"