#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MULTI-INSTANCE DEEP AUDIT
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}🔍 INITIATING MULTI-SITE DEEP AUDIT v4.2${NC}"
echo "=========================================================="

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n${YELLOW}--- Audit for: $name ---${NC}"
    
    if [ -f "$path/wp-config.php" ]; then
        # Database check
        echo -e "\n${CYAN}📊 Database Status:${NC}"
        sudo -u "$user" wp --path="$path" db check 2>/dev/null && echo "   ✅ Database OK" || echo "   ⚠️ Database check failed"
        
        # Plugin updates
        echo -e "\n${CYAN}📦 Plugins with Updates:${NC}"
        updates=$(sudo -u "$user" wp --path="$path" plugin list --update=available --format=table 2>/dev/null)
        if [ -n "$updates" ]; then
            echo "$updates"
        else
            echo "   ${GREEN}✅ All plugins up to date${NC}"
        fi
        
        # Theme updates
        echo -e "\n${CYAN}🎨 Themes with Updates:${NC}"
        theme_updates=$(sudo -u "$user" wp --path="$path" theme list --update=available --format=table 2>/dev/null)
        if [ -n "$theme_updates" ]; then
            echo "$theme_updates"
        else
            echo "   ${GREEN}✅ All themes up to date${NC}"
        fi
        
        # Security check - file permissions
        echo -e "\n${CYAN}🔒 Security Quick Check:${NC}"
        wp_config_perms=$(stat -c "%a" "$path/wp-config.php" 2>/dev/null)
        if [ "$wp_config_perms" = "640" ] || [ "$wp_config_perms" = "600" ]; then
            echo "   ${GREEN}✅ wp-config.php permissions: $wp_config_perms${NC}"
        else
            echo "   ${RED}⚠️ wp-config.php permissions: $wp_config_perms (should be 640)${NC}"
        fi
        
        # Debug mode check
        if grep -q "WP_DEBUG.*true" "$path/wp-config.php" 2>/dev/null; then
            echo "   ${RED}⚠️ WP_DEBUG is enabled (security risk)${NC}"
        else
            echo "   ${GREEN}✅ WP_DEBUG is disabled${NC}"
        fi
        
    else
        echo -e "   ${RED}❌ Configuration missing at $path${NC}"
    fi
done

echo -e "\n${GREEN}✅ DEEP AUDIT COMPLETE${NC}"