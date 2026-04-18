#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
source ~/scripts/wsms-config.sh
echo "Standalone MySQL backup - use 'mysql-backup-manager.sh' instead"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
