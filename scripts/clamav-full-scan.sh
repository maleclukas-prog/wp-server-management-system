#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - CLAMAV FULL SCAN
# =================================================================

source "$HOME/scripts/wsms-config.sh"
TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_CLAMAV_FULL"

echo "--- Deep System Audit: $(date) ---" | sudo tee "$LOG_FILE"
sudo clamscan -r --infected --move="$QUARANTINE_DIR" \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    / 2>&1 | sudo tee -a "$LOG_FILE"

echo -e "\n--- Scan Complete: $(date) ---" | sudo tee -a "$LOG_FILE"

infected_count=$(grep -c "FOUND" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Infected files found: $infected_count" | sudo tee -a "$LOG_FILE"

if [ "$infected_count" -gt 0 ]; then
    echo "⚠️ Infected files moved to: $QUARANTINE_DIR" | sudo tee -a "$LOG_FILE"
fi