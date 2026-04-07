#!/bin/bash
# =================================================================
# 🖥️  SYSTEM DIAGNOSTICS - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}🖥️  SYSTEM DIAGNOSTICS DASHBOARD${NC}"
echo "========================================"
echo "⏰ Audit Timestamp: $(date)"
echo ""

# Hardware Info
echo -e "${BLUE}💻 HARDWARE & OS INFO:${NC}"
echo "   Host: $(hostname)"
echo "   Kernel: $(uname -r)"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   CPU: $(nproc) cores | Uptime: $(uptime -p)"
echo ""

# Memory & Storage
echo -e "${BLUE}💾 STORAGE STATUS:${NC}"
df -h / /var/www /home | grep -v "tmpfs" | sed 's/^/   /'
echo ""

# Managed Sites Health
echo -e "${BLUE}🌐 MANAGED WORDPRESS INSTANCES:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if [ -f "$path/wp-config.php" ]; then
        echo -e "   ✅ $name: ${GREEN}Active${NC} (User: $user)"
    else
        echo -e "   ❌ $name: ${RED}Missing or misconfigured${NC}"
    fi
done

echo -e "\n${GREEN}✅ DIAGNOSTICS COMPLETE${NC}"
