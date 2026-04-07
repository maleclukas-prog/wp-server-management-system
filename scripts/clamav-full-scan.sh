#!/bin/bash

# =================================================================
# 🛡️ ClamAV Full System Deep Audit
# Description: Performs a comprehensive root filesystem scan and 
#              automatically moves infected files to quarantine.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

# Configuration
TIMESTAMP=$(date +%Y%m%d)
LOG_FILE="/var/log/clamav/full_audit_$TIMESTAMP.log"
QUARANTINE_DIR="/var/quarantine"

# Ensure quarantine directory exists
sudo mkdir -p $QUARANTINE_DIR

echo "=== Full System Security Audit Started - $(date) ===" | sudo tee -a $LOG_FILE
echo "Target Path: / (Root Filesystem)" | sudo tee -a $LOG_FILE
echo "Quarantine Location: $QUARANTINE_DIR" | sudo tee -a $LOG_FILE
echo "---------------------------------------------------" | sudo tee -a $LOG_FILE

# Execute deep scan
# --recursive: Scan all subdirectories
# --infected: Only output infected files
# --move: Automatically isolate threats to quarantine
# --exclude-dir: Skip virtual filesystems to prevent errors/hangs
sudo clamscan -r \
    --infected \
    --move=$QUARANTINE_DIR \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    / 2>&1 | sudo tee -a $LOG_FILE

echo "" | sudo tee -a $LOG_FILE
echo "---------------------------------------------------" | sudo tee -a $LOG_FILE
INFECTED_COUNT=$(sudo grep -c "FOUND" $LOG_FILE 2>/dev/null || echo "0")
echo "=== Audit Completed - $(date) ===" | sudo tee -a $LOG_FILE
echo "Total Threats Detected & Isolated: $INFECTED_COUNT" | sudo tee -a $LOG_FILE

# Console Output for Operator
if [ "$INFECTED_COUNT" -gt 0 ]; then
    echo "⚠️  CRITICAL: $INFECTED_COUNT security threats were detected and moved to quarantine!"
    echo "Please inspect the logs: $LOG_FILE"
    echo "Quarantine directory: $QUARANTINE_DIR"
else
    echo "✅ SYSTEM CLEAN: Full audit completed. No malware detected."
fi