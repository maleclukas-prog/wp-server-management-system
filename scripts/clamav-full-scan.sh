#!/bin/bash
TIMESTAMP=$(date +%Y%m%d)
LOG_FILE="/var/log/clamav/full_audit_$TIMESTAMP.log"
sudo mkdir -p /var/quarantine
echo "=== Full System Scan - $(date) ===" | sudo tee -a $LOG_FILE
sudo clamscan -r --infected --move=/var/quarantine --exclude-dir="^/sys" --exclude-dir="^/proc" / 2>&1 | sudo tee -a $LOG_FILE
echo "=== Scan Completed ===" | sudo tee -a $LOG_FILE
