#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - WORDPRESS FLEET STATUS MONITOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}📊 WORDPRESS FLEET STATUS v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    if [ -f "$path/wp-config.php" ]; then
        ver=$(sudo -u "$user" wp --path="$path" core version 2>/dev/null || echo "unknown")
        updates_plugins=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=count 2>/dev/null || echo "0")
        updates_themes=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=count 2>/dev/null || echo "0")
        total_updates=$((updates_plugins + updates_themes))
        
        # Sprawdzanie HTTP/HTTPS z ignorowaniem SSL i follow redirects
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -k -L "http://$name" 2>/dev/null || echo "000")
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ] || [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
            status_icon="${GREEN}✅${NC}"
        else
            status_icon="${RED}❌ (HTTP $http_code)${NC}"
        fi
        
        echo -e "   $status_icon $name: Core v$ver | ${YELLOW}Updates: $total_updates${NC} (Plugins: $updates_plugins, Themes: $updates_themes)"
    else
        echo -e "   ${RED}❌ $name: Environment Error at $path${NC}"
    fi
done

echo ""
echo -e "${CYAN}📸 ROLLBACK SNAPSHOTS AVAILABLE:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    snapshot_count=$(find "$BACKUP_ROLLBACK_DIR/$name" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    if [ "$snapshot_count" -gt 0 ]; then
        latest=$(ls -t "$BACKUP_ROLLBACK_DIR/$name" 2>/dev/null | head -1)
        echo "   📁 $name: $snapshot_count snapshots (Latest: $latest)"
    fi
done