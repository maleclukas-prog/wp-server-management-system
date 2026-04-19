#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - STANDALONE MYSQL BACKUP ENGINE
# =================================================================

source "$HOME/scripts/wsms-config.sh"
echo "⚙️ Standalone MySQL Engine: Executing global dump v4.2"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"