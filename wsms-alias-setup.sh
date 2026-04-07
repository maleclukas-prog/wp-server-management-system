#!/bin/bash
# =================================================================
# 🐚 WSMS ALIAS ORCHESTRATOR
# Description: Automatically configures the shell environment by 
#              injecting professional aliases into .bashrc.
# Author: [Your Name]
# =================================================================

RC_FILE="$HOME/.bashrc"
SCRIPTS_DIR="$HOME/scripts"

echo "🐚 Initiating Shell Environment Setup..."

# Logic: Avoid duplicate entries by checking for a unique WSMS marker
if grep -q "WORDPRESS MANAGEMENT SYSTEM - ALIASES" "$RC_FILE"; then
    echo "⚠️  WSMS Aliases already exist in $RC_FILE. Skipping injection."
else
    echo "📝 Injecting production-grade aliases into $RC_FILE..."
    cat >> "$RC_FILE" << EOF

# ============================================
# WORDPRESS MANAGEMENT SYSTEM - ALIASES
# ============================================
export SCRIPTS_DIR="$SCRIPTS_DIR"

# Diagnostics & Observability
alias system-diag="bash \$SCRIPTS_DIR/server-health-audit.sh"
alias wp-fleet="bash \$SCRIPTS_DIR/wp-fleet-status-monitor.sh"
alias wp-audit="bash \$SCRIPTS_DIR/wp-multi-instance-audit.sh"
alias scripts-dir="ls -la \$SCRIPTS_DIR/"

# Maintenance & Security
alias wp-update-all="bash \$SCRIPTS_DIR/wp-automated-maintenance-engine.sh"
alias wp-update-safe="wp-backup-lite && sleep 5 && wp-update-all"
alias wp-fix-perms="bash \$SCRIPTS_DIR/infrastructure-permission-orchestrator.sh"

# Backup & Disaster Recovery
alias wp-backup-lite="bash \$SCRIPTS_DIR/wp-essential-assets-backup.sh"
alias wp-backup-full="bash \$SCRIPTS_DIR/wp-full-recovery-backup.sh"
alias wp-backup-ui="bash \$SCRIPTS_DIR/wp-interactive-backup-tool.sh"
alias red-robin="bash \$SCRIPTS_DIR/red-robin-system-backup.sh"

# MySQL Operations
alias db-backup="bash \$SCRIPTS_DIR/mysql-backup-manager.sh"
alias db-backup-all="db-backup all"
alias db-backup-list="db-backup list"

# Retention & Disk Management
alias backup-clean="bash \$SCRIPTS_DIR/wp-smart-retention-manager.sh apply"
alias backup-size="bash \$SCRIPTS_DIR/wp-smart-retention-manager.sh list"

# Hybrid Cloud Sync (NAS)
alias nas-sync="bash \$SCRIPTS_DIR/nas-sftp-sync.sh"
alias nas-sync-logs="tail -f ~/logs/nas_sync.log"

# Antivirus Management (ClamAV)
alias clamav-scan="bash \$SCRIPTS_DIR/clamav-auto-scan.sh"
alias clamav-deep-scan="bash \$SCRIPTS_DIR/clamav-full-scan.sh"
alias clamav-status="sudo systemctl status clamav-daemon"

# System Help
alias wp-help="bash \$SCRIPTS_DIR/wp-help.sh"
alias wp-status="system-diag && wp-fleet"
# ============================================
EOF
    echo "✅ Aliases successfully injected."
fi

echo "🚀 Environment updated. Please run: source ~/.bashrc"