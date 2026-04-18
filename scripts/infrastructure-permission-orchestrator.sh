#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🛡️ INFRASTRUCTURE SECURITY ENFORCEMENT
# Description: Hardens isolation between tenants and grants secure 
#              access to the backup operator using ACLs.
# =================================================================
source $HOME/scripts/wsms-config.sh

echo -e "🔐 ${BLUE}LOCKING DOWN INFRASTRUCTURE...${NC}"

# Stop services for consistency
sudo systemctl stop nginx

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "🔧 Enforcing isolation for: $name (User: $user)"

    if [ -d "$path" ]; then
        # Ownership isolation
        sudo chown -R "$user":"$user" "$path"
        
        # Standard hardening
        sudo find "$path" -type d -exec chmod 755 {} \;
        sudo find "$path" -type f -exec chmod 644 {} \;
        
        # Secure wp-config.php
        [ -f "$path/wp-config.php" ] && sudo chmod 640 "$path/wp-config.php"

        # Backup operator access (ACL)
        if command -v setfacl &>/dev/null; then
            sudo setfacl -R -m u:ubuntu:r-x "$path"
        fi
    fi
done

sudo systemctl start nginx
echo -e "✅ ${GREEN}SECURITY POLICIES APPLIED SUCCESSFULLY.${NC}"