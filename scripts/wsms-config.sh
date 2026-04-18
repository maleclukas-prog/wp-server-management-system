#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.1 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
# =================================================================
# 🧠 WSMS GLOBAL CONFIGURATION
# Generated on: Tue Apr  7 11:50:08 UTC 2026
# =================================================================

# Multi-Tenant Infrastructure Mapping
# Format: "identifier:filesystem_path:system_user"
SITES=(
    "uSite_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_site"
)

# Synology NAS Configuration
NAS_HOST="your_server_details.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/Your_id_rsa-key"

# Backup Retention (Days)
RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2

# System Thresholds
DISK_ALERT_THRESHOLD=80   # <-- POPRAWNIE! (było DISK_LIMIT)

# Paths
SCRIPT_DIR="$HOME/scripts"
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MANUAL_DIR="$HOME/backups-manual"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
LOG_DIR="$HOME/logs"

# Backup directories list (for cleanup)
BACKUP_DIRS=(
    "$BACKUP_LITE_DIR"
    "$BACKUP_FULL_DIR"
    "$BACKUP_MANUAL_DIR"
    "$BACKUP_MYSQL_DIR"
)

# Retention mapping for each directory
declare -A RETENTION_MAP=(
    ["$BACKUP_LITE_DIR"]=$RETENTION_LITE
    ["$BACKUP_FULL_DIR"]=$RETENTION_FULL
    ["$BACKUP_MANUAL_DIR"]=$RETENTION_LITE
    ["$BACKUP_MYSQL_DIR"]=$RETENTION_MYSQL
)

# Export for child scripts
export SITES
export NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES
export DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR LOG_DIR
export BACKUP_DIRS
export RETENTION_MAP