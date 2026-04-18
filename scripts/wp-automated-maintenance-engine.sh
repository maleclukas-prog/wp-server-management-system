#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🔄 FLEET-WIDE MAINTENANCE ENGINE
# Description: Orchestrates core/plugin updates across all tenants 
#              with post-patch optimization and schema migration.
# =================================================================
source $HOME/scripts/wsms-config.sh

echo -e "🔄 ${CYAN}STARTING AUTOMATED FLEET MAINTENANCE...${NC}"

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 Updating: $name"

    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        # 1. Core Update
        sudo -u "$user" wp --path="$path" core update --quiet
        
        # 2. Plugin & Theme Update
        sudo -u "$user" wp --path="$path" plugin update --all --quiet
        sudo -u "$user" wp --path="$path" theme update --all --quiet
        
        # 3. Database Migration (Crucial for Zepz reliability!)
        sudo -u "$user" wp --path="$path" core update-db --quiet
        
        # 4. Optimization
        sudo -u "$user" wp --path="$path" cache flush --quiet
        sudo -u "$user" wp --path="$path" transient delete --expired --quiet
        
        echo -e "   ${GREEN}✅ Maintenance for $name successful.${NC}"
    else
        echo -e "   ${RED}❌ Error: WP-CLI cannot access $name. Check permissions.${NC}"
    fi
done
echo -e "\n🎉 ${GREEN}ALL INSTANCES ARE PATCHED AND OPTIMIZED.${NC}"