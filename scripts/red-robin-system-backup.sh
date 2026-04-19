#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - RED ROBIN SYSTEM BACKUP
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_MANUAL_DIR/red-robin-sys-$TS.tar.gz"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo "🔴 EMERGENCY SYSTEM STATE CAPTURE STARTING v4.2..."
echo "=========================================================="

sudo tar -cpzf "$OUT" \
    --exclude="/proc" \
    --exclude="/sys" \
    --exclude="/dev" \
    --exclude="/tmp" \
    --exclude="/run" \
    --exclude="/mnt" \
    --exclude="/media" \
    --exclude="$HOME/backups-"* \
    /etc /var/log /home 2>/dev/null

if [ -f "$OUT" ]; then
    size=$(du -h "$OUT" | cut -f1)
    echo -e "✅ ${GREEN}System configuration captured: $OUT ($size)${NC}"
else
    echo -e "❌ ${RED}Failed to create system backup${NC}"
fi