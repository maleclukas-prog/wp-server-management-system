#!/bin/bash
source ~/scripts/wsms-config.sh
echo "Standalone MySQL backup - use 'mysql-backup-manager.sh' instead"
bash "$SCRIPT_DIR/mysql-backup-manager.sh" "all"
