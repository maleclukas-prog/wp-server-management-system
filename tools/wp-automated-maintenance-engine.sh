#!/bin/bash
source $HOME/scripts/wsms-config.sh

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    
    echo "🔄 Updating $name..."
    
    # 🔥 NOWE: Automatyczny snapshot przed update
    bash "$SCRIPT_DIR/wp-rollback.sh" snapshot "$name" > /dev/null 2>&1
    
    # Wykonaj update
    sudo -u "$user" wp --path="$path" core update --quiet 2>/dev/null
    sudo -u "$user" wp --path="$path" plugin update --all --quiet 2>/dev/null
    
    # 🔥 NOWE: Sprawdź czy strona działa
    if curl -s -o /dev/null -w "%{http_code}" "https://$name" | grep -q "200"; then
        echo "   ✅ $name updated successfully"
    else
        echo "   ⚠️ $name may have issues - rolling back..."
        bash "$SCRIPT_DIR/wp-rollback.sh" rollback "$name"
    fi
done