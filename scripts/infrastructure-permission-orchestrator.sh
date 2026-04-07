#!/bin/bash
# =================================================================
# 🛡️ PERMISSION ORCHESTRATOR - DYNAMIC VERSION
# =================================================================
source ~/scripts/wsms-config.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🛡️  SECURITY & PERMISSION AUDIT${NC}"
echo "=========================================================="

# Stop web services
sudo systemctl stop nginx 2>/dev/null || true
for service in $(systemctl list-units --type=service --all --no-legend | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$'); do
    sudo systemctl stop "$service" 2>/dev/null || true
done

# Fix permissions for each site
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🌐 Securing: $name (User: $user)"
    
    if [ -d "$path" ]; then
        sudo chown -R "$user":"$user" "$path/"
        sudo find "$path/" -type d -exec chmod 755 {} \;
        sudo find "$path/" -type f -exec chmod 644 {} \;
        [ -d "$path/wp-content" ] && sudo chmod -R 775 "$path/wp-content/"
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php"
        echo -e "   ✅ ${GREEN}Permissions aligned${NC}"
    fi
done

# Fix backup directories
for dir in "$BACKUP_LITE_DIR" "$BACKUP_FULL_DIR" "$BACKUP_MYSQL_DIR"; do
    [ -d "$dir" ] && sudo chown -R "$USER":"$USER" "$dir" && sudo chmod 755 "$dir"
done

# Restart services
for service in $(systemctl list-units --type=service --all --no-legend | awk '{print $1}' | grep -E '^php[0-9.]+-fpm.service$'); do
    sudo systemctl start "$service" 2>/dev/null || true
done
sudo systemctl start nginx 2>/dev/null || true

echo -e "\n${GREEN}✅ SECURITY AUDIT COMPLETED${NC}"
