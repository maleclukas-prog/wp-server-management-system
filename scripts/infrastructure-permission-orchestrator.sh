#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - INFRASTRUCTURE PERMISSION ORCHESTRATOR
# =================================================================

source "$HOME/scripts/wsms-config.sh"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

LOG_FILE="$LOG_PERMISSIONS"

# Function to log AND display
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log "=========================================================="
log "🔐 PERMISSION FIX - $(date)"
log "=========================================================="

# Stop web server temporarily
WEB_SERVER=""
if systemctl is-active --quiet nginx; then
    WEB_SERVER="nginx"
elif systemctl is-active --quiet apache2; then
    WEB_SERVER="apache2"
fi

if [ -n "$WEB_SERVER" ]; then
    log "⏸️  Stopping $WEB_SERVER..."
    sudo systemctl stop "$WEB_SERVER" 2>/dev/null || true
fi

fixed_count=0
error_count=0

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    log ""
    log "${YELLOW}Fixing permissions for $name (User: $user)${NC}"
    
    if [ -d "$path" ]; then
        # Ownership
        sudo chown -R "$user":"$user" "$path" 2>/dev/null
        
        # Directory permissions
        sudo find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        
        # File permissions
        sudo find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        
        # Secure wp-config.php
        if [ -f "$path/wp-config.php" ]; then
            sudo chmod 640 "$path/wp-config.php" 2>/dev/null
            log "   ✅ wp-config.php secured (640)"
        fi
        
        # Secure .htaccess
        if [ -f "$path/.htaccess" ]; then
            sudo chmod 644 "$path/.htaccess" 2>/dev/null
        fi
        
        # Set ACL for backup access if available
        if command -v setfacl &>/dev/null; then
            sudo setfacl -R -m "u:$USER:r-x" "$path" 2>/dev/null || true
            log "   ✅ ACL set for user $USER"
        fi
        
        log "   ${GREEN}✅ $name permissions fixed${NC}"
        ((fixed_count++))
    else
        log "   ${RED}❌ Directory $path not found${NC}"
        ((error_count++))
    fi
done

# Restart web server
if [ -n "$WEB_SERVER" ]; then
    log ""
    log "▶️  Starting $WEB_SERVER..."
    sudo systemctl start "$WEB_SERVER" 2>/dev/null || true
fi

log ""
log "${GREEN}==========================================================${NC}"
log "${GREEN}✅ PERMISSIONS FIXED: $fixed_count site(s)${NC}"
if [ $error_count -gt 0 ]; then
    log "${RED}❌ ERRORS: $error_count site(s)${NC}"
fi
log "${GREEN}==========================================================${NC}"