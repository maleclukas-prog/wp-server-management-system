#!/bin/bash
# =================================================================
# 🔍 MULTI-INSTANCE DEEP AUDIT - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🔍 INITIATING DEEP INFRASTRUCTURE AUDIT${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}🌐 AUDITING: $name${NC}"
    echo "----------------------------------------------------------"
    
    if [ ! -f "$path/wp-config.php" ]; then
        echo -e "   ❌ ${RED}wp-config.php missing${NC}"
        continue
    fi
    
    # Core version
    version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null)
    echo "   📦 Core Version: ${GREEN}$version${NC}"
    
    # Database health
    if sudo -u "$user" wp --path="$path" db check 2>/dev/null; then
        echo "   🗃️  Database: ${GREEN}Healthy${NC}"
    else
        echo "   🗃️  Database: ${RED}Issues detected${NC}"
    fi
    
    # Plugin updates
    updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null)
    if [ "$updates" -gt 0 ]; then
        echo "   🔌 Plugins: ${YELLOW}$updates updates available${NC}"
    else
        echo "   🔌 Plugins: ${GREEN}Up to date${NC}"
    fi
done
