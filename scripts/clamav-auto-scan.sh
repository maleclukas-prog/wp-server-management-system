#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - CLAMAV AUTO SCAN
# =================================================================

source "$HOME/scripts/wsms-config.sh"
LOG_FILE="$LOG_CLAMAV_SCAN"

echo "--- Malware Scan: $(date) ---" | sudo tee -a "$LOG_FILE"
sudo clamscan -r --infected --no-summary /var/www /home 2>/dev/null | sudo tee -a "$LOG_FILE"
echo "--- Scan Complete ---" | sudo tee -a "$LOG_FILE"