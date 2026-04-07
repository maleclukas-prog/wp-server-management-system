#!/bin/bash
# =================================================================
# 🔄 AUTOMATED MAINTENANCE ENGINE - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🔄 INITIATING GLOBAL MAINTENANCE CYCLE${NC}"
echo "=========================================================="

total_updates=0; failures=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🌐 Processing: $name${NC}"
    
    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ❌ ${RED}Invalid environment${NC}"
        ((failures++))
        continue
    fi
    
    # Core update
    if sudo -u "$user" wp --path="$path" core check-update --format=count 2>/dev/null | grep -q "^[1-9]"; then
        echo "   📦 Updating core..."
        sudo -u "$user" wp --path="$path" core update --quiet && ((total_updates++))
    fi
    
    # Plugin updates
    plugin_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
    if [ "$plugin_updates" -gt 0 ]; then
        echo "   🔌 Updating $plugin_updates plugins..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet
        total_updates=$((total_updates + plugin_updates))
    fi
    
    # Database migration
    sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" cache flush --quiet
    
    echo -e "   ✅ ${GREEN}Completed${NC}"
done

echo -e "\n${CYAN}📊 SUMMARY:${NC} $total_updates updates applied, $failures failures"
