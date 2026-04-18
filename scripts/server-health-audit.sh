#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🖥️  ULTIMATE INFRASTRUCTURE HEALTH AUDIT & DIAGNOSTICS (PRO)
# Description: Professional-grade diagnostic tool auditing hardware, 
#              service orchestration, and per-site application vitals.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

# Load centralized configuration
source $HOME/scripts/wsms-config.sh

# UI Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS DASHBOARD${NC}"
echo "=========================================================="
echo -e "⏰ Audit Timestamp: $(date)"
echo -e "💻 System Host:    $(hostname) | OS: $(lsb_release -d | cut -f2)"
echo "----------------------------------------------------------"

# --- 1. CORE HARDWARE & LOAD ---
echo -e "\n${CYAN}📈 SYSTEM LOAD & RESOURCES:${NC}"
echo "   CPU Cores:    $(nproc)"
echo "   Uptime:       $(uptime -p)"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory:       " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used (" $7 " available)"}'
echo ""

# --- 2. STORAGE UTILIZATION ---
echo -e "${CYAN}💾 STORAGE AUDIT:${NC}"
# Filter for relevant partitions only
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'
echo ""

# --- 3. NETWORK & EXPOSURE ---
echo -e "${CYAN}🌐 NETWORK EXPOSURE:${NC}"
echo "   Primary IP: $(hostname -I | awk '{print $1}')"
echo "   Listening Services (Top 5 Active):"
ss -tulpn | grep -E ":(80|443|22|3306)" | head -5 | sed 's/^/   /'
echo ""

# --- 4. SERVICE ORCHESTRATION ---
echo -e "${CYAN}🛠️  CORE SERVICES STATUS:${NC}"
# Audit critical stack components
CORE_SERVICES=("nginx" "apache2" "mysql" "mariadb" "ssh")
for s in "${CORE_SERVICES[@]}"; do
    status=$(systemctl is-active "$s" 2>/dev/null || echo "not installed")
    if [ "$status" == "active" ]; then
        echo -e "   ✅ $s: ${GREEN}Active / Running${NC}"
    elif [ "$status" != "not installed" ]; then
        echo -e "   ❌ $s: ${RED}$status (Action Required)${NC}"
    fi
done

# --- 5. PHP-FPM STACK DEEP DIVE ---
echo -e "\n${CYAN}🔌 PHP-FPM POOLS & SOCKETS:${NC}"
# Dynamic discovery of active PHP-FPM pools
ACTIVE_PHPS=$(systemctl list-units --type=service --state=active --no-legend | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$' | sed 's/.service//')

if [ -n "$ACTIVE_PHPS" ]; then
    for s in $ACTIVE_PHPS; do
        echo -e "   📦 $s: ${GREEN}Online${NC}"
    done
    echo "   📍 Active Sockets (Unix Domain):"
    sudo ls -1 /run/php/*.sock 2>/dev/null | sed 's/^/      - /'
else
    echo -e "   ❌ ${RED}PHP-FPM: No active pools detected in systemctl${NC}"
fi

# --- 6. PER-SITE APPLICATION AUDIT ---
echo -e "\n${CYAN}🌐 MANAGED WORDPRESS FLEET AUDIT:${NC}"
# Iterate through sites defined in wsms-config.sh
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ Site: $name ]${NC}"
    
    if [ -f "$path/wp-config.php" ]; then
        # Extract application metadata via WP-CLI
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        db_name=$(sudo -u "$user" wp --path="$path" db query "SELECT DATABASE()" --skip-column-names 2>/dev/null || echo "unknown")
        site_php=$(sudo -u "$user" wp --path="$path" eval "echo PHP_VERSION;" 2>/dev/null || echo "unknown")
        plugins_outdated=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        
        echo "      - Core Version: $wp_ver"
        echo "      - PHP Runtime:  $site_php"
        echo "      - DB Context:   $db_name"
        
        if [ "$plugins_outdated" -gt 0 ]; then
            echo -e "      - Updates:      ${YELLOW}$plugins_outdated plugins pending${NC}"
        else
            echo -e "      - Updates:      ${GREEN}Clean (All patched)${NC}"
        fi
        
        # Security Isolation Check
        if id "$user" &>/dev/null; then
            echo -e "      - Security:     ${GREEN}User $user (Isolated)${NC}"
        else
            echo -e "      - Security:     ${RED}Critical: User $user missing!${NC}"
        fi
    else
        echo -e "      - ${RED}CRITICAL: Config missing at $path${NC}"
    fi
    echo ""
done

# --- 7. BACKUP REPOSITORY STATUS ---
echo -e "${CYAN}💾 DATA INTEGRITY (BACKUP REPOSITORIES):${NC}"
backup_dirs=("$HOME/backups-lite" "$HOME/backups-full" "$HOME/mysql-backups")
total_archives=0

for dir in "${backup_dirs[@]}"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f \( -name "*backup*" -o -name "mysql-*" \) 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count archives ($size)"
        total_archives=$((total_archives + count))
    fi
done

# --- 8. INTELLIGENT RECOMMENDATIONS (HEURISTICS) ---
echo -e "\n${YELLOW}🔔 OPERATIONAL RECOMMENDATIONS:${NC}"
echo "----------------------------------------------------------"

# Disk Space Analysis
free_gb=$(df /home | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$free_gb < 5" | bc -l) )); then
    echo -e "   ⚠️  ${RED}CRITICAL:${NC} Extremely low disk space ($free_gb GB). Run 'backup-clean'."
elif (( $(echo "$free_gb < 10" | bc -l) )); then
    echo -e "   ℹ️  ADVICE: Storage nearing 80% capacity ($free_gb GB). Monitor growth."
else
    echo -e "   ✅ STORAGE: System has healthy disk overhead."
fi

# Backup Density Analysis
if [ "$total_archives" -eq 0 ]; then
    echo -e "   ⚠️  ${RED}ALERT:${NC} No backups detected! Disaster recovery is currently impossible."
elif [ "$total_archives" -lt 5 ]; then
    echo -e "   ℹ️  ADVICE: Low backup density. Ensure CRON jobs are active."
else
    echo -e "   ✅ BACKUPS: Data integrity cycle is functional."
fi

echo -e "\n${GREEN}✅ INFRASTRUCTURE AUDIT COMPLETE${NC}"