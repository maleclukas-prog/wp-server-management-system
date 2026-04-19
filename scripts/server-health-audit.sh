#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - ENHANCED EXECUTIVE DIAGNOSTICS
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${BLUE}🖥️  WSMS EXECUTIVE DIAGNOSTICS v4.2${NC}"
echo "=========================================================="
echo -e "⏰ Timestamp: $(date)"
echo -e "💻 Host: $(hostname) | OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Ubuntu')"
echo "----------------------------------------------------------"

# ============================================
# SYSTEM LOAD
# ============================================
echo -e "\n${CYAN}📈 SYSTEM LOAD & RESOURCES:${NC}"
echo "   CPU Cores:    $(nproc)"
echo "   Uptime:       $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo -ne "   Memory:       " && free -h | awk '/^Mem:/ {print $3 "/" $2 " used (" $7 " available)"}'

# ============================================
# STORAGE
# ============================================
echo -e "\n${CYAN}💾 STORAGE AUDIT:${NC}"
df -h / /var/www /home 2>/dev/null | grep -v "tmpfs" | sed 's/^/   /'

# ============================================
# NETWORK
# ============================================
echo -e "\n${CYAN}🌐 NETWORK EXPOSURE:${NC}"
echo "   Primary IP: $(hostname -I | awk '{print $1}')"
echo "   Listening Services:"
ss -tulpn 2>/dev/null | grep -E ":(80|443|22|3306)" | head -5 | sed 's/^/   /'

# ============================================
# CORE SERVICES STATUS
# ============================================
echo -e "\n${CYAN}🛠️  CORE SERVICES STATUS:${NC}"

# Check Nginx
if systemctl is-active --quiet nginx; then
    echo -e "   ${GREEN}✅ Nginx: Active${NC}"
elif systemctl list-unit-files | grep -q nginx; then
    echo -e "   ${RED}❌ Nginx: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Nginx: Not installed${NC}"
fi

# Check Apache
if systemctl is-active --quiet apache2; then
    echo -e "   ${GREEN}✅ Apache2: Active${NC}"
elif systemctl list-unit-files | grep -q apache2; then
    echo -e "   ${RED}❌ Apache2: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Apache2: Not installed${NC}"
fi

# Check MySQL/MariaDB
if systemctl is-active --quiet mysql; then
    echo -e "   ${GREEN}✅ MySQL: Active${NC}"
elif systemctl is-active --quiet mariadb; then
    echo -e "   ${GREEN}✅ MariaDB: Active${NC}"
elif systemctl list-unit-files | grep -qE "mysql|mariadb"; then
    echo -e "   ${RED}❌ Database: Installed but STOPPED${NC}"
else
    echo -e "   ${YELLOW}⚠️ Database: Not installed${NC}"
fi

# Check SSH
if systemctl is-active --quiet ssh; then
    echo -e "   ${GREEN}✅ SSH: Active${NC}"
else
    echo -e "   ${RED}❌ SSH: Stopped${NC}"
fi

# ============================================
# PHP-FPM STATUS
# ============================================
echo -e "\n${CYAN}🔌 PHP-FPM STATUS:${NC}"
PHP_VERSIONS=$(systemctl list-units --type=service --state=active --no-legend 2>/dev/null | grep -E 'php[0-9.]+-fpm.service' | awk '{print $1}' | sed 's/.service//')

if [ -n "$PHP_VERSIONS" ]; then
    echo -e "   ${GREEN}✅ Active PHP-FPM pools:${NC}"
    for php in $PHP_VERSIONS; do
        echo "      📦 $php"
    done
    echo "   🔌 Active Sockets:"
    sudo ls -la /run/php/ 2>/dev/null | grep -E "\.sock$" | head -5 | sed 's/^/      /'
else
    echo -e "   ${RED}❌ No active PHP-FPM pools detected${NC}"
fi

# ============================================
# PHP-FPM USERS
# ============================================
echo -e "\n${CYAN}👥 PHP-FPM USERS:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if id "$user" &>/dev/null; then
        echo -e "   ${GREEN}✅${NC} $name: $user"
    else
        echo -e "   ${RED}❌${NC} $name: $user (missing)"
    fi
done

# ============================================
# DOMAIN REACHABILITY
# ============================================
echo -e "\n${CYAN}🔗 DOMAIN REACHABILITY:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "   ${GREEN}✅${NC} $name (HTTP $http_code)"
    else
        echo -e "   ${RED}❌${NC} $name (HTTP $http_code - unreachable)"
    fi
done

# ============================================
# MANAGED WORDPRESS SITES
# ============================================
echo -e "\n${CYAN}🌐 MANAGED WORDPRESS SITES:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "   ${YELLOW}[ $name ]${NC}"
    if [ -f "$path/wp-config.php" ]; then
        wp_ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        site_php=$(sudo -u "$user" wp --path="$path" eval "echo PHP_VERSION;" 2>/dev/null || echo "unknown")
        db_name=$(sudo -u "$user" wp --path="$path" db query "SELECT DATABASE()" --skip-column-names 2>/dev/null || echo "unknown")
        plugins_updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        themes_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        
        echo "      Core: v$wp_ver | PHP: $site_php"
        echo "      DB: $db_name"
        
        total_updates=$((plugins_updates + themes_updates))
        if [ "$total_updates" -gt 0 ]; then
            echo -e "      Updates: ${YELLOW}$total_updates pending${NC} (Plugins: $plugins_updates, Themes: $themes_updates)"
        else
            echo -e "      Updates: ${GREEN}All patched${NC}"
        fi
    else 
        echo -e "      ${RED}CRITICAL: Config missing${NC}"
    fi
done

# ============================================
# BACKUP REPOSITORY STATUS
# ============================================
echo -e "\n${CYAN}💾 BACKUP REPOSITORY STATUS:${NC}"
total_archives=0

for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR" "$BACKUP_ROLLBACK_DIR"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "   📂 $(basename "$dir"): $count files ($size)"
        total_archives=$((total_archives + count))
    fi
done

# ============================================
# ROLLBACK SNAPSHOTS
# ============================================
echo -e "\n${CYAN}📸 ROLLBACK SNAPSHOTS AVAILABLE:${NC}"
snapshot_total=0
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count snapshots (Latest: $latest)"
        snapshot_total=$((snapshot_total + snapshot_count))
    fi
done
if [ "$snapshot_total" -eq 0 ]; then
    echo "   No rollback snapshots found"
fi

# ============================================
# RECOMMENDATIONS
# ============================================
echo -e "\n${YELLOW}🔔 OPERATIONAL RECOMMENDATIONS:${NC}"
echo "----------------------------------------------------------"

# Check Nginx/Apache
if ! systemctl is-active --quiet nginx && ! systemctl is-active --quiet apache2; then
    echo -e "   ${RED}⚠️ CRITICAL: No web server running! Run: sudo systemctl start nginx${NC}"
fi

# Check disk space
disk_usage=$(df /home 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$disk_usage" ] && [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
    echo -e "   ⚠️  ${RED}CRITICAL: Disk usage at ${disk_usage}% - run backup-emergency!${NC}"
fi

# Check backups
if [ "$total_archives" -eq 0 ]; then
    echo -e "   ⚠️  ${RED}ALERT: No backups found! Run wp-backup-full${NC}"
fi

# Check rollback snapshots
if [ "$snapshot_total" -eq 0 ]; then
    echo -e "   ℹ️  ADVICE: No rollback snapshots. Run 'wp-snapshot all' before updates${NC}"
fi

echo -e "\n${GREEN}✅ INFRASTRUCTURE AUDIT COMPLETE${NC}"