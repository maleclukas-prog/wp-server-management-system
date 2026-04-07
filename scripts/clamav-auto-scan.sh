#!/bin/bash

# =================================================================
# 🦠 ClamAV Automated Malware Scanner
# Description: Performs daily recursive scanning of high-risk 
#              directories (/home and /var/www).
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# Configuration
LOG_FILE="/var/log/clamav/auto_scan.log"
SCAN_DIRS="/home /var/www" # Add your custom paths here if needed
QUARANTINE_DIR="/var/quarantine"

# Ensure log and quarantine directories exist
sudo mkdir -p /var/log/clamav
sudo mkdir -p $QUARANTINE_DIR

# Start scanning process
echo "=== ClamAV Auto Scan Started - $(date) ===" | sudo tee -a $LOG_FILE
echo "Target Directories: $SCAN_DIRS" | sudo tee -a $LOG_FILE
echo "---------------------------------------------------" | sudo tee -a $LOG_FILE

# Execute clamscan
# --infected: Only print infected files
# --no-summary: Keep log output clean
# --recursive: Scan subdirectories
sudo clamscan -r --infected --no-summary $SCAN_DIRS | sudo tee -a $LOG_FILE

echo "" | sudo tee -a $LOG_FILE
echo "=== Scan Completed - $(date) ===" | sudo tee -a $LOG_FILE

# Summary and Alerting Logic
INFECTED_COUNT=$(sudo grep -c "FOUND" $LOG_FILE 2>/dev/null || echo "0")
echo "Security Summary: $INFECTED_COUNT threats found."

if [ "$INFECTED_COUNT" -gt 0 ]; then
    echo "⚠️  SECURITY ALERT: $INFECTED_COUNT INFECTIONS DETECTED!"
    echo "Review detailed logs at: $LOG_FILE"
    echo "Infected files might require manual quarantine or removal."
else
    echo "✅ CLEAN: Scanning finished - no threats detected."
fi