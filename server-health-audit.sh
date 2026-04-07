#!/bin/bash
# =================================================================
# 🖥️  SERVER INFRASTRUCTURE HEALTH AUDIT & DIAGNOSTICS
# Description: A comprehensive diagnostic tool that monitors system 
#              resources, service uptime, PHP-FPM orchestration, 
#              and backup integrity with automated recommendations.
# Author: [Your Name]
# =================================================================

# UI Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🖥️  SYSTEM DIAGNOSTICS DASHBOARD${NC}"
echo "========================================"
echo "⏰ Audit Timestamp: $(date)"
echo ""

# --- 1. SYSTEM METRICS ---
echo -e "${BLUE}💻 HARDWARE & OS INFO:${NC}"
echo "   Host: $(hostname)"
echo "   Kernel: $(uname -r)"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   CPU: $(nproc) cores | Uptime: $(uptime -p)"
echo ""

echo -e "${BLUE}📈 PERFORMANCE & LOAD:${NC}"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
top -b -n 1 | head -5 | sed 's/^/   /'
echo ""

echo -e "${BLUE}🧠 MEMORY UTILIZATION:${NC}"
free -h | sed 's/^/   /'
echo ""

echo -e "${BLUE}💾 STORAGE STATUS:${NC}"
df -h / /var/www /home | grep -v "tmpfs" | sed 's/^/   /'
echo ""

# --- 2. NETWORK & SECURITY ---
echo -e "${BLUE}🌐 NETWORK EXPOSURE:${NC}"
echo "   Primary IP: $(hostname -I | awk '{print $1}')"
echo "   Listening Ports (Web/SSH/DB):"
ss -tulpn | grep -E ":(80|443|22|3306)" | head -10 | sed 's/^/   /'
echo ""

# --- 3. SERVICE ORCHESTRATION ---
echo -e "${BLUE}🛠️  CORE SERVICES STATUS:${NC}"
services=("nginx" "apache2" "mysql" "ssh")
for service in "${services[@]}"; do
    status=$(systemctl is-active "$service" 2>/dev/null || echo "not installed")
    if [ "$status" == "active" ]; then
        echo -e "   ✅ $service: ${GREEN}Active${NC}"
    else
        echo -e "   ❌ $service: ${RED}$status${NC}"
    fi
done
echo ""

# --- 4. ADVANCED PHP-FPM AUDIT ---
echo -e "${BLUE}🔌 PHP-FPM MULTI-VERSION STATUS:${NC}"
ACTIVE_PHP_SERVICES=$(systemctl list-units --type=service --state=active --no-legend | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$' | sed 's/.service//')

if [ -n "$ACTIVE_PHP_SERVICES" ]; then
    for service in $ACTIVE_PHP_SERVICES; do
        echo -e "   ✅ $service: ${GREEN}Running${NC}"
    done
    echo "   📍 Active Sockets:"
    sudo ls -1 /run/php/*.sock 2>/dev/null | sed 's/^/      - /'
else
    echo -e "   ❌ PHP-FPM: ${RED}No active pool detected${NC}"
fi
echo ""

# --- 5. APPLICATION LAYER (WORDPRESS) ---
echo -e "${BLUE}🌐 WORDPRESS INSTANCE HEALTH:${NC}"
# Site Map Configuration
declare -A site_map=(
    ["site1"]="/var/www/site1/public_html:php_user1"
    ["site2"]="/var/www/site2/public_html:php_user2"
)

for site in "${!site_map[@]}"; do
    IFS=':' read -r path user <<< "${site_map[$site]}"
    if [ -f "$path/wp-config.php" ]; then
        echo -ne "   ✅ $site: ${GREEN}Config Found${NC}"
        # Check if the associated PHP user exists for security isolation
        if id "$user" &> /dev/null; then
            echo -e " | User: ${GREEN}$user (Isolated)${NC}"
        else
            echo -e " | User: ${RED}$user (Missing!)${NC}"
        fi
    else
        echo -e "   ❌ $site: ${RED}Missing Config at $path${NC}"
    fi
done
echo ""

# --- 6. DATA INTEGRITY (BACKUPS) ---
echo -e "${BLUE}💾 BACKUP REPOSITORY AUDIT:${NC}"
backup_dirs=("$HOME/backups-lite" "$HOME/backups-full" "$HOME/mysql-backups")
total_files=0

for dir in "${backup_dirs[@]}"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count archives ($size)"
        total_files=$((total_files + count))
    else
        echo "   ⚠️  $(basename "$dir"): Directory missing"
    fi
done
echo -e "   📊 Summary: Total $total_files archives detected."
echo ""

# --- 7. SMART RECOMMENDATIONS (HEURISTICS) ---
echo -e "${YELLOW}🔔 OPERATIONAL RECOMMENDATIONS:${NC}"
echo "=========================="

# Disk Space Heuristic
free_gb=$(df /home | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$free_gb < 5" | bc -l) )); then
    echo -e "   ⚠️  ${RED}CRITICAL:${NC} Low disk space ($free_gb GB). Run 'backup-smart-clean' immediately."
elif (( $(echo "$free_gb < 10" | bc -l) )); then
    echo -e "   ℹ️  ADVICE: Disk space at $free_gb GB. Monitor storage growth."
else
    echo -e "   ✅ STORAGE: Disk health is optimal ($free_gb GB free)."
fi

# Backup Heuristic
if [ "$total_files" -eq 0 ]; then
    echo -e "   ⚠️  ${RED}ALERT:${NC} Zero backups found. Disaster recovery is at risk!"
elif [ "$total_files" -lt 5 ]; then
    echo -e "   ℹ️  ADVICE: Low backup density. Ensure crontab is active."
fi

echo ""
echo -e "${GREEN}✅ DIAGNOSTICS COMPLETE${NC}"