#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - FLEET-WIDE MAINTENANCE ENGINE
# =================================================================

source "$HOME/scripts/wsms-config.sh"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

LOG_FILE="$LOG_UPDATES"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "🔄 MAINTENANCE ENGINE v4.2 - $(date)"
echo "=========================================================="

success_count=0
fail_count=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "\n🔄 Processing: $name"
    
    if [ -f "$path/wp-config.php" ]; then
        # Create rollback snapshot before update
        echo "   📸 Creating pre-update snapshot..."
        bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" 2>/dev/null
        
        # Perform updates
        echo "   ⚙️ Updating core..."
        sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
        
        echo "   ⚙️ Updating plugins..."
        sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Updating themes..."
        sudo -u "$user" wp --path="$path" theme update --all --quiet 2>/dev/null
        
        echo "   ⚙️ Updating database..."
        sudo -u "$user" wp --path="$path" core update-db --quiet 2>/dev/null
        
        echo "   ⚙️ Flushing cache..."
        sudo -u "$user" wp --path="$path" cache flush --quiet 2>/dev/null
        
        # Verify site is still working
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$name" 2>/dev/null || echo "000")
        if [ "$http_code" = "000" ]; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$name" 2>/dev/null || echo "000")
        fi
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            echo -e "   ${GREEN}✅ $name updated successfully (HTTP $http_code)${NC}"
            ((success_count++))
        else
            echo -e "   ${RED}❌ $name may have issues (HTTP $http_code) - rolling back...${NC}"
            bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name" 2>/dev/null
            ((fail_count++))
        fi
    else
        echo -e "   ${RED}❌ Failed: Config missing at $path${NC}"
        ((fail_count++))
    fi
done

echo -e "\n${CYAN}📊 MAINTENANCE SUMMARY:${NC}"
echo "   ✅ Successful: $success_count site(s)"
echo "   ❌ Failed: $fail_count site(s)"
echo "   ⏰ Completed: $(date)"
echo -e "${GREEN}✅ MAINTENANCE CYCLE COMPLETE${NC}"