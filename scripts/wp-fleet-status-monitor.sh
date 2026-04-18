#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 📊 FLEET STATUS MONITOR - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}📊 WORDPRESS FLEET OBSERVABILITY${NC}"
echo "=========================================================="
echo "⏰ Audit Timestamp: $(date)"
echo ""

total=0; healthy=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    ((total++))
    
    echo -e "${YELLOW}🌐 Instance: $name${NC}"
    if [ -f "$path/wp-config.php" ]; then
        version=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        plugins=$(sudo -u "$user" wp --path="$path" plugin list --format=count 2>/dev/null || echo "0")
        echo "   ✅ Status: Active | Version: $version | Plugins: $plugins"
        ((healthy++))
    else
        echo -e "   ❌ ${RED}Status: Inaccessible${NC}"
    fi
done

echo -e "\n${CYAN}📈 SUMMARY:${NC} $healthy/$total healthy instances"
