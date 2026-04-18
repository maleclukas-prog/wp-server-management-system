#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
source ~/scripts/wsms-config.sh
echo "🧪 WP-CLI VALIDATOR"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    if sudo -u "$user" wp --path="$path" core version &>/dev/null; then
        echo " ✅ $name: $(sudo -u "$user" wp --path="$path" core version)"
    else
        echo " ❌ $name: Connection failed"
    fi
done
