#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
LOG_FILE="/var/log/clamav/auto_scan.log"
sudo mkdir -p /var/log/clamav
echo "=== ClamAV Scan - $(date) ===" | sudo tee -a $LOG_FILE
sudo clamscan -r --infected --no-summary /home /var/www | sudo tee -a $LOG_FILE
echo "=== Scan Completed ===" | sudo tee -a $LOG_FILE
