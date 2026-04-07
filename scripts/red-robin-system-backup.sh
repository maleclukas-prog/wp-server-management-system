#!/bin/bash
source ~/scripts/wsms-config.sh
echo "🔴 RED ROBIN - System backup"
BACKUP_NAME="red-robin-$(hostname)-$(date +%Y%m%d-%H%M%S).tar.gz"
sudo tar -czf "/tmp/$BACKUP_NAME" --exclude="$HOME/backups-*" --exclude="*/wp-content/uploads" / 2>/dev/null
echo "System backup created: /tmp/$BACKUP_NAME"
