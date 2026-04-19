#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - WP-CLI INFRASTRUCTURE VALIDATOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "🧪 VALIDATING WP-CLI INTEGRATION v4.2..."
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ${RED}❌ $name: wp-config.php not found${NC}"
        continue
    fi
    
    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
        echo -e "   ${GREEN}✅ $name: Connected (WP v$version)${NC}"
    else
        echo -e "   ${RED}❌ $name: WP-CLI connection failed${NC}"
        echo -e "      ${YELLOW}💡 Check: sudo -u $user wp --path=$path core version${NC}"
    fi
done

echo -e "\n${YELLOW}📋 WP-CLI Version:${NC}"
wp --version 2>/dev/null || echo "   ❌ WP-CLI not found in PATH"

echo -e "\n✅ Validation complete."