#!/bin/bash
# =================================================================
# ⏰ WSMS AUTOMATION SCHEDULER
# Description: Configures the system crontab for fully automated 
#              maintenance, security, and recovery cycles.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

echo "⏰ Initializing Automation Scheduler..."

# Path Configuration
SCRIPTS_DIR="$HOME/scripts"
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"

# Logic: Export current crontab to a temporary file
crontab -l > /tmp/current_cron 2>/dev/null || touch /tmp/current_cron

# Logic: Clean existing WSMS entries to prevent duplicates
sed -i '/WSMS/d' /tmp/current_cron
sed -i '/scripts/d' /tmp/current_cron

# Logic: Inject new production-ready schedule
cat >> /tmp/current_cron << EOF
# --- WSMS AUTOMATION SCHEDULE ---

# 01:00 - Update Antivirus Definitions (ClamAV freshclam)
0 1 * * * sudo freshclam >> $LOG_DIR/clamav-update.log 2>&1 # WSMS

# 02:00 - Daily Off-site Hybrid Cloud Sync (Synology NAS)
0 2 * * * $SCRIPTS_DIR/nas-sftp-sync.sh >> $LOG_DIR/nas-sync.log 2>&1 # WSMS

# 03:00 - Daily Security Audit (Malware Auto-scan)
0 3 * * * $SCRIPTS_DIR/clamav-auto-scan.sh >> $LOG_DIR/security-scan.log 2>&1 # WSMS

# 04:00 - Daily Smart Retention Engine (Cleanup expired backups)
0 4 * * * $SCRIPTS_DIR/wp-smart-retention-manager.sh apply >> $LOG_DIR/retention.log 2>&1 # WSMS

# 06:00 - Sunday Automated Maintenance (Fleet-wide Updates)
0 6 * * 0 $SCRIPTS_DIR/wp-automated-maintenance-engine.sh >> $LOG_DIR/updates.log 2>&1 # WSMS

# 02:00 - Sunday & Wednesday: Essential Assets Backup (Lite)
0 2 * * 0,3 $SCRIPTS_DIR/wp-essential-assets-backup.sh >> $LOG_DIR/backup-lite.log 2>&1 # WSMS

# 03:00 - 1st of Month: Full System Snapshot (Recovery)
0 3 1 * * $SCRIPTS_DIR/wp-full-recovery-backup.sh >> $LOG_DIR/backup-full.log 2>&1 # WSMS
# --------------------------------
EOF

# Logic: Install the new crontab
crontab /tmp/current_cron
rm /tmp/current_cron

echo "✅ Crontab successfully scheduled."
echo "📋 Use 'crontab -l' to verify the schedule."