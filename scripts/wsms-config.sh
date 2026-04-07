#!/bin/bash
# =================================================================
# 🧠 WSMS GLOBAL CONFIGURATION - AUTO-GENERATED
# Generated on: Tue Apr  7 11:50:08 UTC 2026
# DO NOT EDIT MANUALLY - Changes will be overwritten by installer
# =================================================================

# Multi-Tenant Infrastructure Mapping
# Format: "identifier:filesystem_path:system_user"
SITES=(
    "Site_nick:/var/www/your_site/public_html:your_site"
    "Site_nick:/var/www/your_site/public_html:your_sitet"
    "Site_nick:/var/www/your_site/public_html:your_site"
)

# Synology NAS Configuration
NAS_HOST="your_server_details.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admi/server_backups"
NAS_SSH_KEY="$HOME/.ssh/Your_id_rsa_KEY"

# Backup Retention (Days)
RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
NAS_RETENTION_DAYS=120
NAS_MIN_KEEP_COPIES=2

# System Thresholds
DISK_ALERT_THRESHOLD=80

# Paths
SCRIPT_DIR="$HOME/scripts"
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MANUAL_DIR="$HOME/backups-manual"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
LOG_DIR="$HOME/logs"

# Export for child scripts
export SITES
export NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES
export DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR LOG_DIR
