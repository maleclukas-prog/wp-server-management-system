#!/bin/bash
# =================================================================
# 🧠 WSMS GLOBAL CONFIGURATION - EXAMPLE FILE
# Copy this file to wsms-config.sh and edit with your values
# =================================================================

# ============================================
# MULTI-TENANT WORDPRESS SITES
# Format: "site-name:/full/path/to/public_html:system_user"
# ============================================
SITES=(
    "example-site:/var/www/example-site/public_html:example_user"
    "another-site:/var/www/another-site/public_html:another_user"
)

# ============================================
# SYNOLOGY NAS CONFIGURATION (SFTP)
# ============================================
NAS_HOST="your-nas.synology.me"           # Your NAS hostname or IP
NAS_PORT="22"                              # SSH/SFTP port (usually 22)
NAS_USER="your_username"                   # Your NAS username
NAS_PATH="/homes/your_username/server_backups"  # Remote backup path
NAS_SSH_KEY="$HOME/.ssh/nas_key"           # Path to your SSH private key

# ============================================
# BACKUP RETENTION (Days)
# ============================================
RETENTION_LITE=14          # Lite backups: 14 days
RETENTION_FULL=35          # Full backups: 35 days
RETENTION_MYSQL=7          # MySQL backups: 7 days
RETENTION_ROLLBACK=30      # Rollback snapshots: 30 days
NAS_RETENTION_DAYS=120     # NAS remote retention: 120 days
NAS_MIN_KEEP_COPIES=2      # Minimum copies on NAS (safety rule)

# ============================================
# SYSTEM THRESHOLDS
# ============================================
DISK_ALERT_THRESHOLD=80    # Alert when disk usage > 80%

# ============================================
# PATH CONFIGURATION (usually no changes needed)
# ============================================
SCRIPT_DIR="$HOME/scripts"
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MANUAL_DIR="$HOME/backups-manual"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="$HOME/backups-rollback"
LOG_DIR="$HOME/logs"
QUARANTINE_DIR="/var/quarantine"
CLAMAV_LOG_DIR="/var/log/clamav"

# ============================================
# NAS LOG FILES
# ============================================
LOG_NAS_SYNC="$LOG_DIR/nas_sync.log"
LOG_NAS_ERRORS="$LOG_DIR/nas_errors.log"

# ============================================
# EXPORT ALL VARIABLES
# ============================================
export SITES NAS_HOST NAS_PORT NAS_USER NAS_PATH NAS_SSH_KEY
export RETENTION_LITE RETENTION_FULL RETENTION_MYSQL RETENTION_ROLLBACK
export NAS_RETENTION_DAYS NAS_MIN_KEEP_COPIES DISK_ALERT_THRESHOLD
export SCRIPT_DIR BACKUP_LITE_DIR BACKUP_FULL_DIR BACKUP_MANUAL_DIR BACKUP_MYSQL_DIR BACKUP_ROLLBACK_DIR
export QUARANTINE_DIR CLAMAV_LOG_DIR LOG_DIR LOG_NAS_SYNC LOG_NAS_ERRORS