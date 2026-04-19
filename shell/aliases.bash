# ============================================
# WSMS PRO v4.2 - BASH SHELL ALIASES
# Complete Bash Shell Configuration
# Version: 4.2 | Last Updated: April 2026
# ============================================

export SCRIPTS_DIR="$HOME/scripts"

# ============================================
# EXECUTIVE & HELP
# ============================================
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'

# ============================================
# DIAGNOSTICS & OBSERVABILITY
# ============================================
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-list='wp-fleet'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-diagnoza='wp-audit'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-test-cli='wp-cli-validator'
alias scripts-dir='ls -la $SCRIPTS_DIR/'

# ============================================
# MAINTENANCE & SECURITY
# ============================================
alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update='wp-update-all'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias wp-fix-permissions='wp-fix-perms'

# ============================================
# BACKUPS & RECOVERY
# ============================================
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias wp-backup-site='wp-backup-ui'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

# ============================================
# ROLLBACK SYSTEM (NEW in v4.2)
# ============================================
alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias wp-rollback-clean='bash $SCRIPTS_DIR/wp-rollback.sh clean'

# ============================================
# BACKUP MANAGEMENT
# ============================================
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-clean-emergency='backup-emergency'
alias backup-dirs='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh dirs'
alias backup-smart-clean='backup-clean'

# ============================================
# DATABASE MANAGEMENT
# ============================================
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'

# ============================================
# HYBRID CLOUD SYNC (NAS)
# ============================================
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias nas-sync-status='echo "📊 Last NAS sync:"; tail -10 $HOME/logs/wsms/sync/nas-sync.log 2>/dev/null || echo "No logs yet"'
alias nas-sync-errors='tail -f $HOME/logs/wsms/sync/nas-errors.log 2>/dev/null || echo "No errors logged"'

# ============================================
# CYBERSECURITY (ClamAV)
# ============================================
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'
alias clamav-quarantine='sudo ls -la /var/quarantine/'
alias clamav-clean-quarantine='sudo rm -rf /var/quarantine/* && echo "✅ Quarantine cleaned"'

# ============================================
# LOG VIEWING SHORTCUTS
# ============================================
alias logs-backup='tail -f $HOME/logs/wsms/backups/lite.log'
alias logs-update='tail -f $HOME/logs/wsms/maintenance/updates.log'
alias logs-sync='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias logs-scan='tail -f $HOME/logs/wsms/security/clamav-scan.log'
alias logs-all='ls -la $HOME/logs/wsms/*/'

# ============================================
# FUNCTIONS
# ============================================
wp-status() {
    echo "🌐 WSMS PRO v4.2 - Quick Status:"
    echo "=========================================================="
    wp-list
    echo ""
    backup-size
    echo ""
    echo "📸 Rollback Snapshots:"
    wp-snapshots
}

wp-update-safe() {
    echo "📦 Creating backup first..."
    if wp-backup-lite; then
        echo "⏳ Waiting 10 seconds..."
        sleep 10
        echo "📸 Creating rollback snapshot..."
        wp-snapshot all
        echo "🔄 Running updates..."
        wp-update-all
        echo "✅ Update completed successfully!"
    else
        echo "❌ Backup failed - aborting update!"
        return 1
    fi
}

wp-health() {
    echo "🏥 WSMS Health Check..."
    echo "=========================================================="
    
    # Check disk space
    disk_usage=$(df $HOME | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        echo -e "   \033[0;31m⚠️ Disk usage: $disk_usage% (CRITICAL)\033[0m"
    elif [ "$disk_usage" -gt 60 ]; then
        echo -e "   \033[1;33m⚠️ Disk usage: $disk_usage% (WARNING)\033[0m"
    else
        echo -e "   \033[0;32m✅ Disk usage: $disk_usage%\033[0m"
    fi
    
    # Check services
    if systemctl is-active --quiet nginx || systemctl is-active --quiet apache2; then
        echo -e "   \033[0;32m✅ Web server: Running\033[0m"
    else
        echo -e "   \033[0;31m❌ Web server: Stopped\033[0m"
    fi
    
    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        echo -e "   \033[0;32m✅ Database: Running\033[0m"
    else
        echo -e "   \033[0;31m❌ Database: Stopped\033[0m"
    fi
    
    # Check WP-CLI
    if command -v wp >/dev/null; then
        echo -e "   \033[0;32m✅ WP-CLI: Installed\033[0m"
    else
        echo -e "   \033[0;31m❌ WP-CLI: Missing\033[0m"
    fi
}

echo "✅ WSMS PRO v4.2 - Bash aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"